package Clinomic::DB::Connect::Result::Hgnc_gene;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("Hgnc_gene");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "symbol",
  { data_type => "varchar", is_nullable => 0, size => 25 },
  "chromosome",
  { data_type => "varchar", is_nullable => 1, size => 25 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "drug_bank",
  "Clinomic::DB::Connect::Result::Drug_bank",
  { "foreign.hgnc_gene_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "clinvar",
  "Clinomic::DB::Connect::Result::Clinvar",
  { "foreign.hgnc_gene_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "genetic_association",
  "Clinomic::DB::Connect::Result::Genetic_association",
  { "foreign.hgnc_gene_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "refseq",
  "Clinomic::DB::Connect::Result::Refseq",
  { "foreign.hgnc_gene_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0, },
);


1;
