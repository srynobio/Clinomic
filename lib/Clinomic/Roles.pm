package Clinomic::Roles;
use Moose::Role;
use namespace::autoclean;

with ('Clinomic::Utils', 'Clinomic::Parser', 'Clinomic::Export', 'Clinomic::Annotator' );

no Moose;
1;
