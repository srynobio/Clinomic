package GVF::DB::Connect::Result::OmimInformation;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");


__PACKAGE__->table("Omim_information");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "cytogenetic_location",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "omim_disease",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "status_code",
  { data_type => "varchar", is_nullable => 1, size => 45 },
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
  "pharm_gkb_gene",
  "Connect::Result::PharmGkbGene",
  { id => "PharmGKB_gene_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


1;
