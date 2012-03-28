package Underscore;

use strict;
use warnings;
use v5.10.1 ;

use constant VERSION => '0.02' ;
our $VERSION = VERSION ;

use B               ();
use List::MoreUtils ();
use List::Util      ();
use Scalar::Util    ();

#use Smart::Comments ;

our $UNIQUE_ID = 0;
our $self ;
our %ONCE ;

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
  my $self = +{@_};
  
  $self->{template_settings} = { evaluate    => qr/<\%([\s\S]+?)\%>/,
				 interpolate => qr/<\%=([\s\S]+?)\%>/
			       } ;  
  bless $self, $class;
}

sub true  { Underscore::_True->new }
sub false { Underscore::_False->new }

my %u
  = ( mixin => sub {
	my (%functions) = @_ ;
	
	no strict 'refs';
	no warnings 'redefine';
	while ( my ( $name, $sub ) = each %functions ) {
	  *{__PACKAGE__ . '::' . $name} = sub : method { 
	    local $self = shift ;
	    $self->_wrap($sub, @_) ;
	  } ;
	}
      },
      each => sub {
	my ($obj, $cb, $context) = @_ ;
	return unless defined $obj;
		
	if (ref $obj eq 'ARRAY') {
	  my $i = 0;
	  foreach (@$obj) {
	    $cb->($_, $i, $obj, $context);
	    $i++;
	  }
	} elsif (ref $obj eq 'HASH') {
	  while (my ($k, $v) = each %$obj) {
	    $cb->($v, $k, $obj, $context);
	  }
	}
      },
      extend => sub { _extend(sub {1}, @_) ; },
      defaults => sub { _extend(sub { not exists $_[0]->{$_[2]} ; }, @_) ; },
      clone => sub { _extend( sub {1}, {}, @_ ) ; },
      map => sub {
	my ($obj, $cb, $context) = @_ ;
	return ( ref $obj eq 'ARRAY' ?
		 [map { $cb->($obj->[$_], $_, $obj, $context) } 0 .. $#$obj] :
		 ref $obj eq 'HASH' ?
		 [map { $cb->($obj->{$_}, $_, $obj, $context) } keys %$obj] :
		 _->is_empty($obj) ?
		 [] :
		 undef ) ;
      },
      include => sub {
	my ($list, $value) = @_ ; 
	( ref $list eq 'ARRAY' ? 
	  (( List::Util::first { $_ eq $value } @$list) ? 1 : 0 ) :
	  ref $list eq 'HASH' ? 
	  ((List::Util::first { $_ eq $value } values %$list) ? 1 : 0 ) :
	  die 'WTF?' ) ;
      },
      reduce => sub {
	my ($array, $iterator, $memo, $context) = @_ ;
	die 'TypeError' if !defined $array && !defined $memo;
  
	# TODO
	$memo //= 0 ;
	return $memo unless defined $array;
  
	foreach (@$array) {
	  $memo = $iterator->($memo, $_, $context) if defined $_;
	}
	return $memo ;
      },
      reduce_right => sub {
	my ($array, $iterator, $memo, $context) = @_ ;

	die 'TypeError' if !defined $array && !defined $memo;

	# TODO
	$memo //= '' ;
	return $memo unless defined $array;

	foreach (reverse @$array) {
	  $memo = $iterator->($memo, $_, $context) if defined $_;
	}

	return $memo;
      },
      detect => sub {
	my ($list, $iterator, $context) = @_ ;
	List::Util::first { $iterator->($_) } @$list;
      },
      select => sub {
	my ($list, $iterator, $context) = @_ ;
	[grep { $iterator->($_) } @$list];
      },
      reject => sub {
	my ($list, $iterator, $context) = @_ ;
	[grep { !$iterator->($_) } @$list];
      },
      all => sub {
	my ($list, $iterator, $context) = @_ ;
	foreach (@$list) {
	  return 0 unless $iterator->($_);
	}  
	return 1;
      },
      any => sub {
	my ($list, $iterator, $context) = @_ ;  
	return 0 unless defined @$list;
	foreach (@$list) {
	  return 1 if $iterator ? $iterator->($_) : $_;
	}  
	return 0;
      },
      invoke => sub {
	my ($list, $method, @args) = @_ ;
	[ map { ref $method eq 'CODE' ? $method->($_, @args) : $self->$method($_, @args) }
	  @$list ] ;
      },
      pluck => sub {
	my ($list, $key) = @_ ;  
	[ map { $_->{$key} } @$list ] ;
      },
      min => sub {
	my ($list, $iterator, $context) = @_ ;
	_compared(\&List::Util::min, $list, $iterator, $context ) ;
      },
      max => sub {
	my ($list, $iterator, $context) = @_ ;
	_compared(\&List::Util::max, $list, $iterator, $context ) ;
      },
      sort => sub {
	my ($list) = @_ ;
	[sort @$list];
      },
      sort_numeric => sub {
	my ($list) = @_ ;
	[sort { $a <=> $b } @$list];
      },
      sort_by => sub {
	my ($list, $test, $key, $context) = @_ ;
	$test //= sub { $_[0] cmp $_[1] } ;
	$key //= _->identity ;
	[sort { $test->( map $key->($_, $context), $a, $b ) } @$list];
      },
      reverse => sub {
	my ($list) = @_ ;
	[reverse @$list];
      },
      concat => sub {
	my ($list, $other) = @_ ;
	[@$list, @$other];
      },
      unshift => sub {
	my ($list, @elements) = @_ ;
	unshift @$list, @elements;
	$list;
      },
      pop => sub {
	my ($list) = @_ ;
	pop @$list;
	$list;
      },
      group_by => sub {
	my ($list, $iterator) =  @_ ;
	my $key = ref $iterator eq 'CODE' ? $iterator : sub { $_[0]->{$iterator} } ;
	my %result ;
	foreach (@{$list}) {
	  my $group = $key->($_);
	  if (exists $result{$group}) {
	    push @{$result{$group}}, $_;
	  } else {
	    $result{$group} = [$_];
	  }
	}
	\%result ;
      },
      shuffle => sub {
	my ($list ) = @_ ;  
	my @shuffled ;
	my $rand ;
	my $index = 0 ;
	for my $value (@$list) {
	  if ($index == 0) {
	    $shuffled[0] = $value;
	  } else {
	    $rand = int(rand() * ($index + 1)) ;
	    $shuffled[$index] = $shuffled[$rand] ;
	    $shuffled[$rand] = $value;
	  }
	  $index++ ;
	} 
	\@shuffled ;
      },
      sorted_index => sub {
	my ($list, $value, $test, $key) = @_ ;
	$test //= sub { $_[0] cmp $_[1] } ;
	$key //= _->identity ;

	my $low = 0;
	my $high = @$list;

	while ($low < $high) {
	  my $mid = ($low + $high) >> 1;
	  if ( $test->( map { $key->($_) } $list->[$mid], $value ) < 0 ) {
	    $low = $mid + 1 ;
	  } else {
	    $high = $mid ;
	  } 
	}
	return $low ;
      },
      to_array => sub {
	my ($list) = @_ ;
	return [values %$list] if ref $list eq 'HASH';
	return [$list] unless ref $list eq 'ARRAY';
	return [@$list];
      },
      size => sub {
	my ($list) =  @_ ;
	( ref $list eq 'ARRAY' ?
	  scalar @$list :
	  ref $list eq 'HASH' ?
	  scalar keys %$list :
	  1 ) ;
      },
      first => sub {
	my ($array, $n) = @_ ;
	return defined $n ? [@{$array}[0 .. $n - 1]] : $array->[0] ;
      },
      rest => sub {
	my ($array, $index) = @_ ;
	$index //= 1 ;
	return [@{$array}[$index .. $#$array]];
      },
      last => sub {
	my ($array, $count) = @_ ;
	$count //= 1 ;
	return $count == 1 ? $array->[-1] : [ @$array[ -$count .. -1 ] ] ;
      },
      compact => sub {
	my ($array) = @_ ;
	[ grep { $_ } @$array ] ;
      },
      flatten => sub {
	my ($array) = @_ ;
	my $cb ;
	$cb = sub {
	  my $result = [];
	  foreach (@{$_[0]}) {
	    if (ref $_ eq 'ARRAY') {
	      push @$result, @{$cb->($_)};
	    } else {
	      push @$result, $_;
	    }
	  }
	  return $result;
	} ;
	$cb->($array) ;  
      },
      without => sub {
	my ($array, @values) = @_ ;
  
	my $new_array = [];
	foreach my $el (@$array) {
	  push @$new_array, $el
	    unless 0 <= List::MoreUtils::first_index { $el eq $_ } @values;
	}
	$new_array;
      },
      uniq => sub {
	my ($array, $is_sorted) = @_ ;
	return [List::MoreUtils::uniq(@$array)] unless $is_sorted;
  
	List::Util::reduce {
	  push @$a, $b if !@$a or $a->[-1] ne $b ;
	  return $a ;
	} [], @$array ;
      },
      intersection => sub {
	my (@arrays) = @_ ;
	my $seen = {};
	foreach my $array (@arrays) {
	  $seen->{$_}++ for @$array;
	}
	[ grep { $seen->{$_} == @arrays } keys %$seen ] ;
      },
      union => sub {
	my (@arrays) = @_ ;  
	my %seen ;
	foreach my $array (@arrays) {
	  $seen{$_}++ for @$array;
	}
	[keys %seen];
      },
      difference => sub {
	my ($array, @other) = @_ ;
	my %seen ;
	foreach my $array (@other) {
	  $seen{$_ // ''}++ for @$array;
	}
	[grep { not $seen{$_ // ''} } @$array];
      },
      zip => sub {
	my (@arrays) = @_ ;  
	my $max = List::Util::reduce { $#$b > $a ? $#$b : $a} -1, @arrays ;
	[ map {
	  my $ix = $_;
	  [map $_->[$ix], @arrays];
	} 0 .. $max
	] ;
      },
      index_of => sub {
	my ($array, $value, $is_sorted) = @_ ;
  
	return -1 unless defined $array;
	return List::MoreUtils::first_index { $_ eq $value } @$array;
      },
      last_index_of => sub {
	my ($array, $value, $is_sorted) = @_ ;
  
	return -1 unless defined $array;  
	return List::MoreUtils::last_index { $_ eq $value } @$array;
      },
      range => sub {
	my ($start, $stop, $step) =
	  @_ >= 2 ? @_ : (undef, @_, undef);
  
	return [] unless $stop;  
	$start //= 0 ;
  
	return [$start .. $stop-1] unless defined $step;
  
	my $new_array = [];
	while ($start < $stop) {
	  push @$new_array, $start;
	  $start += $step;
	}
	$new_array;
      },
      unique_id => sub {
	my ($prefix) = @_ ;
	$prefix //= '' ;
	$prefix . ($UNIQUE_ID++);
      },
      identity => sub { sub { return $_[0] ; } ; },
      times => sub {
	my ($n, $iterator) = @_ ;
	$iterator->($_) for 0 .. $n - 1 ;
      },
      template_settings => sub {
	my (%args) = @_;
	for (qw/interpolate evaluate/) {
	  if (my $value = $args{$_}) {
	    $self->{template_settings}->{$_} = $value;
	  }
	}
      },
      template => sub {
	my ($template) = @_ ;
 
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
      },
      once => sub {
	my ($func) = @_;
	return sub {
	  return if $ONCE{"$func"};
    
	  $ONCE{"$func"}++;
	  $func->(@_);
	};
      },
      wrap => sub {
	my ($function, $wrapper) = @_ ;
	sub { $wrapper->($function, @_) ; };
      },
      compose => sub {
	my (@functions) = @_;
  
	return sub {
	  my @args = @_;
	  foreach (reverse @functions) {
	    @args = $_->(@args);
	  }
    
	  return wantarray ? @args : $args[0];
	};
      },
      bind => sub {
	my ($function, $object, @args) = @_ ;
	return sub { $function->($object, @args, @_) ; } ;
      },
      has => sub {
	my ($object, $key) = @_ ;
	die 'Not a hash reference' unless ref $object && ref $object eq 'HASH';  
	exists $object->{$key} ;
      },
      keys => sub {
	my ($object) = @_ ;
	die 'Not a hash reference' unless ref $object && ref $object eq 'HASH';
	[keys %$object];
      },
      values => sub {
	my ($object) = @_ ;
	die 'Not a hash reference' unless ref $object && ref $object eq 'HASH';
	[values %$object];
      },
      functions => sub {
	my ($object) = @_ ;
	die 'Not a hash reference' unless ref $object && ref $object eq 'HASH';
	[ grep { ref $object->{$_} && ref $object->{$_} eq 'CODE'; } keys %$object ] ;
      },
      is_equal => sub {
	my ($object, $other) = @_ ;
	_eq($object, $other) ? 1 : 0 ; 
      },
      is_empty => sub {
	my ($object) = @_ ;
	return 1 unless defined $object;
	my $ref = ref $object ;
	if (!$ref) {
	  return 1 if $object eq '';
	}
	elsif ($ref eq 'HASH') {
	  return 1 if !(keys %$object);
	}
	elsif ($ref eq 'ARRAY') {
	  return 1 if @$object == 0;
	}
	elsif ($ref eq 'Regexp') {
	  return 1 if $object eq qr//;
	}
	return 0 ;
      },
      is_array => sub {
	my ($object) = @_ ;
	defined $object && ref $object && ref $object eq 'ARRAY' ? 1 : 0 ;
      },
      is_string => sub {
	my ($object) = @_ ;
	return 0 unless defined $object && !ref $object;
	return 0 if $self->is_number($object);
	return 1;
      },
      is_number => sub {
	my ($object) = @_ ;  
	return 0 unless defined $object && !ref $object;
  
	# From JSON::PP
	my $flags = B::svref_2object(\$object)->FLAGS;
	( $flags & (B::SVp_IOK | B::SVp_NOK) and !($flags & B::SVp_POK) ) ? 1 : 0 ;
      },
      is_function => sub {
	my ($object) = @_ ;
	defined $object && ref $object && ref $object eq 'CODE' ? 1 : 0 ;
      },
      is_regexp => sub {
	my ($object) = @_ ;
	defined $object && ref $object && ref $object eq 'Regexp' ? 1 : 0 ;
      },
      is_undefined => sub {
	my ($object) = @_ ;
	defined $object ? 0 : 1 ;
      },
      is_boolean => sub {
	my ($object) = @_;
	Scalar::Util::blessed($object)
	    && ( $object->isa('Underscore::_True') || $object->isa('Underscore::_False')) ? 1 : 0 ;
      },
    ) ;

$u{$_->[0]} = $u{$_->[1]} for
  ( ['forEach', 'each'],
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

$u{mixin}->(%u) ;

sub chain {
  my $self = shift ;
  if (@_) {
    my @args = $self->_prepare(@_);
    return _( @args )->chain ;
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

sub _wrap {
  my ($self, $sub, @args) = @_ ;
  $self->_finalize( $sub->( $self->_prepare(@args) ) ) ;
}

sub _extend {
  my ($include, @args) = @_ ;
  List::Util::reduce { 
    for my $key (keys %$b) {
      $a->{$key} = $b->{$key} if $include->($a, $b, $key) ;
    }
    return $a ;
  } @args ;
}

sub _eq {
  my ($o1, $o2) = @_ ;
  ( ref $o1 eq ref $o2 and
    $o1 ~~ $o2 and 
    ref $o1 eq 'HASH' ?
    ( List::MoreUtils::all { _->is_equal($o1->{$_[0]}, $o2->{$_[0]}) ; } keys %$o1 ) :
    1 ) ;
}

sub _compared {
  my ($comparator, $list, $iterator, $context) = @_ ;
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
