package GVF::DB::Connect::Result::DrugInformation;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("Drug_information");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "drug_id",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "drug_info",
  { data_type => "varchar", is_nullable => 1, size => 75 },
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
