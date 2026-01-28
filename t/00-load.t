#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Test::Changes::Strict' ) || print "Bail out!\n";
}

diag( "Testing Test::Changes::Strict $Test::Changes::Strict::VERSION, Perl $], $^X" );
