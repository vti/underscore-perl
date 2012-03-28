use Test::Spec;
use Underscore;

describe 'bind' => sub {
    it 'can bind a function to a context' => sub {
        my $context = {name => 'moe'};
        my $func = sub {
            my ($this, $arg) = @_;
            return "name: " . ($this->{name} || $arg);
        };
        my $bound = _->bind($func, $context);
        is($bound->(), 'name: moe');

        $bound = _($func)->bind($context);
        is($bound->(), 'name: moe', 'can do OO-style binding');
    };

    it 'can bind without specifying a context' => sub {
        my $func = sub {
            my ($this, $arg) = @_;
            return "name: " . ($this->{name} || $arg);
        };
        my $bound = _->bind($func, undef, 'curly');
        is($bound->(), 'name: curly');
    };

    it 'the function was partially applied in advance' => sub {
        my $func = sub {
            my ($this, $salutation, $name) = @_;
            return $salutation . ': ' . $name;
        };
        $func = _->bind($func, {}, 'hello');
        is($func->('moe'), 'hello: moe', );
    };

    it 'the function was completely applied in advance' => sub {
      my $func = _->bind(sub { 'hello: ' . $_[1] }, {}, 'curly');
      is($func->(), 'hello: curly');
    };

    it 'the function was partially applied in advance and can accept multiple arguments'
      => sub {
        my $func = sub {
            my ($this, $salutation, $firstname, $lastname) = @_;
            return $salutation . ': ' . $firstname . ' ' . $lastname;
        };
        $func = _->bind($func, {}, 'hello', 'moe', 'curly');
        is($func->(), 'hello: moe curly');
      };

    describe 'edge cases' => sub {
        my $func = sub {
            my ($this, $context) = @_;

            is($this, $context);
        };

        it 'can bind a function to 0' => sub {
            _->bind($func, 0, 0)->();
        };

        it 'can bind a function to empty string' => sub {
            _->bind($func, '', '')->();
        };

        it 'can bind a function to false' => sub {
            _->bind($func, _->false, _->false)->();
        };
    };
};

#  test("functions: bindAll", function() {
#    var curly = {name : 'curly'}, moe = {
#      name    : 'moe',
#      getName : function() { return 'name: ' + this.name; },
#      sayHi   : function() { return 'hi: ' + this.name; }
#    };
#    curly.getName = moe.getName;
#    _.bindAll(moe, 'getName', 'sayHi');
#    curly.sayHi = moe.sayHi;
#    equals(curly.getName(), 'name: curly', 'unbound function is bound to current object');
#    equals(curly.sayHi(), 'hi: moe', 'bound function is still bound to original object');
#
#    curly = {name : 'curly'};
#    moe = {
#      name    : 'moe',
#      getName : function() { return 'name: ' + this.name; },
#      sayHi   : function() { return 'hi: ' + this.name; }
#    };
#    _.bindAll(moe);
#    curly.sayHi = moe.sayHi;
#    equals(curly.sayHi(), 'hi: moe', 'calling bindAll with no arguments binds all functions to the object');
#  });
#
#  test("functions: memoize", function() {
#    var fib = function(n) {
#      return n < 2 ? n : fib(n - 1) + fib(n - 2);
#    };
#    var fastFib = _.memoize(fib);
#    equals(fib(10), 55, 'a memoized version of fibonacci produces identical results');
#    equals(fastFib(10), 55, 'a memoized version of fibonacci produces identical results');
#
#    var o = function(str) {
#      return str;
#    };
#    var fastO = _.memoize(o);
#    equals(o('toString'), 'toString', 'checks hasOwnProperty');
#    equals(fastO('toString'), 'toString', 'checks hasOwnProperty');
#  });
#
#  asyncTest("functions: delay", 2, function() {
#    var delayed = false;
#    _.delay(function(){ delayed = true; }, 100);
#    setTimeout(function(){ ok(!delayed, "didn't delay the function quite yet"); }, 50);
#    setTimeout(function(){ ok(delayed, 'delayed the function'); start(); }, 150);
#  });
#
#  asyncTest("functions: defer", 1, function() {
#    var deferred = false;
#    _.defer(function(bool){ deferred = bool; }, true);
#    _.delay(function(){ ok(deferred, "deferred the function"); start(); }, 50);
#  });
#
#  asyncTest("functions: throttle", 1, function() {
#    var counter = 0;
#    var incr = function(){ counter++; };
#    var throttledIncr = _.throttle(incr, 100);
#    throttledIncr(); throttledIncr(); throttledIncr();
#    setTimeout(throttledIncr, 120);
#    setTimeout(throttledIncr, 140);
#    setTimeout(throttledIncr, 220);
#    setTimeout(throttledIncr, 240);
#    _.delay(function(){ ok(counter == 3, "incr was throttled"); start(); }, 400);
#  });
#
#  asyncTest("functions: debounce", 1, function() {
#    var counter = 0;
#    var incr = function(){ counter++; };
#    var debouncedIncr = _.debounce(incr, 50);
#    debouncedIncr(); debouncedIncr(); debouncedIncr();
#    setTimeout(debouncedIncr, 30);
#    setTimeout(debouncedIncr, 60);
#    setTimeout(debouncedIncr, 90);
#    setTimeout(debouncedIncr, 120);
#    setTimeout(debouncedIncr, 150);
#    _.delay(function(){ ok(counter == 1, "incr was debounced"); start(); }, 220);
#  });

describe 'once' => sub {
    it 'should be called once' => sub {
        my $num = 0;
        my $increment = _->once(sub { $num++; });
        $increment->();
        $increment->();
        is($num, 1);
    };
    it 'should be called once, with different function' => sub {
        my $num = 0;
        my $increment = _->once(sub { $num++; });
        $increment->();
        $increment->();
        is($num, 1);
    };
};

describe 'wrap' => sub {
    it 'wrapped the saluation function' => sub {
        my $greet = sub { my ($name) = @_; "hi: " . $name; };
        my $backwards = _->wrap(
            $greet => sub {
                my ($func, $name) = @_;
                return $func->($name) . ' '
                  . join('', reverse(split('', $name)));
            }
        );
        is($backwards->('moe'), 'hi: moe eom');
    };

    it 'inner' => sub {
        my $inner = sub { return "Hello "; };
        my $obj = {name => "Moe"};
        $obj->{hi} = _->wrap(
            $inner => sub {
                my ($fn, $name) = @_;
                return $fn->() . $name;
            }
        );
        is($obj->{hi}->($obj->{name}), "Hello Moe");
    };
};

describe 'compose' => sub {
    my $greet   = sub { my ($name)     = @_; return "hi: " . $name; };
    my $exclaim = sub { my ($sentence) = @_; return $sentence . '!'; };

    it 'can compose a function that takes another' => sub {
        my $composed = _->compose($exclaim, $greet);
        is($composed->('moe'), 'hi: moe!');
    };

    it 'otherway around' => sub {
        my $composed = _->compose($greet, $exclaim);
        is($composed->('moe'), 'hi: moe!');
    };
};

#  test("functions: after", function() {
#    var testAfter = function(afterAmount, timesCalled) {
#      var afterCalled = 0;
#      var after = _.after(afterAmount, function() {
#        afterCalled++;
#      });
#      while (timesCalled--) after();
#      return afterCalled;
#    };
#
#    equals(testAfter(5, 5), 1, "after(N) should fire after being called N times");
#    equals(testAfter(5, 4), 0, "after(N) should not fire unless called N times");
#  });
#
#});

runtests unless caller;
