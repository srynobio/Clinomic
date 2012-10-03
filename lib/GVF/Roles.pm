package GVF::Roles;
use Moose::Role;
use namespace::autoclean;

with ('GVF::Utils', 'GVF::DB::Loader', 'GVF::Parser', 'GVF::Export' );

no Moose;
1;