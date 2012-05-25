package GVF::DB::Connect::Result::SnomedRelationship;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("SNOMED_Relationships");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "concept_id",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "SNOMED_id",
  {
    accessor       => "snomed_id",
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "snomed",
  "Connect::Result::Snomed",
  { id => "SNOMED_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
