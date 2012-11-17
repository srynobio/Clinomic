package Clinomic::Base;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

with 'Clinomic::Roles';
with 'MooseX::Getopt';

#-----------------------------------------------------------------------------
#------------------------------- Attributes ----------------------------------
#-----------------------------------------------------------------------------
    
has 'data_directory' => (
    traits    =>['NoGetopt'],
    is       => 'rw',
    isa      => 'Str',
    default  => '../data/',
    writer   => 'set_directory',
    reader   => 'get_directory',
);

has 'build_database' => (
    traits    =>['NoGetopt'],
    is         => 'rw',
    isa        => 'Int',
    trigger => \&_build_database,
);


no Moose;
1;

