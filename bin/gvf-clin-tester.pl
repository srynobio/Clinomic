#!/usr/bin/perl
use strict;
use warnings;
use lib '/home/srynearson/GVF-Clin/lib';
use GVF::Parser;

use Data::Dumper;

my $user = {
    user   => 'srynearson',
    passwd => 'sh@wnPAss',
};


my $obj = GVF::Parser->new(
    data_directory => '/home/srynearson/GVF-Clin/data',
    mysql_user     => $user,
    build_database => 1,
);


