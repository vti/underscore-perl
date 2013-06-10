use strict;
use warnings;

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

    it
      'the function was partially applied in advance and can accept multiple arguments'
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

describe 'once' => sub {
    it 'must be called once' => sub {
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

describe 'after' => sub {
    my $invoke_after = sub {
        my ($after_amount, $times_called) = @_;
        my $after_called = 0;
        my $after = _->after($after_amount, sub { ++$after_called; });
        while ($times_called--) { $after->(); }
        return $after_called;
    };

    it 'does call the subroutine after the threshold is reached' => sub {
        is($invoke_after->(5, 5), 1);
    };

    it 'does not call the subroutine if the threshold is not reached' => sub {
        is($invoke_after->(5, 4), 0);
    };

    it 'does continue to call the subroutine after the threshold is reached' => sub {
        is($invoke_after->(5, 10), 6);
    };
};

runtests unless caller;
