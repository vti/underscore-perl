use strict;
use warnings;

use Test::Spec;

use Underscore;

describe 'value' => sub {
    it 'must return value' => sub {
        is(_(1)->value, 1);
        is_deeply(_([1, 2, 3])->value, [1, 2, 3]);
    };
};

describe 'map/flatten/reduce' => sub {
    it 'must count all the letters in the song' => sub {
        my $lyrics = [
            "I'm a lumberjack and I'm okay",
            "I sleep all night and I work all day",
            "He's a lumberjack and he's okay",
            "He sleeps all night and he works all day"
        ];
        my $counts =
          _($lyrics)->chain->map(sub { my ($line) = @_; split '', $line; })
          ->flatten->reduce(
            sub {
                my ($hash, $l) = @_;
                $hash->{$l} = $hash->{$l} || 0;
                $hash->{$l}++;
                return $hash;
            },
            {}
          )->value;
        ok($counts->{a} == 16 && $counts->{e} == 10);
    };
};

describe 'select/reject/sortBy' => sub {
    my $numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    $numbers = _($numbers)->chain->select(
        sub {
            my ($n) = @_;
            return $n % 2 == 0;
        }
      )->reject(
        sub {
            my ($n) = @_;
            return $n % 4 == 0;
        }
      )->sortBy(
        sub {
            my ($n) = @_;
            return -$n;
        }
      )->value;
    is_deeply($numbers, [10, 6, 2]);
};

describe 'reverse/concat/unshift/pop/map' => sub {
    my $numbers = [1, 2, 3, 4, 5];
    $numbers = _($numbers)
        ->chain
        ->reverse
        ->concat([5, 5, 5])
        ->unshift(17)
        ->pop
        ->map(sub { my ($n) = @_; return $n * 2; })
        ->value;
    is_deeply($numbers, [34, 10, 8, 6, 4, 2, 10, 10]);
};

runtests unless caller;
