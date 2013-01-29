use strict;
use warnings;

use Test::Spec;
use Try::Tiny;

use Underscore;

describe 'Each iterators' => sub {
    they "provide value and iteration count" => sub {
        _->each(
            [1, 2, 3] => sub {
                my ($num, $i) = @_;
                is($num, $i + 1);
            }
        );
    };

    it "context object property accessed" => sub {
        my $answers = [];

        _->each(
            [1, 2, 3] => sub {
                my ($num, undef, $ctx) = @_;
                push @$answers, $num * $ctx->{multiplier};
            },
            {multiplier => 5}
        );

        is(join(', ', @$answers), '5, 10, 15');
    };


    it 'aliased as "forEach"' => sub {
        my $answers = [];

        _->forEach(
            [1, 2, 3] => sub {
                my ($num) = @_;

                push @$answers, $num;
            }
        );
        is(join(', ', @$answers), '1, 2, 3');
    };


    it 'aliased as "for_each"' => sub {
        my $answers = [];

        _->for_each(
            [1, 2, 3] => sub {
                my ($num) = @_;

                push @$answers, $num;
            }
        );
        is(join(', ', @$answers), '1, 2, 3');
    };

    it 'iterating over objects works, and ignores the object prototype.';

    it 'can reference the original collection from inside the iterator' =>
      sub {
        my $answer = undef;

        _->each(
            [1, 2, 3] => sub {
                my ($num, $index, $arr) = @_;

                if (_->include($arr, $num)) {
                    $answer = 1;
                }
            }
        );

        ok($answer);
      };

    it 'handles a null properly' => sub {
        my $answers = 0;
        _->each(
            undef,
            sub {
                ++$answers;
            }
        );
        is($answers, 0);
    };
};

describe 'A map' => sub {
    it 'doubled numbers' => sub {
        my $doubles = _->map(
            [1, 2, 3] => sub {
                my ($num) = @_;

                return $num * 2;
            }
        );

        is(join(', ', @$doubles), '2, 4, 6');
    };

    it 'tripled numbers with context' => sub {
        my $triples = _->map(
            [1, 2, 3] => sub {
                my ($num, $key, $context) = @_;

                return $num * $context->{multiplier};
            },
            {multiplier => 3}
        );

        is(join(', ', @$triples), '3, 6, 9');
    };

    it 'OO-style doubled numbers' => sub {
        my $doubled =
          _([1, 2, 3])->map(sub { my ($num) = @_; return $num * 2; });
        is(join(', ', @$doubled), '2, 4, 6');
    };

    it 'aliased as "collect"' => sub {
        my $doubled =
          _([1, 2, 3])->collect(sub { my ($num) = @_; return $num * 2; });
        is(join(', ', @$doubled), '2, 4, 6');
    };

    it 'handles a null properly' => sub {
        my $ifnull = _->map(undef, sub { });
        ok(_->isArray($ifnull) && @$ifnull == 0);
    };
};

describe 'Reduce' => sub {
    it 'can sum up an array' => sub {
        my $sum = _->reduce(
            [1, 2, 3] => sub {
                my ($sum, $num) = @_;

                return $sum + $num;
              } => 0
        );
        is($sum, 6);
    };

    it 'can reduce with a context object' => sub {
        my $context = {multiplier => 3};
        my $sum = _->reduce(
            [1, 2, 3] => sub {
                my ($sum, $num, $context) = @_;
                return $sum + $num * $context->{multiplier};
              } => 0,
            $context
        );
        is($sum, 18);
    };

    it 'aliased as "inject"' => sub {
        my $sum = _->inject(
            [1, 2, 3] => sub {
                my ($sum, $num) = @_;

                return $sum + $num;
              } => 0
        );
        is($sum, 6);
    };

    it 'OO-style reduce' => sub {
        my $sum = _([1, 2, 3])->reduce(
            sub {
                my ($sum, $num) = @_;

                return $sum + $num;
              } => 0
        );
        is($sum, 6);
    };

    it 'default initial value' => sub {
        my $sum = _->reduce(
            [1, 2, 3] => sub {
                my ($sum, $num) = @_;
                return $sum + $num;
            }
        );
        is($sum, 6);
    };

    it 'handles a null (without inital value) properly' => sub {
        my $ifnull;

        try {
            _->reduce(undef, sub { });
        }
        catch {
            $ifnull = $_;
        };

        ok($ifnull);
    };

    it 'handles a null (with initial value) properly' => sub {
        is(_->reduce(undef, sub { }, 138), 138);
    };

    it 'initially-sparse arrays with no memo' => sub {
        my $sparseArray = [];
        $sparseArray->[100] = 10;
        $sparseArray->[200] = 20;

        my $result = _->reduce(
            $sparseArray => sub { my ($a, $b) = @_; return $a + $b }
        );
        is($result, 30);
    };
};

