package GVF::DB::Connect::Result::DbVar;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");


__PACKAGE__->table("dbVar");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "seqid",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "type",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "start",
  { data_type => "integer", is_nullable => 0 },
  "end",
  { data_type => "integer", is_nullable => 0 },
  "attribute_id",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "alias",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "dbxref",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "start_range",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "end_range",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "GVF_features_id",
  {
    accessor       => "gvf_features_id",
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

1;
