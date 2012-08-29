package GVF::Roles;
use Moose::Role;


with ('GVF::Utils', 'GVF::DB::Loader', 'GVF::Parser', 'GVF::Export' );




1;

