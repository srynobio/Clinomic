#!/usr/bin/perl
use strict;
use warnings;
use lib '/home/srynearson/GVF-Clin/lib';
use GVF::Clin;
use GVF::Build;
use Getopt::Long;

use Data::Dumper;

#our ($VERSION) = '$Revision: 1 $' =~ m{ \$Revision: \s+ (\S+) }x;

my $usage = "\n
DESCRIPTION:
USAGE:
OPTIONS(required):
\n";


my ( $mysql, $pass, $gvf, $fasta, $help, $db_files, $valadate, $ref );
 
my $result = GetOptions(
    'mysql_user=s' => \$mysql,
    'mysql_pass=s' => \$pass,
    'db_files=s'   => \$db_files,
    'gvf_file=s'   => \$gvf,
    'fa=s'         => \$fasta,
    'ref_match=s'  => \$ref,

    #'valadate'   => \$valadate,
    'help'       => \$help,
) || die $usage;


# print message
if ( $help ){ die $usage }



if ( $mysql && $pass && $db_files ) {
    
    # db info.
    my $user = {
        #user   => 'srynearson',
        #passwd => 'sh@wnPAss',
        user   => $mysql,
        passwd => $pass,
    };
    
    # Building db object.
    my $db = GVF::Clin->new(
        data_directory => $db_files,
        #data_directory => '/home/srynearson/GVF-Clin/data',
        build_database => 1,
        mysql_user     => $user,
    );
}




if ( $gvf && $fasta ) {

    # This wil check if required Variant_effect information is added.
    # and check if references match current build.

    # Make new object for gvf file.
    my $file = GVF::Build->new(
        fasta_file => $fasta,
        gvf_file   => $gvf,
        ref_match  => $ref,
    );
    $file->gvf_valadate;
}




