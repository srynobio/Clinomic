package GVF::DB::Connect::Result::Drug_bank;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");


__PACKAGE__->table("Drug_bank");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "generic_name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
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
  "hgnc_gene_id",
  "GVF::DB::Connect::Result::Hgnc_gene",
  { id => "hgnc_gene_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
