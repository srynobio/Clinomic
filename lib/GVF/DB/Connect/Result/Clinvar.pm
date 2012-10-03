package GVF::DB::Connect::Result::Clinvar;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");


__PACKAGE__->table("Clinvar");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "umls_concept_id",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "snomed_id",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "disease",
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
  "GVF::DB::Connect::Result::Hgnc_gene",
  { id => "hgnc_gene_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
