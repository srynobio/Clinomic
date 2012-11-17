package Clinomic::Roles;
use Moose::Role;
use namespace::autoclean;

with ('Clinomic::Utils', 'Clinomic::DB::Loader', 'Clinomic::Parser', 'Clinomic::Export' );

no Moose;
1;
