package GVF::DB::Connect::Result::GvfAttribute;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");


__PACKAGE__->table("GVF_attributes");


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
  "variant_effect",
  { data_type => "varchar", is_nullable => 0, size => 45 },
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
  "GVF_features_id",
  {
    accessor       => "gvf_features_id",
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "PharmGKB_gene_id",
  {
    accessor       => "pharm_gkb_gene_id",
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
);


__PACKAGE__->set_primary_key("id");


__PACKAGE__->belongs_to(
  "gvf_feature",
  "Connect::Result::GvfFeature",
  { id => "GVF_features_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->has_many(
  "hgmd_attributes",
  "Connect::Result::HgmdAttribute",
  { "foreign.GVF_attributes_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


__PACKAGE__->belongs_to(
  "pharm_gkb_gene",
  "Connect::Result::PharmGkbGene",
  { id => "PharmGKB_gene_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
