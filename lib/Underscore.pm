package Underscore;

use strict;
use warnings;

our $VERSION = '0.03';

use B               ();
use List::MoreUtils ();
use List::Util      ();
use Scalar::Util    ();

our $UNIQUE_ID = 0;

sub import {
    my $class = shift;
    my (%options) = @_;

    my $name = $options{-as} || '_';

    my $package = caller;
    no strict;
    *{"$package\::$name"} = \&_;
}

sub _ {
    return new(__PACKAGE__, args => [@_]);
}

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    $self->{template_settings} = {
        evaluate    => qr/<\%([\s\S]+?)\%>/,
        interpolate => qr/<\%=([\s\S]+?)\%>/
    };

    return $self;
}

sub true  { Underscore::_True->new }
sub false { Underscore::_False->new }

sub forEach {&each}

sub each {
    my $self = shift;
    my ($array, $cb, $context) = $self->_prepare(@_);

    return unless defined $array;

    $context = $array unless defined $context;

    my $i = 0;
    foreach (@$array) {
        $cb->($_, $i, $context);
        $i++;
    }
}

sub collect {&map}

sub map {
    my $self = shift;
    my ($array, $cb, $context) = $self->_prepare(@_);

    $context = $array unless defined $context;

    my $index = 0;
    my $result = [map { $cb->($_, ++$index, $context) } @$array];

    return $self->_finalize($result);
}

sub contains {&include}

sub include {
    my $self = shift;
    my ($list, $value) = $self->_prepare(@_);

    if (ref $list eq 'ARRAY') {
        return (List::Util::first { $_ eq $value } @$list) ? 1 : 0;
    }
    elsif (ref $list eq 'HASH') {
        return (List::Util::first { $_ eq $value } values %$list) ? 1 : 0;
    }

    die 'include only supports arrays and hashes';
}

sub inject {&reduce}
sub foldl  {&reduce}

sub reduce {
    my $self = shift;
    my ($array, $iterator, $memo, $context) = $self->_prepare(@_);

    die 'No list or memo' if !defined $array && !defined $memo;

    return $memo unless defined $array;

    my $initial = defined $memo;

    foreach (@$array) {
        if (!$initial && defined $_) {
            $memo = $_;
            $initial = 1;
        } else {
            $memo = $iterator->($memo, $_, $context) if defined $_;
        }
    }
    die 'No memo' if !$initial;
    return $self->_finalize($memo);
}

sub foldr       {&reduce_right}
sub reduceRight {&reduce_right}

sub reduce_right {
    my $self = shift;
    my ($array, $iterator, $memo, $context) = $self->_prepare(@_);

    die 'No list or memo' if !defined $array && !defined $memo;

    return $memo unless defined $array;

    return _->reduce([reverse @$array], $iterator, $memo, $context);
}

sub find {&detect}

sub detect {
    my $self = shift;
    my ($list, $iterator, $context) = $self->_prepare(@_);

    return List::Util::first { $iterator->($_) } @$list;
}

sub filter {&select}

sub select {
    my $self = shift;
    my ($list, $iterator, $context) = $self->_prepare(@_);

    my $result = [grep { $iterator->($_) } @$list];

    $self->_finalize($result);
}

sub reject {
    my $self = shift;
    my ($list, $iterator, $context) = $self->_prepare(@_);

    my $result = [grep { !$iterator->($_) } @$list];

    $self->_finalize($result);
}

sub every {&all}

sub all {
    my $self = shift;
    my ($list, $iterator, $context) = $self->_prepare(@_);

    foreach (@$list) {
        return 0 unless $iterator->($_);
    }

    return 1;
}

sub some {&any}

sub any {
    my $self = shift;
    my ($list, $iterator, $context) = $self->_prepare(@_);

    return 0 unless @$list;

    foreach (@$list) {
        return 1 if $iterator ? $iterator->($_) : $_;
    }

    return 0;
}

sub invoke {
    my $self = shift;
    my ($list, $method, @args) = $self->_prepare(@_);

    my $result = [];

    foreach (@$list) {
        push @$result,
          [ref $method eq 'CODE' ? $method->(@$_) : $self->$method(@$_)];
    }

    return $result;
}

