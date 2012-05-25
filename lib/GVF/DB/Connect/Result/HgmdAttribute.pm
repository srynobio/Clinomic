package GVF::DB::Connect::Result::HgmdAttribute;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");


__PACKAGE__->table("HGMD_attributes");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "hgmd_class",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "hgmd_disease",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "hgmd_type",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "GVF_attributes_id",
  {
    accessor       => "gvf_attributes_id",
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "gvf_attribute",
  "Connect::Result::GvfAttribute",
  { id => "GVF_attributes_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


1;
