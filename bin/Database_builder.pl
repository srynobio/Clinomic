#!/usr/bin/perl
use strict;
use warnings;
use lib '/home/srynearson/GVF-Clin/lib';
use GVF::Clin;
use Getopt::Long;

use Data::Dumper;

our $VERSION  = '0.01';

my $usage = "\n
Database_builder $VERSION

DESCRIPTION:
USAGE:
OPTIONS(required):
\n";


my ( $user, $pass, $help, $threads, $db_lib );
 
my $result = GetOptions(
    'u=s'      => \$user,
    'p=s'      => \$pass,
    't=s'      => \$threads,
    'db_lib=s' => \$db_lib,
    'help'     => \$help,
) || die $usage;

# print message
if ( $help ){ die $usage }

# Build the database
if ( $user && $pass && $db_lib ){

    # db info.
    my $person = {
        user   => $user,
        passwd => $pass,
    };

    # Build database
    #system("mysql -u $user -p < ../data/mysql/GVFClin.sql");
    
    # Building db object.
    my $db = GVF::Clin->new(
        data_directory => $db_lib,
        build_database => 1,
        mysql_user     => $person,
    );   
}
elsif ( $user && $pass ) {
    
    # db info.
    my $person = {
        user   => $user,
        passwd => $pass,
    };

    # Build database
    #system("mysql -u $user -p < ../data/mysql/GVFClin.sql");
    
    # Building db object.
    my $db = GVF::Clin->new(
        #data_directory => $db_lib,
        build_database => 1,
        mysql_user     => $person,
    );
}
else {
    print "
        Unable to create or build database,
        please check files and try again.

        For help use: ./Database_builder.pl --help
    \n";
}




