package GVF::DB::Connect::Result::PharmGkbDrug;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("PharmGKB_drug");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "drug_id",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "drug_name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "drug_gene_evidence",
  { data_type => "varchar", is_nullable => 1, size => 75 },
  "rxnorm_confirm",
  { data_type => "varchar", is_nullable => 1, size => 4 },
  "PharmGKB_gene_id",
  {
    accessor       => "pharm_gkb_gene_id",
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "drug_informations",
  "Connect::Result::DrugInformation",
  { "foreign.PharmGKB_drug_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->belongs_to(
  "pharm_gkb_gene",
  "Connect::Result::PharmGkbGene",
  { id => "PharmGKB_gene_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->has_many(
  "rxnorms",
  "Connect::Result::Rxnorm",
  { "foreign.PharmGKB_drug_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
