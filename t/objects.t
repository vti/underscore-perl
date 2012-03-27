use Test::Spec;
use Underscore;

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

    it 'does copies undefined values' => sub {
        is_deeply(_->extend({},  {a => 0, b => undef}), {a => 0, b => undef});
    };
};

describe 'defaults' => sub {
    my $options;

    before each => sub {
        $options = {zero => 0, one => 1, empty => "", string => "string"};
    };

    it 'should set defaults values' => sub {
        _->defaults($options, {zero => 1, one => 10, twenty => 20});
        is($options->{zero},   0);
        is($options->{one},    1);
        is($options->{twenty}, 20);
    };

    it 'should set multiple defaults' => sub {
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
    it 'should make a shallow copy' => sub {
        my $moe = {name => 'moe', lucky => [13, 27, 34]};
        my $clone = _->clone($moe);
        is($clone->{name}, 'moe');

        $clone->{name} = 'curly';
        ok($clone->{name} eq 'curly' && $moe->{name} eq 'moe');

        push @{$clone->{lucky}}, 101;
        is($moe->{lucky}->[-1], 101);
    };
};

describe 'isEqual' => sub {
  my $moe   = {name => 'moe', lucky => [13, 27, 34], juu => undef };
  my $clone = {name => 'moe', lucky => [13, 27, 34], juu => undef};

  it 'should compare object deeply' => sub {
    ok($moe ne $clone);
    ok !_->isEqual($moe, {name => 'moe', 1,2})  ;
    ok _->isEqual({}, {})  ;
    ok !_->isEqual({a => 1}, {})  ;

    # 4 ways to say the same
    ok _->isEqual($moe, $clone) ;
    ok _($moe)->isEqual($clone) ;
    ok _($moe)->chain()->isEqual($clone)->value ;
    ok _->chain($moe)->isEqual($clone)->value ;
  } ;
    
  it 'says identical regexes are equal' => sub { ok(_->isEqual(qr/hello/, qr/hello/), ) ; } ;
  it 'says a falsy is not equal to a truthy' => sub { ok(!_->isEqual(undef, [1]), ) ; } ;
  it 'says different objects are not equal', sub { ok(!_->isEqual({x => 1, y => undef}, {x => 1, z => 2}), ) ; };
} ;

#    ok(_.isEqual({isEqual: function () { return true; }}, {}), 'first object implements `isEqual`');
#    ok(_.isEqual({}, {isEqual: function () { return true; }}), 'second object implements `isEqual`');
#    ok(!_.isEqual(_({x: 1, y: undefined}).chain(), _({x: 1, z: 2}).chain()), 'wrapped objects are not equal');
#    equals(_({x: 1, y: 2}).chain().isEqual(_({x: 1, y: 2}).chain()).value(), true, 'wrapped objects are equal');
#  });

describe 'isEmpty' => sub {
    it 'should check if value is empty' => sub {
        ok(!_([1])->isEmpty());
        ok(_->isEmpty([]));

        ok(!_->isEmpty({one => 1}));
        ok(_->isEmpty({}));

        ok(_->isEmpty(qr//));
        ok(!_->isEmpty(qr/x/));

        ok(_->isEmpty(undef));
        ok(_->isEmpty());
        ok(_->isEmpty(''));
        ok(!_->isEmpty('moe'));
    };
};

# TODO
#  test("objects: isObject", function() {
#    ok(_.isObject(arguments), 'the arguments object is object');
#    ok(_.isObject([1, 2, 3]), 'and arrays');
#    ok(_.isObject($('html')[0]), 'and DOM element');
#    ok(_.isObject(iElement), 'even from another frame');
#    ok(_.isObject(function () {}), 'and functions');
#    ok(_.isObject(iFunction), 'even from another frame');
#    ok(!_.isObject(null), 'but not null');
#    ok(!_.isObject(undefined), 'and not undefined');
#    ok(!_.isObject('string'), 'and not string');
#    ok(!_.isObject(12), 'and not number');
#    ok(!_.isObject(true), 'and not boolean');
#    ok(_.isObject(new String('string')), 'but new String()');
#  });

describe 'isArray' => sub {
    it 'should check if value is an array' => sub {
        ok(_->isArray([1, 2, 3]));
    };
};

describe 'isString' => sub {
    it 'should check if value is a string' => sub {
        ok(_->isString('hello'));
        ok(!_->isString(1));
    };
};

describe 'isNumber' => sub {
    it 'should check if value is a number' => sub {
        ok(!_->isNumber('string'));
        ok(!_->isNumber(\33));
        ok(!_->isNumber('33'));
        ok( _->isNumber(0+'33'));
        ok(!_->isNumber(undef));
        ok( _->isNumber(3 * 4 - 7 / 10));
    };
};

describe 'isBoolean' => sub {
    it 'should check if value is boolean' => sub {
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
    it 'should check if value is a function' => sub {
        ok(!_->isFunction([1, 2, 3]));
        ok(!_->isFunction('moe'));
        ok(_->isFunction(sub {}));
    };
};

describe 'isRegExp' => sub {
    it 'should check if value is a regexp' => sub {
        ok(!_->isRegExp(sub { }));
        ok(_->isRegExp(qr/identity/));
    };
};

describe 'isUndefined' => sub {
    it 'should check if value is undefined' => sub {
        ok(!_->isUndefined(1), 'numbers are defined');
        ok(!_->isUndefined(_->false), 'false is defined');
        ok(!_->isUndefined(0), '0 is defined');
        ok(_->isUndefined(), 'nothing is undefined');
        ok(_->isUndefined(undef), 'undefined is undefined');
    };
};

#  test("objects: tap", function() {
#    var intercepted = null;
#    var interceptor = function(obj) { intercepted = obj; };
#    var returned = _.tap(1, interceptor);
#    equals(intercepted, 1, "passes tapped object to interceptor");
#    equals(returned, 1, "returns tapped object");
#
#    returned = _([1,2,3]).chain().
#      map(function(n){ return n * 2; }).
#      max().
#      tap(interceptor).
#      value();
#    ok(returned == 6 && intercepted == 6, 'can use tapped objects in a chain');
#  });

runtests unless caller;
