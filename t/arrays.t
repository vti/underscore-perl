use strict;
use warnings;

use Test::Spec;

use UnderscoreJS;

describe 'first' => sub {
    it 'can pull out the first element of an array' => sub {
        is(_->first([1, 2, 3]), 1);
    };

    it 'can perform OO-style "first()"' => sub {
        is(_([1, 2, 3])->first(), 1);
    };

    it 'can pass an index to first' => sub {
        is(join(', ', @{_->first([1, 2, 3], 0)}), "");
    };

    it 'can pass an index to first' => sub {
        is(join(', ', @{_->first([1, 2, 3], 2)}), '1, 2');
    };

    it 'works on an arguments object.' => sub {
        my $cb = sub { return _->first([@_]) };
        my $result = $cb->(4, 3, 2, 1);
        is($result, 4);
    };

    it 'aliased as "head"' => sub {
        is(_->head([1, 2, 3]), 1);
    };

    it 'aliased as "take"' => sub {
        is(join(', ', @{_->take([1, 2, 3], 2)}), '1, 2');
    };
};

describe 'initial' => sub {
    it 'can pull out all but the last element of an array' => sub {
        is(join(', ', @{_->initial([1, 2, 3, 4, 5])}), '1, 2, 3, 4');
    };

    it 'can take an index' => sub {
        is(join(', ', @{_->initial([1, 2, 3, 4, 5], 3)}), '1, 2, 3');
    };

    it 'handles the case of an empty array gracefully' => sub {
        ok(!@{_->initial([])});
    };

    it 'handles the case of a zero index gracefully' => sub {
        is(join(', ', @{_->initial([1, 2, 3], 0)}), '');
    };

    it 'handles the case of a negative index gracefully' => sub {
        is(join(', ', @{_->initial([1, 2, 3], -1)}), '');
    };
};

describe 'object' => sub {
    it 'zips two arrays into a single hash' => sub {
        my $result = _->object(['moe', 'larry', 'curly'], [30, 40, 50]);
        my $expected = {moe => 30, larry => 40, curly => 50};
        is_deeply($result, $expected);
    };

    it 'zips an array of key=value pairs into a single hash' => sub {
        my $result = _->object([['one', 1], ['two', 2], ['three', 3]]);
        my $expected = {one => 1, two => 2, three => 3};
        is_deeply($result, $expected);
    };
};

describe 'rest' => sub {
    it 'working rest()' => sub {
        my $numbers = [1, 2, 3, 4];
        is(join(', ', @{_->rest($numbers)}), '2, 3, 4');
        is(join(', ', @{_->rest($numbers, 0)}), '1, 2, 3, 4');
        is(join(', ', @{_->rest($numbers, 2)}), '3, 4');
    };

    it 'aliased as tail and works on arguments object' => sub {
        my $cb = sub { _([@_])->tail; };
        my $result = $cb->(1, 2, 3, 4);
        is(join(', ', @$result), '2, 3, 4');
    };
};

describe 'last' => sub {
    it 'can pull out the last element of an array' => sub {
        is(_->last([1, 2, 3]), 3);
    };

    it 'works on an arguments object' => sub {
        my $cb = sub { _([@_])->last };
        my $result = $cb->(1, 2, 3, 4);
        is($result, 4);
    };
};

describe 'compact' => sub {
    it 'can trim out all falsy values' => sub {

        is(@{_->compact([0, 1, _->false, 2, '', 3])}, 3);
    };

    it 'works on an arguments object' => sub {
        my $cb = sub { _([@_])->compact };

        my $result = $cb->(0, 1, _->false, 2, '', 3);
        is(scalar @$result, 3);
    };
};

describe 'flatten' => sub {
    it 'can flatten nested arrays' => sub {
        my $list = [1, [2], [3, [[[4]]]]];
        is(join(', ', @{_->flatten($list)}), '1, 2, 3, 4');
    };

    it 'works on an arguments object' => sub {
        my $cb = sub { _([@_])->flatten };
        my $result = $cb->([1, [2], [3, [[[4]]]]]);
        is(join(', ', @$result), '1, 2, 3, 4');
    };
};

describe 'without' => sub {
    it 'can remove all instances of an object' => sub {
        my $list = [1, 2, 1, 0, 3, 1, 4];
        is(join(', ', @{_->without($list, 0, 1)}), '2, 3, 4');
    };

    it 'works on an arguments object' => sub {
        my $cb = sub { _->without(@_, 0, 1) };
        my $result = $cb->([1, 2, 1, 0, 3, 1, 4]);
        is(join(', ', @$result), '2, 3, 4');
    };

    it 'uses real object identity for comparisons.' => sub {
        my $list = [{one => 1}, {two => 2}];
        is(@{_->without($list, {one => 1})}, 2);
        is(@{_->without($list, $list->[0])}, 1);
    };
};

