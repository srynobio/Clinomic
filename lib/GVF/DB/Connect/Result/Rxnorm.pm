package GVF::DB::Connect::Result::Rxnorm;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("Rxnorm");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "rxnorm_concept_id",
  { data_type => "integer", is_nullable => 1 },
  "rxnorm_atom_id",
  { data_type => "integer", is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "PharmGKB_drug_id",
  {
    accessor       => "pharm_gkb_drug_id",
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "pharm_gkb_drug",
  "Connect::Result::PharmGkbDrug",
  { id => "PharmGKB_drug_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
