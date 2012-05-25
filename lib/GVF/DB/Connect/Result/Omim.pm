package GVF::DB::Connect::Result::Omim;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("Omim");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "symbol",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "omim_number",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "PharmGKB_gene_id",
  {
    accessor       => "pharm_gkb_gene_id",
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "omim_informations",
  "Connect::Result::OmimInformation",
  { "foreign.Omim_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->belongs_to(
  "pharm_gkb_gene",
  "Connect::Result::PharmGkbGene",
  { id => "PharmGKB_gene_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

1;
