package GVF::DB::Connect::Result::Gvf_clinAttributes;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");


__PACKAGE__->table("tmp.db.Gvf_clinAttributes");


__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
 
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
  "gvf_clinFeatures_id",
  {
    accessor       => "gvf_clinFeatures_id",
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "gvf_clinFeatures_id",
  "Connect::Result::Gvf_clinFeatures",
  { id => "gvf_clinFeature_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->has_many(
  "variant_effect",
  "Connect::Result::Variant_effect",
  { "foreign.gvf_clinAttributes_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


1;
