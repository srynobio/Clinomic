package GVF::DB::Connect::Result::PharmGkbGene;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("PharmGKB_gene");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "gene_id",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "symbol",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "gene_info",
  { data_type => "varchar", is_nullable => 1, size => 75 },
  "omim",
  { data_type => "varchar", is_nullable => 1, size => 30 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "gvf_attributes",
  "Connect::Result::GvfAttribute",
  { "foreign.PharmGKB_gene_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "omims",
  "Connect::Result::Omim",
  { "foreign.PharmGKB_gene_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "pharm_gkb_diseases",
  "Connect::Result::PharmGkbDisease",
  { "foreign.PharmGKB_gene_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "pharm_gkb_drugs",
  "Connect::Result::PharmGkbDrug",
  { "foreign.PharmGKB_gene_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
