#!/usr/bin/perl
use strict;
use warnings;
use lib '/home/srynearson/GVF-Clin/lib';
use GVF::Parser;

use Data::Dumper;

my $user = {
    user   => 'srynearson',
    passwd => 'something',
};


my $obj = GVF::Parser->new(
    data_directory => '/home/srynearson/GVF-Clin/data',
    mysql_user           => $user,
);



# call to build db.
my $return = $obj->populate_drug_info;
#print Dumper($return);

#$obj->pharmGKB_disease;



