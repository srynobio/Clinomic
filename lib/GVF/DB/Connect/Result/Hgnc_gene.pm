package GVF::DB::Connect::Result::Hgnc_gene;
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
  "name",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "chromosome",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "omim_id",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "transcript_refseq",
  { data_type => "varchar", is_nullable => 1, size => 25 }
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "drug_bank",
  "Connect::Result::Drug_bank",
  { "foreign.hgnc_gene_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "clinvar_hgmd",
  "Connect::Result::Clinvar_hgmd",
  { "foreign.hgnc_gene_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "genetic_association",
  "Connect::Result::Genetic_association",
  { "foreign.hgnc_gene_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "refseq",
  "Connect::Result::Refseq",
  { "foreign.hgnc_gene_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);









1;
