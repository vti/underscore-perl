#!/usr/bin/env perl

use strict;
use warnings;

use inc::Module::Install;

name 'Underscore';

version_from 'lib/Underscore.pm';
author 'Viacheslav Tykhanovskyi <vti@cpan.org>';
abstract 'Underscore.js port to Perl';
license 'artistic_2';
perl_version '5.010001';

requires 'List::Util';
requires 'List::MoreUtils';
requires 'B';

build_requires 'Test::Spec';
build_requires 'Try::Tiny';

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';

no_index directory => 't';

resources
  bugtracker => 'http://github.com/vti/underscore-perl/issues',
  repository => 'http://github.com/vti/underscore-perl/',
  license    => 'http://dev.perl.org/licenses/';

auto_install;

WriteAll;
