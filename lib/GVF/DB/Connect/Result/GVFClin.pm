package GVF::DB::Connect::Result::GVFClin;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");


__PACKAGE__->table("GVFClin");


__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "seqid",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "source",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "type",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "start",
  { data_type => "integer", is_nullable => 0 },
  "end",
  { data_type => "integer", is_nullable => 0 },
  "score",
  { data_type => "varchar", is_nullable => 0 },
  "strand",
  { data_type => "varchar", is_nullable => 0, size => 10 },
  "phase",
  { data_type => "varchar", is_nullable => 0, size => 10 },
  "attributes_id",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "alias",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "dbxref",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "variant_seq",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "reference_seq",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "variant_reads",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "total_reads",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "zygosity",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "variant_freq",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "start_range",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "end_range",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "phased",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "genotype",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "individual",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "variant_codon",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "reference_codon",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "variant_aa",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "breakpoint_detail",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "sequence_context",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "clin_gene",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "clin_genomic_ref",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "clin_transcript",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "clin_allle_name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "clin_variant_id",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "clin_hgvs_dna",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "clin_variant_type",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "clin_hgvs_protein",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "clin_aa_change_type",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "clin_dna_region",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "clin_allelic_region",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "clin_variant_display_name",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "clin_disease_interpret",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "clin_drug_metab_interpert",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "clin_drug_eff_interpet",
  { data_type => "varchar", is_nullable => 1, size => 45 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "variant_effect",
  "GVF::DB::Connect::Result::Variant_effect",
  { "foreign.GVFClin_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


1;
