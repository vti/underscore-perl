use strict;
use warnings;

use Test::Spec;

use Underscore;

describe 'uniqueId' => sub {
    it 'can generate a globally-unique stream of ids' => sub {
        my $ids = [];
        my $i = 0;
        while ($i++ < 100) { push @$ids, _->uniqueId }
        is(@{_->uniq($ids)}, @$ids);
    };
};

describe 'result' => sub {
    it 'calls a subroutine reference' => sub {
        my $expected = 'yay';
        my $o = { code => sub { return $expected } };
        is(_->result($o, 'code'), $expected);
    };
    it 'returns the value of a non-subroutine key' => sub {
        my $expected = 'yay';
        my $o = { key => $expected };
        is(_->result($o, 'key'), $expected);
    };
};

describe 'times' => sub {
    it 'is 0 indexed' => sub {
        my $vals = [];
        _->times(3, sub { my ($i) = @_; push @$vals, $i; });
        is_deeply($vals, [0, 1, 2]);
    };

    it 'works as a wrapper' => sub {
        my $vals = [];
        _(3)->times(sub { my ($i) = @_; push @$vals, $i; });
        is_deeply($vals, [0, 1, 2]);
    };
};

describe 'mixin' => sub {
    before each => sub {
        _->mixin(
            myReverse => sub {
                my ($string) = @_;

                return join '', reverse split '', $string;
            }
        );
    };

    it 'mixed in a function to _' => sub {
        is(_->myReverse('panacea'), 'aecanap');
    };

    it 'mixed in a function to the OOP wrapper' => sub {
        is(_('champ')->myReverse, 'pmahc');
    };
};

describe 'template' => sub {
    it 'can do basic attribute interpolation' => sub {
        my $basicTemplate =
          _->template(q{<%= $thing %> is gettin' on my noives!});
        my $result = $basicTemplate->({thing => 'This'});
        is($result, "This is gettin' on my noives!");
    };

    it 'backslashes' => sub {
        my $backslashTemplate =
          _->template("<%= \$thing %> is \\ridanculous");
        is($backslashTemplate->({thing => 'This'}), "This is \\ridanculous");
    };

    it 'can run arbitrary javascript in templates' => sub {
        my $fancyTemplate = _->template(
            '<ul><% foreach my $key (sort keys %$people) { %><li><%= $people->{$key} %></li><% } %></ul>'
        );
        my $result = $fancyTemplate->(
            {people => {moe => "Moe", larry => "Larry", curly => "Curly"}});
        is($result, "<ul><li>Curly</li><li>Larry</li><li>Moe</li></ul>",);
    };

    it 'simple' => sub {
        my $noInterpolateTemplate = _->template(
            "<div><p>Just some text. Hey, I know this is silly but it aids consistency.</p></div>"
        );
        my $result = $noInterpolateTemplate->();
        is($result,
            "<div><p>Just some text. Hey, I know this is silly but it aids consistency.</p></div>"
        );
    };

    it 'quotes' => sub {
        my $quoteTemplate = _->template("It's its, not it's");
        is($quoteTemplate->({}), "It's its, not it's");
    };

    it 'quotes in statemets and body' => sub {
        my $quoteInStatementAndBody = _->template(
            q!<% if($foo eq 'bar'){ %>Statement quotes and 'quotes'.<% } %>!);
        is($quoteInStatementAndBody->({foo => "bar"}),
            "Statement quotes and 'quotes'.");
    };

    it 'newlines and tabs' => sub {
        my $withNewlinesAndTabs =
          _->template('This\n\t\tis: <%= $x %>.\n\tok.\nend.');
        is( $withNewlinesAndTabs->({x => 'that'}),
            'This\n\t\tis: that.\n\tok.\nend.'
        );
    };

    describe 'template with custom settings' => sub {
        my $u = _;
        $u->template_settings(
            evaluate    => qr/\{\{([\s\S]+?)\}\}/,
            interpolate => qr/\{\{=([\s\S]+?)\}\}/
        );

        it 'can run arbitrary javascript in templates' => sub {
            my $custom = $u->template(
                q!<ul>{{ foreach my $key (sort keys %$people) { }}<li>{{= $people->{$key} }}</li>{{ } }}</ul>!
            );
            my $result = $custom->(
                {   people =>
                      {moe => "Moe", larry => "Larry", curly => "Curly"}
                }
            );
            is($result, "<ul><li>Curly</li><li>Larry</li><li>Moe</li></ul>");
        };

        it 'quotes' => sub {
            my $customQuote = $u->template("It's its, not it's");
            is($customQuote->({}), "It's its, not it's");
        };

        it 'quote in statement and body' => sub {
            my $quoteInStatementAndBody = $u->template(
                q!{{ if($foo eq 'bar'){ }}Statement quotes and 'quotes'.{{ } }}!
            );
            is($quoteInStatementAndBody->({foo => "bar"}),
                "Statement quotes and 'quotes'.");
        };
    };

    describe 'template with custom settings and special chars' => sub {
        my $u = _;
        $u->template_settings(
            evaluate    => qr/<\?([\s\S]+?)\?>/,
            interpolate => qr/<\?=([\s\S]+?)\?>/
        );

        it 'can run arbitrary javascript in templates' => sub {
            my $customWithSpecialChars = $u->template(q!<ul><? foreach my $key (sort keys %$people) { ?><li><?= $people->{$key} ?></li><? } ?></ul>!);
            my $result = $customWithSpecialChars->({people => {moe  =>  "Moe", larry  =>  "Larry", curly  =>  "Curly"}});
            is($result, "<ul><li>Curly</li><li>Larry</li><li>Moe</li></ul>");
        };

        it 'quotes' => sub {
            my $customWithSpecialCharsQuote = $u->template("It's its, not it's");
            is($customWithSpecialCharsQuote->({}), "It's its, not it's");
        };

        it 'quote in statement and body' => sub {
            my $quoteInStatementAndBody = $u->template(q!<? if($foo eq 'bar'){ ?>Statement quotes and 'quotes'.<? } ?>!);
            is($quoteInStatementAndBody->({foo => "bar"}), "Statement quotes and 'quotes'.");
        };
    };

    describe 'mustache' => sub {
        my $u = _;
        $u->template_settings(interpolate => qr/\{\{(.+?)\}\}/);

        it 'can mimic mustache.js' => sub {
            my $mustache = $u->template(q/Hello {{$planet}}!/);
            is($mustache->({planet => "World"}), "Hello World!");
        };
    };
};

runtests unless caller;
