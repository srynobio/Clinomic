#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'GVF::Clin' ) || print "Bail out!\n";
}

diag( "Testing GVF::Clin $GVF::Clin::VERSION, Perl $], $^X" );
