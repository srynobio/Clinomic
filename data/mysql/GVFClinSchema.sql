-- Creator:       MySQL Workbench 5.2.37/ExportSQLite plugin 2009.12.02
-- Author:        Shawn Rynearson
-- Caption:       New Model
-- Project:       Name of the project
-- Changed:       2012-08-10 09:47
-- Created:       2012-07-30 15:04
PRAGMA foreign_keys = ON;

-- Schema: GVFClin
BEGIN;
CREATE TABLE "GVFClin"(
  "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "seqid" VARCHAR(45) NOT NULL,
  "source" VARCHAR(45) NOT NULL,
  "type" VARCHAR(45) NOT NULL,
  "start" INTEGER NOT NULL,
  "end" INTEGER NOT NULL,
  "score" INTEGER,
  "strand" VARCHAR(10),
  "phase" VARCHAR(10),
  "attributes_id" VARCHAR(45) NOT NULL,
  "alias" VARCHAR(45) DEFAULT NULL,
  "dbxref" VARCHAR(45) DEFAULT NULL,
  "variant_seq" VARCHAR(45) DEFAULT NULL,
  "reference_seq" VARCHAR(45) DEFAULT NULL,
  "variant_reads" VARCHAR(45) DEFAULT NULL,
  "total_reads" VARCHAR(45) DEFAULT NULL,
  "zygosity" VARCHAR(45) DEFAULT NULL,
  "variant_freq" VARCHAR(45) DEFAULT NULL,
  "start_range" VARCHAR(45) DEFAULT NULL,
  "end_range" VARCHAR(45) DEFAULT NULL,
  "phased" VARCHAR(45) DEFAULT NULL,
  "genotype" VARCHAR(45) DEFAULT NULL,
  "individual" VARCHAR(45) DEFAULT NULL,
  "variant_codon" VARCHAR(45) DEFAULT NULL,
  "reference_codon" VARCHAR(45) DEFAULT NULL,
  "variant_aa" VARCHAR(45) DEFAULT NULL,
  "breakpoint_detail" VARCHAR(45) DEFAULT NULL,
  "sequence_context" VARCHAR(75) DEFAULT NULL,
  "clin_gene" VARCHAR(45) DEFAULT NULL,
  "clin_genomic_reference" VARCHAR(45) DEFAULT NULL,
  "clin_transcript" VARCHAR(45) DEFAULT NULL,
  "clin_allele_name" VARCHAR(45) DEFAULT NULL,
  "clin_variant_id" VARCHAR(45) DEFAULT NULL,
  "clin_hgvs_dna" VARCHAR(45) DEFAULT NULL,
  "clin_variant_type" VARCHAR(45) DEFAULT NULL,
  "clin_hgvs_protein" VARCHAR(45) DEFAULT NULL,
  "clin_aa_change_type" VARCHAR(45) DEFAULT NULL,
  "clin_dna_region" VARCHAR(45) DEFAULT NULL,
  "clin_allelic_state" VARCHAR(45) DEFAULT NULL,
  "clin_variant_display_name" VARCHAR(45) DEFAULT NULL,
  "clin_disease_interpret" VARCHAR(45) DEFAULT NULL,
  "clin_drug_metabolism_interpret" VARCHAR(45) DEFAULT NULL,
  "clin_drug_efficacy_interpret" VARCHAR(45) DEFAULT NULL
);
CREATE TABLE "variant_effect"(
  "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "so_effect" VARCHAR(45) DEFAULT NULL,
  "index" VARCHAR(10) DEFAULT NULL,
  "affected_feature" VARCHAR(45) NOT NULL,
  "feature_id" VARCHAR(45) DEFAULT NULL,
  "hgnc_gene_id" INTEGER NOT NULL,
  "GVFClin_id" INTEGER NOT NULL,
  CONSTRAINT "fk_variant_effect_GVFClin"
    FOREIGN KEY("GVFClin_id")
    REFERENCES "GVFClin"("id")
);
CREATE INDEX "variant_effect.fk_variant_effect_GVFClin" ON "variant_effect"("GVFClin_id");
COMMIT;
