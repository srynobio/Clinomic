package GVF::DB::Connect::Result::Gwas;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");


__PACKAGE__->table("Gwas");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "rsid",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "gene_region",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "journal",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "pubmed_id",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "allele_risk",
  { data_type => "varchar", is_nullable => 1, size => 45 },
   "Rsid_id",
  {
    accessor       => "Rsid_id",
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "Rsid_id",
  "Connect::Result::Rsid",
  { id => "Rsid_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


1;

