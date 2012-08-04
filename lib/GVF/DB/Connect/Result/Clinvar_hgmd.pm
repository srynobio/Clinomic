package GVF::DB::Connect::Result::Clinvar_hgmd;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");


__PACKAGE__->table("Clinvar_hgmd");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "position",
  { data_type => "integer", is_nullable => 1 },
  "so_feature",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "rsid",
  { data_type => "varchar", is_nullable => 1, size => 30 },
   "hgnc_gene_id",
  {
    accessor       => "hgnc_gene_id",
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "hgnc_gene",
  "Connect::Result::Hgnc_gene",
  { id => "hgnc_gene_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
