package Clin::Roles;
use Moose::Role;
use namespace::autoclean;

with ('Clin::Utils', 'Clin::DB::Loader', 'Clin::Parser', 'Clin::Export' );

no Moose;
1;