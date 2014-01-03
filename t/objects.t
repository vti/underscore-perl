use strict;
use warnings;

use Test::Spec;

use UnderscoreJS;

describe 'keys' => sub {
    it 'can extract the keys from an object' => sub {
        is_deeply(_->keys({one => 1, two => 2}), ['one', 'two'])
    };

    it 'throws an error for undefined values' => sub {
        eval {_->keys(undef)};
        ok $@;
    };

    it 'throws an error for number primitives' => sub {
        eval {_->keys(1)};
        ok $@;
    };

    it 'throws an error for string primitives' => sub {
        eval {_->keys('foo')};
        ok $@;
    };

    it 'throws an error for boolean primitives' => sub {
        eval {_->keys(_->true)};
        ok $@;
    };
};

describe 'values' => sub {
    it 'can extract the values from an object' => sub {
        is_deeply(_->values({one => 1, two => 2}), [1, 2]);
    };
};

describe 'pairs' => sub {
    it 'can convert a hash into pairs' => sub {
        is_deeply(_->pairs({one => 1, two => 2}), [['one', 1], ['two', 2]]);
    };
};

describe 'pick' => sub {
    it 'can restrict properties to those named' => sub {
        is_deeply(_->pick({a=>1, b=>2, c=>3}, 'a', 'c'), {a=>1, c=>3});
    };
    it 'can restrict properties to those named in an array' => sub {
        is_deeply(_->pick({a=>1, b=>2, c=>3}, ['a', 'c']), {a=>1, c=>3});
    };
    it 'can restrict properties to those named in a mix' => sub {
        is_deeply(_->pick({a=>1, b=>2, c=>3}, ['a'], 'c'), {a=>1, c=>3});
    };
};

describe 'omit' => sub {
    it 'can omit a single key' => sub {
        is_deeply(_->omit({a=>1, b=>2, c=>3}, 'b'), {a=>1, c=>3});
    };
    it 'can omit many keys' => sub {
        is_deeply(_->omit({a=>1, b=>2, c=>3}, 'b', 'a'), {c=>3});
    };
    it 'can omit many keys in an array' => sub {
        is_deeply(_->omit({a=>1, b=>2, c=>3}, ['b', 'a']), {c=>3});
    };
    it 'can omit many keys in a mix' => sub {
        is_deeply(_->omit({a=>1, b=>2, c=>3}, ['b'], 'a'), {c=>3});
    };
};

describe 'functions' => sub {
    it 'can grab the function names of any passed-in object' => sub {
        my $cb = sub {};
        my $result = _->functions({a => 'dash', b => sub {}, c => qr//, d => sub {}});
        is_deeply($result, ['b', 'd']);
    };
};

describe 'extend' => sub {
    it 'can extend an object with the attributes of another' => sub {
        is_deeply(_->extend({}, {a => 'b'}), {a => 'b'});
    };

    it 'properties in source override destination' => sub {
        is_deeply(_->extend({a => 'x'}, {a => 'b'}), {a => 'b'});
    };

    it 'properties not in source dont get overriden' => sub {
        is_deeply(_->extend({x => 'x'}, {a => 'b'}), {x => 'x', a => 'b'});
    };

    it 'can extend from multiple source objects' => sub {
        is_deeply(_->extend({x => 'x'}, {a => 'a'}, {b => 'b'}),
            {x => 'x', a => 'a', b => 'b'});
    };

    it 'extending from multiple source objects last property trumps' => sub {
        is_deeply(_->extend({x => 'x'}, {a => 'a', x => 2}, {a => 'b'}),
            {x => '2', a => 'b'});
    };

    it 'does not copy undefined values' => sub {
        is_deeply(_->extend({},  {a => 0, b => undef}), {a => 0});
    };
};

describe 'defaults' => sub {
    my $options;

    before each => sub {
        $options = {zero => 0, one => 1, empty => "", string => "string"};
    };

    it 'must set defaults values' => sub {
        _->defaults($options, {zero => 1, one => 10, twenty => 20});
        is($options->{zero},   0);
        is($options->{one},    1);
        is($options->{twenty}, 20);
    };

    it 'must set multiple defaults' => sub {
        _->defaults(
            $options,
            {empty => "full"},
            {word  => "word"},
            {word  => "dog"}
        );
        is($options->{empty}, "");
        is($options->{word},  "word");
    };
};

describe 'clone' => sub {
    it 'must make a shallow copy' => sub {
        my $moe = {name => 'moe', lucky => [13, 27, 34]};
        my $clone = _->clone($moe);
        is($clone->{name}, 'moe');

        $clone->{name} = 'curly';
        ok($clone->{name} eq 'curly' && $moe->{name} eq 'moe');

        push @{$clone->{lucky}}, 101;
        is($moe->{lucky}->[-1], 101);
    };
};

# TODO
describe 'isEqual' => sub {
   it 'must compare object deeply' => sub {
       my $moe   = {name => 'moe', lucky => [13, 27, 34]};
       my $clone = {name => 'moe', lucky => [13, 27, 34]};
       ok($moe ne $clone);
       ok(_->isEqual($moe, $clone));
       ok(_($moe)->isEqual($clone));
   };
};

describe 'isEmpty' => sub {
    it 'must check if value is empty' => sub {
        ok(!_([1])->isEmpty());
        ok(_->isEmpty([]));
        ok(!_->isEmpty({one => 1}));
        ok(_->isEmpty({}));
        ok(_->isEmpty(qr//));
        ok(_->isEmpty(undef));
        ok(_->isEmpty());
        ok(_->isEmpty(''));
        ok(!_->isEmpty('moe'));
    };
};

describe 'isArray' => sub {
    it 'must check if value is an array' => sub {
        ok(_->isArray([1, 2, 3]));
    };
};

describe 'isString' => sub {
    it 'must check if value is a string' => sub {
        ok(_->isString('hello'));
        ok(!_->isString(1));
    };
};

describe 'isNumber' => sub {
    it 'must check if value is a number' => sub {
        ok(!_->isNumber('string'));
        ok(!_->isNumber(undef));
        ok(_->isNumber(3 * 4 - 7 / 10));
    };
};

describe 'isBoolean' => sub {
    it 'must check if value is boolean' => sub {
        ok(!_->isBoolean(2),        'a number is not a boolean');
        ok(!_->isBoolean("string"), 'a string is not a boolean');
        ok(!_->isBoolean("false"),  'the string "false" is not a boolean');
        ok(!_->isBoolean("true"),   'the string "true" is not a boolean');
        ok(!_->isBoolean(undef),    'undefined is not a boolean');
        ok(_->isBoolean(_->true),   'but true is');
        ok(_->isBoolean(_->false),  'and so is false');
    };
};

describe 'isFunction' => sub {
    it 'must check if value is a function' => sub {
        ok(!_->isFunction([1, 2, 3]));
        ok(!_->isFunction('moe'));
        ok(_->isFunction(sub {}));
    };
};

describe 'isRegExp' => sub {
    it 'must check if value is a regexp' => sub {
        ok(!_->isRegExp(sub { }));
        ok(_->isRegExp(qr/identity/));
    };
};

describe 'isUndefined' => sub {
    it 'must check if value is undefined' => sub {
        ok(!_->isUndefined(1), 'numbers are defined');
        ok(!_->isUndefined(_->false), 'false is defined');
        ok(!_->isUndefined(0), '0 is defined');
        ok(_->isUndefined(), 'nothing is undefined');
        ok(_->isUndefined(undef), 'undefined is undefined');
    };
};

runtests unless caller;
