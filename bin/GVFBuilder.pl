#!/usr/bin/perl
use strict;
use warnings;
use lib '/home/srynearson/GVF-Clin/lib';
use GVF::Build;
use Getopt::Long;

our ($VERSION) = '1';

my $usage = "\n
DESCRIPTION:
USAGE:
OPTIONS(required):
\n";


my ( $gvf, $fasta, $help, $valadate, $per, $user, $pass, $tabix );
 
my $result = GetOptions(
    'u=s'       => \$user,
    'p=s'       => \$pass,
    'gvf=s'     => \$gvf,
    'fa=s'      => \$fasta,
    'percent=s' => \$per,
    'tbx=s'     => \$tabix,
    'help'      => \$help,
    
) || die $usage;


# print message
if ( $help ){ die $usage }

if ( $gvf && $fasta ) {

    # This wil check if required Variant_effect information is added.
    # and check if references match current build.

    # db info.
    my $person = {
        user   => $user,
        passwd => $pass,
    };

    my $file;
    if ( $per ){
        # Make new object for gvf file.
        $file = GVF::Build->new(
            fasta_file    => $fasta,
            gvf_file      => $gvf,
            mysql_user    => $person,
        );
        $file->set_ref_match($per);
    }
    else {
        # Make new object for gvf file.
        $file = GVF::Build->new(
            fasta_file => $fasta,
            gvf_file   => $gvf,
            mysql_user => $person,
        );
    }

    # valadate the file for gene information and reference match
    my ($valid, $hasGene, $match) = $file->gvf_valadate;

    # if fasta match is not met, the file will not be added, and the program will die.
    if (  ! $$valid  ) {
        die "\n Your GVF file does not match the reference at ", $file->get_ref_match,
            "% it will not be added to the database\n\n Match percent ", $$match, "\n\n";
    }
    elsif ( $$valid && $$hasGene ){
        print "
               File matches at ", $file->get_ref_match, "% and contains gene annotations.
               File will be added to database.
        \n\n";
        # add file to db
        $file->populate_gvf_data;
    }
    else {
        if ( $tabix ){
            print "\nLooking for gene matches using NCBI current feature file\nMatch percent ", $$match, "\n\n";
            $file->tabix_build($tabix);
        }
        else {
            print "File has no gene information via Varient_effect, please include tabix file\n\n$usage";
        }
    }
}

else {
    print "
        Unable to create or build database,
        please check files and try again.
        $usage \n";
}



