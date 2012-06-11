#!/usr/bin/perl
use strict;
use warnings;
use lib '/home/srynearson/GVF-Clin/lib';
use GVF::Clin;
use Getopt::Long;

use Data::Dumper;

our ($VERSION) = '0.01';

my $usage = "\n
DESCRIPTION:
USAGE:
OPTIONS(required):
\n";


my ( $mysql, $pass, $help, $db_files );
 
my $result = GetOptions(
    'mysql_user=s' => \$mysql,
    'mysql_pass=s' => \$pass,
    'db_files=s'   => \$db_files,
    'help'       => \$help,
) || die $usage;

# print message
if ( $help ){ die $usage }

# Build the database
if ( $mysql && $pass && $db_files ) {
    
    # db info.
    my $user = {
        user   => $mysql,
        passwd => $pass,
    };

    # try and add db system call here.
    
    # Building db object.
    my $db = GVF::Clin->new(
        data_directory => $db_files,
        build_database => 1,
        mysql_user     => $user,
    );
}
else {
    print "
        Unable to create or build database,
        please check files and try again.

        For help use: ./Database_builder.pl --help
    \n";
}




