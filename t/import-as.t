use Test::Spec;
use Underscore -as => 'X';

describe 'import' => sub {
  it 'should import as X' => sub {
    is(X->first( [1, 2, 3]), 1 );
  } ;
} ;

describe 'version' => sub {
  it 'is latest' => sub {
    is( X->VERSION, '0.02' ) ;
  }
} ;

runtests unless caller;
