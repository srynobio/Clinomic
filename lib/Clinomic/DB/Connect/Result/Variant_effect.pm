package Clinomic::DB::Connect::Result::Variant_effect;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");


__PACKAGE__->table("Variant_effect");


__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "so_effect",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "index",
  { data_type => "varchar", is_nullable => 0, size => 10 },
  "affected_feature",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "feature_id",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "hgnc_gene_id",
  { data_type => "integer", is_nullable => 0 },
  "GVFClin_id",
  {
    accessor       => "GVFClin_id",
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
  },  
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "GVFClin_id",
  "Clinomic::DB::Connect::Result::GVFClin",
  { id => "GVFClin_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


1;
