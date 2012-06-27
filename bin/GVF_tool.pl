#!/usr/bin/perl
use strict;
use warnings;
use lib '/home/srynearson/GVF-Clin/lib';
use GVF::Build;
use Getopt::Long;

use Data::Dumper;

our ($VERSION) = '1';

my $usage = "\n
DESCRIPTION:
USAGE:
OPTIONS(required):
\n";


my ( $gvf, $fasta, $help, $valadate, $ref );
 
my $result = GetOptions(
    'gvf_file=s'   => \$gvf,
    'fa=s'         => \$fasta,
    'ref_match=s'  => \$ref,

    #'valadate'   => \$valadate,
    'help'       => \$help,
) || die $usage;


# print message
if ( $help ){ die $usage }

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
else {
    print "
        Unable to create or build database,
        please check files and try again.

        For help use: ./Database_builder.pl --help
    \n";
}


# add later to venn script
# for R
#venn.diagram(x=list("PharmGKB"= test1, "SNOMED"= test2), filename="testone", height = 4000, width = 5000, resolution = 800, main="SNOMED vs PharmGKB disease terms", scaled = FALSE)