describe 'uniq' => sub {
    it 'can find the unique values of an unsorted array' => sub {
        my $list = [1, 2, 1, 3, 1, 4];
        is(join(', ', @{_->uniq($list)}), '1, 2, 3, 4');
    };

    it 'can find the unique values of a sorted array faster' => sub {
        my $list = [1, 1, 1, 2, 2, 3];
        is(join(', ', @{_->uniq($list, _->true)}), '1, 2, 3',);
    };

    it 'works on an arguments object' => sub {
        my $cb = sub { _->uniq([@_]) };
        my $result = $cb->(1, 2, 3, 4);
        is(join(', ', @$result), '1, 2, 3, 4');
    };

    it 'aliased as "unique"' => sub {
        my $list = [1, 2, 1, 3, 1, 4];
        is(join(', ', @{_->unique($list)}), '1, 2, 3, 4');
    };
};

describe 'intersection' => sub {
    my $stooges;
    my $leaders;

    before each => sub {
        $stooges = ['moe', 'curly', 'larry'];
        $leaders = ['moe', 'groucho'];
    };

    it 'can take the set intersection of two arrays' => sub {
        is_deeply(_->intersection($stooges, $leaders), ['moe']);
    };

    it 'can perform an OO-style intersection' => sub {
        is_deeply(_($stooges)->intersection($leaders), ['moe']);
    };

    it 'works on an arguments object' => sub {
        my $cb = sub { _->intersection(@_, $leaders) };
        is_deeply($cb->($stooges), ['moe']);
    };
};

describe 'union' => sub {
    it 'takes the union of a list of arrays' => sub {
        my $result = _->union([1, 2, 3], [2, 30, 1], [1, 40]);
        is_deeply([sort @$result], [1, 2, 3, 30, 40]);
    };
};

describe 'difference' => sub {
    it 'takes the difference of two arrays' => sub {
        my $result = _->difference([1, 2, 3], [2, 30, 40]);
        is_deeply([sort @$result], [1, 3]);
    };
};

describe 'zip' => sub {
    it 'zipped together arrays of different lengths' => sub {
        my $names = ['moe', 'larry', 'curly'];
        my $ages  = [30,    40,      50];
        my $leaders = [_->true];
        my $stooges = _->zip($names, $ages, $leaders);
        is_deeply($stooges,
            ['moe', 30, _->true, 'larry', 40, undef, 'curly', 50, undef]);
    };
};

describe 'indexOf' => sub {

    it 'can compute indexOf' => sub {
        my $numbers = [1, 2, 3];
        is(_->indexOf($numbers, 2), 1);
    };

    it 'works on an arguments object' => sub {
        my $cb = sub { _->indexOf([@_], 2) };
        is($cb->(1, 2, 3), 1);
    };

    it 'handles nulls properly' => sub {
        is(_->indexOf(undef, 2), -1);
    };

    it '35 is not in the list' => sub {
        my $numbers = [10, 20, 30, 40, 50];
        my $num     = 35;
        my $index   = _->indexOf($numbers, $num, _->true);
        is($index, -1);
    };

    it '40 is in the list' => sub {
        my $numbers = [10, 20, 30, 40, 50];
        my $num     = 40;
        my $index   = _->indexOf($numbers, $num, _->true);
        is($index, 3);
    };

    it '40 is in the list' => sub {
        my $numbers = [1, 40, 40, 40, 40, 40, 40, 40, 50, 60, 70];
        my $num = 40;
        my $index = _->indexOf($numbers, $num, _->true);
        is($index, 1);
    };
};

describe 'lastIndexOf' => sub {
    it 'computes last index of the element in array' => sub {
        my $numbers = [1, 0, 1, 0, 0, 1, 0, 0, 0];
        is(_->lastIndexOf($numbers, 1), 5);
        is(_->lastIndexOf($numbers, 0), 8);
    };

    it 'works on an arguments object' => sub {
        my $cb = sub { _->lastIndexOf([@_], 1) };
        my $result = $cb->(1, 0, 1, 0, 0, 1, 0, 0, 0);
        is($result, 5);
    };

    it 'handles nulls properly' => sub {
        is(_->indexOf(undef, 2), -1);
    };
};

describe 'range' => sub {
    it 'range with 0 as a first argument generates an empty array' => sub {
        is_deeply(_->range(0), []);
    };

    it 'range with a single positive argument generates an array of elements 0,1,2,...,n-1' => sub {
        is_deeply(_->range(4), [0, 1, 2, 3]);
    };

    it 'range with two arguments a & b, a<b generates an array of elements a,a+1,a+2,...,b-2,b-1' => sub {
        is_deeply(_->range(5, 8), [5, 6, 7]);
    };

    it 'range with two arguments a & b, b<a generates an empty array' => sub {
        is_deeply(_->range(8, 5), []);
    };

    it 'range with three arguments a & b & c, c < b-a, a < b generates an array of elements a,a+c,a+2c,...,b - (multiplier of a) < c' => sub {
        is_deeply(_->range(3, 10, 3), [3, 6, 9]);
    };

    it 'range with three arguments a & b & c, c > b-a, a < b generates an array with a single element, equal to a' => sub {
        is_deeply(_->range(3, 10, 15), [3]);
    };

    it 'range with three arguments a & b & c, a > b, c < 0 generates an array of elements a,a-c,a-2c and ends with the number not less than b' => sub {
        is_deeply(_->range(12, 7, -2), [12, 10, 8]);
    };

    it 'final example in the Python docs' => sub {
        is_deeply(_->range(0, -10, -1), [0, -1, -2, -3, -4, -5, -6, -7, -8, -9]);
    };
};

runtests unless caller;
