#!/usr/bin/perl
use strict;
use warnings;
use lib '/home/srynearson/GVF-Clin/lib';
use GVF::Clin;

use Data::Dumper;

my $user = {
    user   => 'srynearson',
    passwd => 'sh@wnPAss',
};

my $obj = GVF::Clin->new(
    data_directory => '/home/srynearson/GVF-Clin/data',
    build_database => 1,
    mysql_user     => $user,
);


# this allows you to add gvf file individually.
# requests will be populate, valadate, parse.
my $data_file = {
    file  => $ARGV[0],
    fasta => '/home/srynearson/GVF-Clin/data/genomes/Hsap_genome.fasta',
};

$obj->gvf_data( $data_file );




