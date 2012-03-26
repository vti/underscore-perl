package Underscore;

use strict;
use warnings;
use v5.10.1 ;

our $VERSION = '0.02';

use B               ();
use List::MoreUtils ();
use List::Util      ();
use Scalar::Util    ();

#use Smart::Comments ;

our $UNIQUE_ID = 0;

sub import {
    my $class = shift;
    my (%options) = @_;

    my $name = $options{-as} || '_';

    my $package = caller;
    no strict;
    *{"$package\::$name"} = \&_;
}

sub _ { new(__PACKAGE__, args => [@_]) ; }

sub new {
  my $class = shift;
  my $self = {@_};
  bless $self, $class;
  
  $self->{template_settings} = { evaluate    => qr/<\%([\s\S]+?)\%>/,
				 interpolate => qr/<\%=([\s\S]+?)\%>/
			       } ;  
  return $self;
}

sub _call {
  my ($self, $method, @args) = @_ ;
  $self->_finalize( $self->$method( $self->_prepare(@args) ) ) ;
}

sub true  { Underscore::_True->new }
sub false { Underscore::_False->new }

eval "sub $_ : method { shift->_call( __$_ => \@_ ) ; }" 
  for qw(
	  all
	  any
	  bind
	  clone
	  compact
	  compose
	  concat
	  defaults
	  detect
	  difference
	  each
	  extend
	  first
	  flatten
	  functions
	  group_by
	  has
	  identity
	  include
	  index_of
	  intersection
	  invoke
	  is_array
	  is_boolean
	  is_empty
	  is_equal
	  is_function
	  is_number
	  is_regexp
	  is_string
	  is_undefined
	  keys
	  last 
	  last_index_of
	  min
	  map
	  max
	  mixin
	  once
	  pluck
	  pop
	  range
	  reduce
	  reduce_right
	  reject
	  rest
	  reverse
	  select
	  shuffle
	  size
	  sort
	  sort_by
	  sorted_index
	  template
	  times
	  to_array
	  union
	  uniq
	  unique_id
	  unshift
	  values
	  without
	  wrap
	  zip
       ) ;

eval qq{sub $_->[0] {\&$_->[1]}}
  for ( ['forEach', 'each'],
	['contains', 'include'],
	['inject', 'reduce'],
	['foldl', 'reduce'],
	['foldr', 'reduce_right'],
	['reduceRight', 'reduce_right'],
	['find', 'detect'],
	['filter', 'select'],
	['every', 'all'],
	['some', 'any'],
	['sortBy', 'sort_by'],
	['groupBy', 'group_by'],
	['sortedIndex', 'sorted_index'],
	['toArray', 'to_array'],
	['tail', 'rest'],
	['indexOf', 'index_of'],
	['lastIndexOf', 'last_index_of'],
	['uniqueId', 'unique_id'],
	['isEqual', 'is_equal'],
	['isEmpty', 'is_empty'],
	['isArray', 'is_array'],
	['isString', 'is_string'],
	['isNumber', 'is_number'],
	['isFunction', 'is_function'],
	['isRegExp', 'is_regexp'],
	['isUndefined', 'is_undefined'],
	['isBoolean', 'is_boolean'],
      ) ;

sub __each {
  my ($self, $array, $cb, $context) = @_ ;
  return unless defined $array;
  
  $context //= $array ;  
  my $i = 0;
  foreach (@$array) {
    $cb->($_, $i, $context);
    $i++;
  }
}

sub __map {
  my ($self, $array, $cb, $context) = @_ ;
  [map { $cb->($_, undef, $context) } @$array];
}

sub __include {
  my ($self, $list, $value) = @_ ; 
 ( ref $list eq 'ARRAY' ? 
   (( List::Util::first { $_ eq $value } @$list) ? 1 : 0 ) :
   ref $list eq 'HASH' ? 
   ((List::Util::first { $_ eq $value } values %$list) ? 1 : 0 ) :
   die 'WTF?' ) ;
}

sub __reduce {
  my ($self, $array, $iterator, $memo, $context) = @_ ;
  die 'TypeError' if !defined $array && !defined $memo;
  
  # TODO
  $memo //= 0 ;
  return $memo unless defined $array;
  
  foreach (@$array) {
    $memo = $iterator->($memo, $_, $context) if defined $_;
  }
  return $memo ;
}

sub __reduce_right {
  my ($self, $array, $iterator, $memo, $context) = @_ ;

  die 'TypeError' if !defined $array && !defined $memo;

  # TODO
  $memo //= '' ;
  return $memo unless defined $array;

  foreach (reverse @$array) {
    $memo = $iterator->($memo, $_, $context) if defined $_;
  }

  return $memo;
}

