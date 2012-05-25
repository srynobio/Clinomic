package GVF::DB::Connect::Result::GvfFeature;

use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");


__PACKAGE__->table("GVF_features");


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
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "strand",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "phase",
  { data_type => "varchar", is_nullable => 0, size => 45 },
);


__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "db_snps",
  "Connect::Result::DbSnp",
  { "foreign.GVF_features_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "db_vars",
  "Connect::Result::DbVar",
  { "foreign.GVF_features_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "gvf_attributes",
  "Connect::Result::GvfAttribute",
  { "foreign.GVF_features_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