sub pluck {
    my $self = shift;
    my ($list, $key) = $self->_prepare(@_);

    my $result = [];

    foreach (@$list) {
        push @$result, $_->{$key};
    }

    return $self->_finalize($result);
}

sub _minmax {
    my $self = shift;
    my ($list, $iterator, $context, $behaviour) = $self->_prepare(@_);

    my $computed_list = [map {
        { original => $_, computed => $iterator->($_, $context) }
    } @$list];

    return _->reduce(
        $computed_list
        , sub {
            my ($memo, $e) = @_;
            return $behaviour->($memo, $e);
        }
        , $computed_list->[0]
    )->{original};
}

sub max {
    my $self = shift;
    my ($list, $iterator, $context) = $self->_prepare(@_);

    return List::Util::max(@$list) unless defined $iterator;

    return _->_minmax($list, $iterator, $context, sub {
        my ($max, $e) = @_;
        return ($e->{computed} > $max->{computed}) ? $e: $max;
    });
}

sub min {
    my $self = shift;
    my ($list, $iterator, $context) = $self->_prepare(@_);

    return List::Util::min(@$list) unless defined $iterator;

    return _->_minmax($list, $iterator, $context, sub {
        my ($min, $e) = @_;
        return ($e->{computed} < $min->{computed}) ? $e: $min;
    });
}

sub sort : method {
    my $self = shift;
    my ($list) = $self->_prepare(@_);

    return $self->_finalize([sort @$list]);
}

sub sortBy {&sort_by}

sub sort_by {
    my $self = shift;
    my ($list, $iterator, $context, $comparator) = $self->_prepare(@_);

    my $cmp = defined $comparator ? $comparator : sub { my ($x, $y) = @_; $x <=> $y } ;

    my $result = [sort { $cmp->($iterator->($a, $context), $iterator->($b, $context)) } @$list];

    return $self->_finalize($result);
}

sub reverse : method {
    my $self = shift;
    my ($list) = $self->_prepare(@_);

    my $result = [reverse @$list];

    return $self->_finalize($result);
}

sub concat {
    my $self = shift;
    my ($list, $other) = $self->_prepare(@_);

    my $result = [@$list, @$other];

    return $self->_finalize($result);
}

sub unshift : method {
    my $self = shift;
    my ($list, @elements) = $self->_prepare(@_);

    unshift @$list, @elements;
    my $result = $list;

    return $self->_finalize($result);
}

sub pop : method {
    my $self = shift;
    my ($list) = $self->_prepare(@_);

    pop @$list;
    my $result = $list;

    return $self->_finalize($result);
}

sub _partition {
    my $self = shift;
    my ($list, $iterator, $behaviour) = $self->_prepare(@_);

    my $result = {};
    foreach (@{$list}) {
        my $group = $iterator->($_);
        $behaviour->($result, $group, $_);
    }
    return $self->_finalize($result);
}

sub groupBy {&group_by}

sub group_by {
    my $self = shift;
    return $self->_partition(@_, sub {
        my ($result, $group, $o) = @_;
        if (exists $result->{$group}) {
            push @{$result->{$group}}, $o;
        }
        else {
            $result->{$group} = [$o];
        }
    });
}

sub countBy {&count_by}

sub count_by {
    my $self = shift;
    return $self->_partition(@_, sub {
        my ($result, $group, $o) = @_;
        if (exists $result->{$group}) {
            $result->{$group} = $result->{$group} + 1;
        }
        else {
            $result->{$group} = 1;
        }
    });
}

sub sortedIndex {&sorted_index}

sub sorted_index {
    my $self = shift;
    my ($list, $value, $iterator) = $self->_prepare(@_);

    # TODO $iterator

    my $min = 0;
    my $max = @$list;
    my $mid;

    do {
        $mid = int(($min + $max) / 2);
        if ($value > $list->[$mid]) {
            $min = $mid + 1;
        }
        else {
            $max = $mid - 1;
        }
    } while ($list->[$mid] == $value || $min > $max);

    if ($list->[$mid] == $value) {
        return $mid;
    }

    return $mid + 1;
}

sub toArray {&to_array}

sub to_array {
    my $self = shift;
    my ($list) = $self->_prepare(@_);

    return [values %$list] if ref $list eq 'HASH';

    return [$list] unless ref $list eq 'ARRAY';

    return [@$list];
}

