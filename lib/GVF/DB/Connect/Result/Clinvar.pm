package GVF::DB::Connect::Result::Clinvar;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");


__PACKAGE__->table("clinvar");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "umls_concept_id",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "snomed_id",
  { data_type => "varchar", is_nullable => 1, size => 25 },
   "genetic_association_id",
  {
    accessor       => "genetic_association_id",
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "genetic_association_id",
  "Connect::Result::Genetic_association",
  { id => "genetic_association_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
