package GVF::DB::Connect::Result::Omim;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("Omim");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "cytogenetic_location",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "symbol",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "omim_disease",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "status_code",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "omim_number",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "Genes_id",
  {
    accessor       => "Genes_id",
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_one(
  "Genes_id",
  "Connect::Result::Genes",
  { "foreign.Genes_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
