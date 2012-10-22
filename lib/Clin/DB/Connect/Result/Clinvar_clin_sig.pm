package Clin::DB::Connect::Result::Clinvar_clin_sig;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");


__PACKAGE__->table("Clinvar_clin_sig");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "ref_seq",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "var_seq",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "rsid",
  { data_type => "varchar", is_nullable => 1, size => 30 },  
  "location",
  { data_type => "integer", is_nullable => 0 },
  "clnsig",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "clncui",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "clnhgvs",
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
  "hgnc_gene",
  "Clin::DB::Connect::Result::Hgnc_gene",
  { id => "hgnc_gene_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;