describe 'rightReduce' => sub {
    it 'can perform right folds' => sub {
        my $list = _->reduceRight(
            ['foo', 'bar', 'baz'] => sub {
                my ($memo, $str) = @_;

                return $memo . $str;
              } => ''
        );
        is($list, 'bazbarfoo');
    };

    it 'aliased as "foldr"' => sub {
        my $list = _->foldr(
            ['foo', 'bar', 'baz'] => sub {
                my ($memo, $str) = @_;

                return $memo . $str;
              } => ''
        );
        is($list, 'bazbarfoo');
    };

    it 'default initial value' => sub {
        my $list = _->foldr(
            ['foo', 'bar', 'baz'] => sub {
                my ($memo, $str) = @_;
                return $memo . $str;
            }
        );
        is($list, 'bazbarfoo');
    };

    it 'handles a null (without inital value) properly' => sub {
        my $ifnull;
        try {
            _->reduceRight(undef, sub { });
        }
        catch {
            $ifnull = @_;
        };
        ok($ifnull);
    };

    it 'handles a null (with initial value) properly' => sub {
        is(_->reduceRight(undef, sub { }, 138), 138);
    };
};

describe 'detect' => sub {
    it 'found the first "2" and broke the loop' => sub {
        my $result =
          _->detect([1, 2, 3] => sub { my ($num) = @_; return $num * 2 == 4 }
          );
        is($result, 2);
    };
    it 'aliased as find' => sub {
        my $result =
          _->find([1, 2, 3] => sub { my ($num) = @_; return $num % 2 == 0 }
          );
        is($result, 2);
    };
};

describe 'select' => sub {
    it 'selected each even number' => sub {
        my $evens =
          _->select([1, 2, 3, 4, 5, 6] =>
              sub { my ($num) = @_; return $num % 2 == 0; });
        is(join(', ', @$evens), '2, 4, 6');
    };

    it 'aliased as filter' => sub {
        my $evens =
          _->filter([1, 2, 3, 4, 5, 6] =>
              sub { my ($num) = @_; return $num % 2 == 0; });
        is(join(', ', @$evens), '2, 4, 6');
    };
};

describe 'reject' => sub {
    it 'rejected each even number' => sub {
        my $odds = _->reject(
            [1, 2, 3, 4, 5, 6] => sub {
                my ($num) = @_;

                return $num % 2 == 0;
            }
        );
        is(join(', ', @$odds), '1, 3, 5');
    };
};

describe 'shuffle' => sub {
    it 'returns a list with the same number of elements' => sub {
        my $source = [ 1, 2, 3 ];
        is(scalar @{_->shuffle($source)}, scalar @$source);
    };
};

describe 'all' => sub {

    it 'given an empty array returns 1' => sub {
       ok(_->all([], sub { die 'Iterator must not be called for the empty array.' }));
    };

    it 'even numbers' => sub {
        ok( _->all(
                [0, 10, 28] => sub { $_ % 2 == 0 }
            )
        );
    };

    it 'odd number' => sub {
        ok( !_->all(
                [0, 11, 28] => sub { my ($num) = @_; return $num % 2 == 0 }
            )
        );
    };

    it 'aliased every' => sub {
       ok(_->every([1, 1, 1], sub { shift == 1; }));
    };
};

describe 'any' => sub {
    it 'the empty set' => sub {
        ok(!_->any([]));
    };

    it 'all false values' => sub {
        ok(!_->any([0, 0, 0]));
    };

    it 'one true value' => sub {
        ok(_->any([0, 0, 1]));
    };

    it 'all odd numbers' => sub {
        ok( !_->any(
                [1, 11, 29] => sub { my ($num) = @_; return $num % 2 == 0 }
            )
        );
    };

    it 'all even numbers' => sub {
        ok( _->any(
                [1, 10, 29] => sub { my ($num) = @_; return $num % 2 == 0 }
            )
        );
    };

    it 'aliased as "some"' => sub {
        ok(_->some([0, 0, 1]));
    };
};