sub __detect {
  my ($self, $list, $iterator, $context) = @_ ;
  List::Util::first { $iterator->($_) } @$list;
}

sub __select {
  my ($self, $list, $iterator, $context) = @_ ;
  [grep { $iterator->($_) } @$list];
}

sub __reject {
  my ($self, $list, $iterator, $context) = @_ ;
  [grep { !$iterator->($_) } @$list];
}

sub __all {
  my ($self, $list, $iterator, $context) = @_ ;
  foreach (@$list) {
    return 0 unless $iterator->($_);
  }  
  return 1;
}

sub __any {
  my ($self, $list, $iterator, $context) = @_ ;  
  return 0 unless defined @$list;
  foreach (@$list) {
    return 1 if $iterator ? $iterator->($_) : $_;
  }  
  return 0;
}

sub __invoke {
  my ($self, $list, $method, @args) = @_ ;
 [ map { ref $method eq 'CODE' ? $method->($_, @args) : $self->$method($_, @args) }
   @$list ] ;
}

sub __pluck {
  my ($self, $list, $key) = @_ ;  
  [ map { $_->{$key} } @$list ] ;
}

sub ___compared {
  my ($self, $comparator, $list, $iterator, $context) = @_ ;
  ( defined $iterator ?
    ( List::Util::reduce {
      return +{ value => $b, key => $iterator->($b) } unless defined $a ;
      my $key = $iterator->($b) ;
      if ($comparator->($key, $a->{key}) == $key) {
	$a->{key} = $key ;
	$a->{value} = $b ;
      }
      return $a ;
    } undef, @$list )->{value} :
    $comparator->(@$list) ) ;
}

sub __min {
  my ($self, $list, $iterator, $context) = @_ ;
  $self->___compared(\&List::Util::min, $list, $iterator, $context ) ;
}

sub __max {
  my ($self, $list, $iterator, $context) = @_ ;
  $self->___compared(\&List::Util::max, $list, $iterator, $context ) ;
}

sub __sort : method {
  my ($self, $list) = @_ ;
  [sort @$list];
}

sub __sort_by {
  my ($self, $list, $iterator, $context) = @_ ;
  [sort { $a cmp $iterator->($b) } @$list];
}

sub __reverse : method {
  my ($seflf, $list) = @_ ;
  [reverse @$list];
}

sub __concat {
  my ($self, $list, $other) = @_ ;
  [@$list, @$other];
}

sub __unshift : method {
  my ($self, $list, @elements) = @_ ;
  unshift @$list, @elements;
  $list;
}

sub __pop : method {
  my ($self, $list) = @_ ;
  pop @$list;
  $list;
}

sub __group_by {
  my ($self, $list, $iterator) =  @_ ;  
  my %result ;
  foreach (@{$list}) {
    my $group = $iterator->($_);
    if (exists $result{$group}) {
      push @{$result{$group}}, $_;
    }
    else {
      $result{$group} = [$_];
    }
  }
  \%result ;
}

sub __shuffle {
  my ( $self, $list ) = @_ ;  
  my @shuffled ;
  my $rand ;
  my $index = 0 ;
  for my $value (@$list) {
    if ($index == 0) {
      $shuffled[0] = $value;
    }
    else {
      $rand = int(rand() * ($index + 1)) ;
      $shuffled[$index] = $shuffled[$rand] ;
      $shuffled[$rand] = $value;
    }
    $index++ ;
  } 
  \@shuffled ;
}

