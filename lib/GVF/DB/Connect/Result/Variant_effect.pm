package GVF::DB::Connect::Result::Variant_effect;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");


__PACKAGE__->table("tmp.db.Variant_effect");


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
  "gvf_clinAttributes_id",
  {
    accessor       => "gvf_clinAttributes_id",
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
  },  
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "gvf_clinAttributes_id",
  "Connect::Result::Gvf_clinAttributes",
  { id => "gvf_clinAttributes_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


1;
