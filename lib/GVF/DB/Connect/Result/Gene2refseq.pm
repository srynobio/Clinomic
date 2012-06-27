package GVF::DB::Connect::Result::Gene2refseq;
use strict;
use warnings;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components("InflateColumn::DateTime");


__PACKAGE__->table("Gene2refseq");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "rna_acc_version",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "rna_gi",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "start",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "end",
  { data_type => "varchar", is_nullable => 1, size => 45 },
   "Genes_id",
  {
    accessor       => "Gene_id",
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "Genes_id",
  "Connect::Result::Genes",
  { id => "Genes_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


1;

