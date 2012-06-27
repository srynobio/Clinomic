package GVF::DB::Connect::Result::Genes;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("Genes");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "gene_id",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "symbol",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "location",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "dbxref",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "refseq_id",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "hgnc_id",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "accession_num",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "omim",
  { data_type => "varchar", is_nullable => 1, size => 45 },

);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "Genetic_association",
  "Connect::Result::Genetic_association",
  { "foreign.Genes" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "Drug_bank",
  "Connect::Result::Drug_bank",
  { "foreign.Genes" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "Clinvar_gene",
  "Connect::Result::Clinvar_gene",
  { "foreign.Genes" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "Clinvar_hgmd",
  "Connect::Result::Clinvar_hgmd",
  { "foreign.Genes" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "Gene2gene_relationship",
  "Connect::Result::Gene2gene_relationship",
  { "foreign.Genes" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "gene2refseq",
  "Connect::Result::Gene2refseq",
  { "foreign.Genes" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "omim",
  "Connect::Result::Omim",
  { "foreign.Genes" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "GVFclin",
  "Connect::Result::GVFclin",
  { "foreign.Genes" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "rsid",
  "Connect::Result::Rsid",
  { "foreign.Genes" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "gwas",
  "Connect::Result::Gwas",
  { "foreign.Genes" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