describe 'include' => sub {
    it 'two is in the array' => sub {
        ok(_->include([1, 2, 3], 2));
    };

    it 'two is not in the array' => sub {
        ok(!_->include([1, 3, 9], 2));
    };

    it '_->include on objects checks their values' => sub {
        ok(_->contains({moe => 1, larry => 3, curly => 9}, 3));
    };

    it 'OO-style include' => sub {
        ok(_([1, 2, 3])->include(2));
    };
};

describe 'invoke w/ function reference' => sub {
    my $list;
    my $result;

    before each => sub {
        $list = [[5, 1, 7], [3, 2, 1]];
        $result = _->invoke($list, sub { sort(@_) });
    };

    it 'first array sorted' => sub {
        is(join(', ', @{$result->[0]}), '1, 5, 7');
    };

    it 'second array sorted' => sub {
        is(join(', ', @{$result->[1]}), '1, 2, 3');
    };
};

describe 'pluck' => sub {
    it 'pulls names out of objects' => sub {
        my $people =
          [{name => 'moe', age => 30}, {name => 'curly', age => 50}];
        is(join(', ', @{_->pluck($people, 'name')}), 'moe, curly');
    };
};

describe 'max' => sub {
    it 'can perform a regular Math.max' => sub {
        is(_->max([1, 2, 3]), 3);
    };

    it 'can perform a computation-based max' => sub {
       my $neg = _->max([1, 2, 3], sub { my ($num) = @_; return -$num; });
       is($neg, 1);
    };
};

describe 'min' => sub {
    it 'can perform a regular Math.min' => sub {
        is(_->min([1, 2, 3]), 1);
    };

    it 'can perform a computation-based min' => sub {
       my $neg = _->min([1, 2, 3], sub { my ($num) = @_; return -$num; });
       is($neg, 3);
    };
};

describe 'sort' => sub {
    it 'sorts regularly' => sub {
        my $list = [3, 2, 1];
        is_deeply(_($list)->sort, [1, 2, 3]);
    };
};

describe 'sortBy' => sub {
    it 'stooges sorted by age' => sub {
        my $people =
          [{name => 'curly', age => 50}, {name => 'moe', age => 30}];
        $people =
          _->sortBy($people,
            sub { my ($person) = @_; return $person->{age}; });
        is(join(', ', @{_->pluck($people, 'name')}), 'moe, curly');
    };
};

describe 'groupBy' => sub {
    it 'put each even number in the right group' => sub {
        my $parity = _->groupBy([1, 2, 3, 4, 5, 6],
            sub { my ($num) = @_; return $num % 2; });
        is(join(', ', @{$parity->{0}}), '2, 4, 6');
    };
};

describe 'countBy' => sub {
    it 'returns a count for the number of objects in each group' => sub {
        my $parity = _->countBy([1, 2, 3, 4, 5],
            sub { my ($num) = @_; return $num % 2 == 0 ? 'true' : 'false'; });
        is($parity->{true}, 2);
        is($parity->{false}, 3);
    };
    it 'is aliased as count_by' => sub {
        my $parity = _->count_by([1, 2, 3, 4, 5],
            sub { my ($num) = @_; return $num == 3 ? 'true' : 'false'; });
        is($parity->{true}, 1);
        is($parity->{false}, 4);
    };
};

describe 'sortedIndex' => sub {
    it '35 must be inserted at index 3' => sub {
        my $numbers = [10, 20, 30, 40, 50];
        my $num     = 35;
        my $index   = _->sortedIndex($numbers, $num);
        is($index, 3);
    };
};

describe 'toArray' => sub {
    it 'arguments object is not an array' => sub {
        ok(!_->isArray(my $arguments));
    };

    it 'arguments object converted into array' => sub {
        ok(_->isArray(_->toArray(my $arguments)));
    };

    it 'cloned array contains same elements' => sub {
        my $a = [1, 2, 3];
        ok(_->toArray($a) ne $a);
        is(join(', ', @{_->toArray($a)}), '1, 2, 3');
    };

    it 'object flattened into array' => sub {
        my $numbers = _->toArray({one => 1, two => 2, three => 3});
        is(join(', ', sort @$numbers), '1, 2, 3');
    };
};

describe 'size' => sub {
    it 'can compute the size of an object' => sub {
        is(_->size({one => 1, two => 2, three => 3}), 3);
    };
};

runtests unless caller;
