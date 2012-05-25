package GVF::DB::Connect::Result::Snomed;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("SNOMED");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "concept_id",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "snomed_id",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "PharmGKB_disease_id",
  {
    accessor       => "pharm_gkb_disease_id",
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "pharm_gkb_disease",
  "Connect::Result::PharmGkbDisease",
  { id => "PharmGKB_disease_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->has_many(
  "snomed_relationships",
  "Connect::Result::SnomedRelationship",
  { "foreign.SNOMED_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