sub size {
    my $self = shift;
    my ($list) = $self->_prepare(@_);

    return scalar @$list if ref $list eq 'ARRAY';

    return scalar keys %$list if ref $list eq 'HASH';

    return 1;
}

sub head {&first}
sub take {&first}

sub first {
    my $self = shift;
    my ($array, $n) = $self->_prepare(@_);

    return $array->[0] unless defined $n;

    return [@{$array}[0 .. $n - 1]];
}

sub initial {
    my $self = shift;
    my ($array, $n) = $self->_prepare(@_);

    $n = scalar @$array - 1 unless defined $n;
    
    return $self->take($array, $n);
}

sub tail {&rest}

sub rest {
    my $self = shift;
    my ($array, $index) = $self->_prepare(@_);

    $index = 1 unless defined $index;

    return [@{$array}[$index .. $#$array]];
}

sub last {
    my $self = shift;
    my ($array) = $self->_prepare(@_);

    return $array->[-1];
}

sub shuffle {
    my $self = shift;
    my ($array) = $self->_prepare(@_);

    return [List::Util::shuffle @$array];
}

sub compact {
    my $self = shift;
    my ($array) = $self->_prepare(@_);

    my $new_array = [];
    foreach (@$array) {
        push @$new_array, $_ if $_;
    }

    return $new_array;
}

sub flatten {
    my $self = shift;
    my ($array) = $self->_prepare(@_);

    my $cb;
    $cb = sub {
        my $result = [];
        foreach (@{$_[0]}) {
            if (ref $_ eq 'ARRAY') {
                push @$result, @{$cb->($_)};
            }
            else {
                push @$result, $_;
            }
        }
        return $result;
    };

    my $result = $cb->($array);

    return $self->_finalize($result);
}

sub without {
    my $self = shift;
    my ($array, @values) = $self->_prepare(@_);

    # Nice hack comparing hashes

    my $new_array = [];
    foreach my $el (@$array) {
        push @$new_array, $el
          unless defined List::Util::first { $el eq $_ } @values;
    }

    return $new_array;
}

sub unique {&uniq}

sub uniq {
    my $self = shift;
    my ($array, $is_sorted) = $self->_prepare(@_);

    return [List::MoreUtils::uniq(@$array)] unless $is_sorted;

    # We can push first value to prevent unneeded -1 check
    my $new_array = [shift @$array];
    foreach (@$array) {
        push @$new_array, $_ unless $_ eq $new_array->[-1];
    }

    return $new_array;
}

sub intersection {
    my $self = shift;
    my (@arrays) = $self->_prepare(@_);

    my $seen = {};
    foreach my $array (@arrays) {
        $seen->{$_}++ for @$array;
    }

    my $intersection = [];
    foreach (keys %$seen) {
        push @$intersection, $_ if $seen->{$_} == @arrays;
    }
    return $intersection;
}

sub union {
    my $self = shift;
    my (@arrays) = $self->_prepare(@_);

    my $seen = {};
    foreach my $array (@arrays) {
        $seen->{$_}++ for @$array;
    }

    return [keys %$seen];
}

sub difference {
    my $self = shift;
    my ($array, $other) = $self->_prepare(@_);

    my $new_array = [];
    foreach my $el (@$array) {
        push @$new_array, $el unless List::Util::first { $el eq $_ } @$other;
    }

    return $new_array;
}

sub object {
    my $self = shift;
    my (@arrays) = $self->_prepare(@_);

    my $object = {};
    my $arrays_length = scalar @arrays;
    if ($arrays_length == 2) {
        my ($keys, $values) = @arrays;
        foreach my $i (0..scalar @$keys - 1) {
            my $key   = $keys->[$i];
            my $value = $values->[$i];
            $object->{$key} = $value;
        }
    } elsif ($arrays_length == 1) {
        _->reduce($arrays[0]
                , sub {
                    my ($o, $pair) = @_;
                    $o->{$pair->[0]} = $pair->[1];
                    return $o;
                }
                , $object
        );
    }
    return $object;
}

sub pairs {
    my $self = shift;
    my ($hash) = $self->_prepare(@_);

    return [map { [ $_ => $hash->{$_} ] } keys %$hash ];
}

sub pick {
    my $self = shift;
    my ($hash, @picks) = $self->_prepare(@_);

    return _->reduce(
        _->flatten(\@picks)
        , sub {
            my ($o, $pick) = @_;
            $o->{$pick} = $hash->{$pick};
            return $o;
        }
        , {}
    );
}

sub omit {
    my $self = shift;
    my ($hash, @omits) = $self->_prepare(@_);

    my %omit_these = map { $_ => $_ } @{_->flatten(\@omits)};
    return _->reduce(
        [keys %$hash]
        , sub {
            my ($o, $key) = @_;
            $o->{$key} = $hash->{$key} unless exists $omit_these{$key};
            return $o;
        }
        , {}
    );
}

sub zip {
    my $self = shift;
    my (@arrays) = $self->_prepare(@_);

    # This code is from List::MoreUtils
    # (can't use it here directly because of the prototype!)
    my $max = -1;
    $max < $#$_ && ($max = $#$_) foreach @arrays;
    return [
        map {
            my $ix = $_;
            map $_->[$ix], @_;
          } 0 .. $max
    ];
}

sub indexOf {&index_of}

sub index_of {
    my $self = shift;
    my ($array, $value, $is_sorted) = $self->_prepare(@_);

    return -1 unless defined $array;

    return List::MoreUtils::first_index { $_ eq $value } @$array;
}

sub lastIndexOf {&last_index_of}

sub last_index_of {
    my $self = shift;
    my ($array, $value, $is_sorted) = $self->_prepare(@_);

    return -1 unless defined $array;

    return List::MoreUtils::last_index { $_ eq $value } @$array;
}

sub range {
    my $self = shift;
    my ($start, $stop, $step) =
      @_ == 3 ? @_ : @_ == 2 ? @_ : (undef, @_, undef);

    return [] unless $stop;

    $start = 0 unless defined $start;

    return [$start .. $stop - 1] unless defined $step;

    my $test = ($start < $stop)
        ? sub { $start < $stop }
        : sub { $start > $stop };

    my $new_array = [];
    while ($test->()) {
        push @$new_array, $start;
        $start += $step;
    }
    return $new_array;
}

sub mixin {
    my $self = shift;
    my (%functions) = $self->_prepare(@_);

    no strict 'refs';
    no warnings 'redefine';
    foreach my $name (keys %functions) {
        *{__PACKAGE__ . '::' . $name} = sub {
            my $self = shift;

            unshift @_, @{$self->{args}}
              if defined $self->{args} && @{$self->{args}};
            $functions{$name}->(@_);
        };
    }
}

sub uniqueId {&unique_id}

sub unique_id {
    my $self = shift;
    my ($prefix) = $self->_prepare(@_);

    $prefix = '' unless defined $prefix;

    return $prefix . ($UNIQUE_ID++);
}

sub result {
    my $self = shift;
    my ($hash, $key, @args) = $self->_prepare(@_);

    my $value = $hash->{$key};
    return ref $value eq 'CODE' ? $value->(@args) : $value;
}

sub times {
    my $self = shift;
    my ($n, $iterator) = $self->_prepare(@_);

    for (0 .. $n - 1) {
        $iterator->($_);
    }
}

sub after {
    my $self = shift;
    my ($n, $func, @args) = $self->_prepare(@_);

    my $invocation_count = 0;
    return sub {
        return ++$invocation_count >= $n ? $func->(@args) : undef;
    };
}

sub template_settings {
    my $self = shift;
    my (%args) = @_;

    for (qw/interpolate evaluate/) {
        if (my $value = $args{$_}) {
            $self->{template_settings}->{$_} = $value;
        }
    }
}

sub template {
    my $self = shift;
    my ($template) = $self->_prepare(@_);

    my $evaluate    = $self->{template_settings}->{evaluate};
    my $interpolate = $self->{template_settings}->{interpolate};

    return sub {
        my ($args) = @_;

        my $code = q!sub {my ($args) = @_; my $_t = '';!;
        foreach my $arg (keys %$args) {
            $code .= "my \$$arg = \$args->{$arg};";
        }

        $template =~ s{$interpolate}{\}; \$_t .= $1; \$_t .= q\{}g;
        $template =~ s{$evaluate}{\}; $1; \$_t .= q\{}g;

        $code .= '$_t .= q{';
        $code .= $template;
        $code .= '};';
        $code .= 'return $_t};';

        my $sub = eval $code;

        return $sub->($args);
    };
}

our $ONCE;

sub once {
    my $self = shift;
    my ($func) = @_;

    return sub {
        return if $ONCE;

        $ONCE++;
        $func->(@_);
    };
}

sub wrap {
    my $self = shift;
    my ($function, $wrapper) = $self->_prepare(@_);

    return sub {
        $wrapper->($function, @_);
    };
}

sub compose {
    my $self = shift;
    my (@functions) = @_;

    return sub {
        my @args = @_;
        foreach (reverse @functions) {
            @args = $_->(@args);
        }

        return wantarray ? @args : $args[0];
    };
}

sub bind {
    my $self = shift;
    my ($function, $object, @args) = $self->_prepare(@_);

    return sub {
        $function->($object, @args, @_);
    };
}

sub keys : method {
    my $self = shift;
    my ($object) = $self->_prepare(@_);

    die 'Not a hash reference' unless ref $object && ref $object eq 'HASH';

    return [keys %$object];
}

sub values {
    my $self = shift;
    my ($object) = $self->_prepare(@_);

    die 'Not a hash reference' unless ref $object && ref $object eq 'HASH';

    return [values %$object];
}

sub functions {
    my $self = shift;
    my ($object) = $self->_prepare(@_);

    die 'Not a hash reference' unless ref $object && ref $object eq 'HASH';

    my $functions = [];
    foreach (keys %$object) {
        push @$functions, $_
          if ref $object->{$_} && ref $object->{$_} eq 'CODE';
    }
    return $functions;
}

sub extend {
    my $self = shift;
    my ($destination, @sources) = $self->_prepare(@_);

    foreach my $source (@sources) {
        foreach my $key (keys %$source) {
            next unless defined $source->{$key};
            $destination->{$key} = $source->{$key};
        }
    }

    return $destination;
}

sub defaults {
    my $self = shift;
    my ($object, @defaults) = $self->_prepare(@_);

    foreach my $default (@defaults) {
        foreach my $key (keys %$default) {
            next if exists $object->{$key};
            $object->{$key} = $default->{$key};
        }
    }

    return $object;
}

sub clone {
    my $self = shift;
    my ($object) = $self->_prepare(@_);

    # Scalars will be copied, everything deeper not
    my $cloned = {};
    foreach my $key (keys %$object) {
        $cloned->{$key} = $object->{$key};
    }

    return $cloned;
}

sub isEqual {&is_equal}

sub is_equal {
    my $self = shift;
    my ($object, $other) = $self->_prepare(@_);
}

sub isEmpty {&is_empty}

sub is_empty {
    my $self = shift;
    my ($object) = $self->_prepare(@_);

    return 1 unless defined $object;

    if (!ref $object) {
        return 1 if $object eq '';
    }
    elsif (ref $object eq 'HASH') {
        return 1 if !(keys %$object);
    }
    elsif (ref $object eq 'ARRAY') {
        return 1 if @$object == 0;
    }
    elsif (ref $object eq 'Regexp') {
        return 1 if $object eq qr//;
    }

    return 0;
}

sub isArray {&is_array}

sub is_array {
    my $self = shift;
    my ($object) = $self->_prepare(@_);

    return 1 if defined $object && ref $object && ref $object eq 'ARRAY';

    return 0;
}

sub isString {&is_string}

sub is_string {
    my $self = shift;
    my ($object) = $self->_prepare(@_);

    return 0 unless defined $object && !ref $object;

    return 0 if $self->is_number($object);

    return 1;
}

sub isNumber {&is_number}

sub is_number {
    my $self = shift;
    my ($object) = $self->_prepare(@_);

    return 0 unless defined $object && !ref $object;

    # From JSON::PP
    my $flags = B::svref_2object(\$object)->FLAGS;
    my $is_number = $flags & (B::SVp_IOK | B::SVp_NOK)
      and !($flags & B::SVp_POK) ? 1 : 0;

    return 1 if $is_number;

    return 0;
}

sub isFunction {&is_function}

sub is_function {
    my $self = shift;
    my ($object) = $self->_prepare(@_);

    return 1 if defined $object && ref $object && ref $object eq 'CODE';

    return 0;
}

sub isRegExp {&is_regexp}

sub is_regexp {
    my $self = shift;
    my ($object) = $self->_prepare(@_);

    return 1 if defined $object && ref $object && ref $object eq 'Regexp';

    return 0;
}

sub isUndefined {&is_undefined}

sub is_undefined {
    my $self = shift;
    my ($object) = $self->_prepare(@_);

    return 1 unless defined $object;

    return 0;
}

sub isBoolean {&is_boolean}

sub is_boolean {
    my $self = shift;
    my ($object) = @_;

    return 1
      if Scalar::Util::blessed($object)
          && (   $object->isa('Underscore::_True')
              || $object->isa('Underscore::_False'));

    return 0;
}

sub chain {
    my $self = shift;

    $self->{chain} = 1;

    return $self;
}

sub value {
    my $self = shift;

    return wantarray ? @{$self->{args}} : $self->{args}->[0];
}

sub _prepare {
    my $self = shift;
    unshift @_, @{$self->{args}} if defined $self->{args} && @{$self->{args}};
    return @_;
}

sub _finalize {
    my $self = shift;

    return
        $self->{chain} ? do { $self->{args} = [@_]; $self }
      : wantarray      ? @_
      :                  $_[0];
}

package Underscore::_True;

use overload '""'   => sub {'true'}, fallback => 1;
use overload 'bool' => sub {1},      fallback => 1;
use overload 'eq' => sub { $_[1] eq 'true' ? 1 : 0; }, fallback => 1;
use overload '==' => sub { $_[1] == 1 ? 1 : 0; }, fallback => 1;

sub new { bless {}, $_[0] }

package Underscore::_False;

use overload '""'   => sub {'false'}, fallback => 1;
use overload 'bool' => sub {0},       fallback => 1;
use overload 'eq' => sub { $_[1] eq 'false' ? 1 : 0; }, fallback => 1;
use overload '==' => sub { $_[1] == 0 ? 1 : 0; }, fallback => 1;

sub new { bless {}, $_[0] }

1;
__END__

=head1 NAME

Underscore - Perl port of Underscore.js

=head1 SYNOPSIS

    use Underscore;

    _([3, 2, 1])->sort;

=head1 DESCRIPTION

L<Underscore> Perl is a clone of a popular JavaScript library
L<http://github.com/documentcloud/underscore|Underscore.js>. Why? Because Perl
is awesome. And because we can!

This document describes the differences. For the full introduction see original
page of L<http://documentcloud.github.com/underscore/|Underscore.js>.

The test suite is compatible with the original one, except for those functions
that were not ported.

=head2 The main differences

All the methods have CamelCase aliases. Use whatever you like. I
personally prefer underscores.

Objects are simply hashes, not Perl objects. Maybe objects will be added
later.

Of course not everything was ported. Some things don't make any sense
for Perl, other are impossible to implement without depending on event
loops and async programming.

=head2 Implementation details

Most of the functions are just wrappers around built-in functions. Others use
L<List::Util> and L<List::MoreUtils> modules.

Numeric/String detection is done the same way L<JSON::PP> does it: by using
L<B> hacks.

Boolean values are implemented as overloaded methods, that return numbers or
strings depending on the context.

    _->true;
    _->false;

=head2 Object-Oriented and Functional Styles

You can use Perl version in either an object-oriented or a functional style,
depending on your preference. The following two lines of code are identical
ways to double a list of numbers.

    _->map([1, 2, 3], sub { my ($n) = @_; $n * 2; });
    _([1, 2, 3])->map(sub { my ($n) = @_; $n * 2; });

See the L<http://documentcloud.github.com/underscore/#styles|original documentation>
 for an explanation of why the object-oriented style can be better.

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/vti/underscore-perl

=head1 CREDITS

Undescore.js authors and contributors

=head1 AUTHORS

Viacheslav Tykhanovskyi, C<vti@cpan.org>
Rich Douglas Evans, C<rich.douglas.evans@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2012, Viacheslav Tykhanovskyi
Copyright (C) 2013 Rich Douglas Evans

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
