package GVF::DB::Connect::Result::Gvf_clinFeatures;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");


__PACKAGE__->table("tmp.db.Gvf_clinFeatures");


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
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "gvf_clinAttributes",
  "Connect::Result::Gvf_clinAttributes",
  { "foreign.gvf_clinFeature_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


1;
