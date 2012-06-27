package GVF::DB::Connect::Result::Clinvar_gene;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");


__PACKAGE__->table("Clinvar_gene");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "symbol",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "location",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "umls_concept_id",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "condition_name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "source",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "source_id",
  { data_type => "varchar", is_nullable => 1, size => 45 },
   "omim_id",
  { data_type => "varchar", is_nullable => 1, size => 45 },  
   "Genes_id",
  {
    accessor       => "Gene_id",
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "Genes_id",
  "Connect::Result::Genes",
  { id => "Genes_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


1;