sub __sorted_index {
  my ($self, $list, $value, $iterator) = @_ ;
  
  # TODO $iterator
  my $min = 0;
  my $max = @$list;
  my $mid ;
  
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

sub __to_array {
    my ($self, $list) = @_ ;
    return [values %$list] if ref $list eq 'HASH';
    return [$list] unless ref $list eq 'ARRAY';
    return [@$list];
}

sub __size {
  my ($self, $list) =  @_ ;
  ( ref $list eq 'ARRAY' ?
    scalar @$list :
    ref $list eq 'HASH' ?
    scalar keys %$list :
    1 ) ;
}

sub __first {
  my ($self, $array, $n) = @_ ;
  return defined $n ? [@{$array}[0 .. $n - 1]] : $array->[0] ;
}

sub __rest {
  my ($self, $array, $index) = @_ ;
  $index //= 1 ;
  return [@{$array}[$index .. $#$array]];
}

sub __last {
  my ($self, $array, $count) = @_ ;
  $count //= 1 ;
  return $count == 1 ? $array->[-1] : [ @$array[ -$count .. -1 ] ] ;
}

sub __compact {
  my ($self, $array) = @_ ;
  [ grep { $_ } @$array ] ;
}

sub __flatten {
  my ($self, $array) = @_ ;
  
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
  $cb->($array) ;  
}

sub __without {
  my ($self, $array, @values) = @_ ;
  
  my $new_array = [];
  foreach my $el (@$array) {
    push @$new_array, $el
      unless 0 <= List::MoreUtils::first_index { $el eq $_ } @values;
  }
  $new_array;
}

sub __uniq {
  my ($self, $array, $is_sorted) = @_ ;
  return [List::MoreUtils::uniq(@$array)] unless $is_sorted;
  
  List::Util::reduce {
    @$a && $a->[$#$a] eq $b ? $a : [ @$a, $b ] ;
  } [], @$array ;
}

sub __intersection {
  my ($self, @arrays) = @_ ;
  my $seen = {};
  foreach my $array (@arrays) {
    $seen->{$_}++ for @$array;
  }
  [ grep { $seen->{$_} == @arrays } keys %$seen ] ;
}

sub __union {
  my ($self, @arrays) = @_ ;  
  my %seen ;
  foreach my $array (@arrays) {
    $seen{$_}++ for @$array;
  }
  [keys %seen];
}

sub __difference {
  my ($self, $array, @other) = @_ ;
  my %seen ;
  foreach my $array (@other) {
    $seen{$_ // ''}++ for @$array;
  }
  [grep { not $seen{$_ // ''} } @$array];
}

sub __zip {
  my ($self, @arrays) = @_ ;  
  my $max = List::Util::reduce { $#$b > $a ? $#$b : $a} -1, @arrays ;
  [ map {
    my $ix = $_;
    [map $_->[$ix], @arrays];
  } 0 .. $max
  ] ;
}

sub __index_of {
  my ($self, $array, $value, $is_sorted) = @_ ;
  
  return -1 unless defined $array;
  return List::MoreUtils::first_index { $_ eq $value } @$array;
}

sub __last_index_of {
  my ($self, $array, $value, $is_sorted) = @_ ;
  
  return -1 unless defined $array;  
  return List::MoreUtils::last_index { $_ eq $value } @$array;
}

sub __range {
  my ($self, $start, $stop, $step) =
    @_ == 4 ? @_ : @_ == 3 ? @_ : (shift, undef, @_, undef);
  
  return [] unless $stop;  
  $start //= 0 ;
  
  return [$start .. $stop-1] unless defined $step;
  
  my $new_array = [];
  while ($start < $stop) {
    push @$new_array, $start;
    $start += $step;
  }
  $new_array;
}

sub __mixin {
  my ($self, %functions) = @_ ;
  
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

sub __unique_id {
  my ($self, $prefix) = @_ ;
  $prefix //= '' ;
  $prefix . ($UNIQUE_ID++);
}

sub __identity {
  my ($self, $value) = @_ ;    
  sub { return $_[0] ; } ;
}

sub __times {
  my ($self, $n, $iterator) = @_ ;
  $iterator->($_) for 0 .. $n - 1 ;
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

sub __template {
  my ($self, $template) = @_ ;
 
  my $evaluate    = $self->{template_settings}->{evaluate};
  my $interpolate = $self->{template_settings}->{interpolate};
  
  sub {
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
  } ;
}

our %ONCE ;

sub __once {
  my ($self, $func) = @_;
  return sub {
    return if $ONCE{"$func"};
    
    $ONCE{"$func"}++;
    $func->(@_);
  };
}

sub __wrap {
  my ($self, $function, $wrapper) = @_ ;
  sub { $wrapper->($function, @_) ; };
}

sub __compose {
  my ($self, @functions) = @_;
  
  return sub {
    my @args = @_;
    foreach (reverse @functions) {
      @args = $_->(@args);
    }
    
    return wantarray ? @args : $args[0];
  };
}

sub __bind {
  my ($self, $function, $object, @args) = @_ ;
  return sub { $function->($object, @args, @_) ; } ;
}

sub __has {
  my ($self, $object, $key) = @_ ;
  die 'Not a hash reference' unless ref $object && ref $object eq 'HASH';  
  exists $object->{$key} ;
}

sub __keys : method {
  my ($self, $object) = @_ ;
  die 'Not a hash reference' unless ref $object && ref $object eq 'HASH';
  [keys %$object];
}

sub __values {
  my ($self, $object) = @_ ;
  die 'Not a hash reference' unless ref $object && ref $object eq 'HASH';
  [values %$object];
}

sub __functions {
  my ($self, $object) = @_ ;
  die 'Not a hash reference' unless ref $object && ref $object eq 'HASH';
  my $functions = [];
  foreach (keys %$object) {
    push @$functions, $_
      if ref $object->{$_} && ref $object->{$_} eq 'CODE';
  }
  $functions;
}

sub ___extend {
  my ($self, $dont, @args) = @_ ;
  List::Util::reduce { 
    for my $key (keys %$b) {
      $a->{$key} = $b->{$key} unless $dont->($a, $b, $key) ;
    }
    return $a ;
  } @args ;
}

sub __extend { shift->___extend( sub {0}, @_) ; }

sub __defaults { shift->___extend( sub { exists $_[0]->{$_[2]} ; }, @_ ) ; }

sub __clone { shift->___extend( sub {0}, {}, @_ ) ; }

sub _eq {
  my ($o1, $o2) = @_ ;
  ( ref $o1 eq ref $o2 and
    $o1 ~~ $o2 and 
    ref $o1 eq 'HASH' ?
    _->all( [ keys %$o1 ], sub { _->is_equal($o1->{$_[0]}, $o2->{$_[0]}) ; } ) : 
    1 ) ;
}

sub __is_equal {
  my ($self, $object, $other) = @_ ;
  _eq($object, $other) ? 1 : 0 ; 
}

sub __is_empty {
  my ($self, $object) = @_ ;
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

sub __is_array {
  my ($self, $object) = @_ ;
  defined $object && ref $object && ref $object eq 'ARRAY' ? 1 : 0 ;
}

sub __is_string {
  my ($self, $object) = @_ ;
  return 0 unless defined $object && !ref $object;
  return 0 if $self->is_number($object);
  return 1;
}

sub __is_number {
  my ($self, $object) = @_ ;  
  return 0 unless defined $object && !ref $object;
  
  # From JSON::PP
  my $flags = B::svref_2object(\$object)->FLAGS;
  my $is_number = $flags & (B::SVp_IOK | B::SVp_NOK)
    and !($flags & B::SVp_POK) ? 1 : 0;
 
  $is_number;
}

sub __is_function {
  my ($self, $object) = @_ ;
  defined $object && ref $object && ref $object eq 'CODE' ? 1 : 0 ;
}

sub __is_regexp {
  my ($self, $object) = @_ ;
  defined $object && ref $object && ref $object eq 'Regexp' ? 1 : 0 ;
}

sub __is_undefined {
  my ($self, $object) = @_ ;
  defined $object ? 0 : 1 ;
}

sub __is_boolean {
  my ($self, $object) = @_;
  
  Scalar::Util::blessed($object)
      && ( $object->isa('Underscore::_True') || $object->isa('Underscore::_False')) ? 1 : 0 ;
}

sub chain {
  my $self = shift;
  if (@_) {
    my ($object) = $self->_prepare(@_);
    return _( $object )->chain ;
  }
  else {
    $self->{chain} = 1;
    return $self;
  }
}

sub value {
  my $self = shift ;
  return wantarray ? @{$self->{args}} : $self->{args}->[0];
}

sub _prepare {
  my $self = shift;
  unshift @_, @{$self->{args}} if defined $self->{args} && @{$self->{args}};
  return @_;
}

sub _finalize {
  my $self = shift; 
  return ( $self->{chain} ?
	   do { $self->{args} = [@_]; $self } :
	   wantarray ?
	   @_ :
	   $_[0] ) ;
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

1 ;

__END__

=head1 NAME

Underscore

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

Most of the functions are just wrappers around built-in functions.  Others use
L<List::Util> and L<List::MoreUtils> modules.

Numeric/String detection is done the same way L<JSON::PP> does it: by using
L<B> hacks.

Boolean values are implemented as overloaded methods, that return numbers or
strings depending on the context.

    _->true;
    _->false;

=head2 Object-Oriented and Functional Styles

As original Underscore.js you can use Perl version in either an object-oriented
or a functional style, depending on your preference. The following two lines of
code are identical ways to double a list of numbers.

    _->map([1, 2, 3], sub { my ($n) = @_; $n * 2; });
    _([1, 2, 3])->map(sub { my ($n) = @_; $n * 2; });

See L<http://documentcloud.github.com/underscore/#styles|original documentation>
 why sometimes object-oriented style is better.

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/vti/underscore-perl

=head1 CREDITS

Underscore.js authors and contributors.

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2012, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
