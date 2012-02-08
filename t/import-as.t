use strict;
use warnings;

use Test::Spec;

use Underscore -as => 'X';

describe 'import' => sub {
    it 'should import as X' => sub {
        is(X->first([1, 2, 3]), 1);
    };
};

runtests unless caller;
