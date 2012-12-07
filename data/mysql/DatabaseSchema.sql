-- Creator:       MySQL Workbench 5.2.37/ExportSQLite plugin 2009.12.02
-- Author:        Shawn Rynearson
-- Caption:       New Model
-- Project:       Name of the project
-- Changed:       2012-12-03 09:27
-- Created:       2012-07-30 13:55
PRAGMA foreign_keys = OFF;

-- Schema: GeneDatabase
BEGIN;
CREATE TABLE "hgnc_gene"(
  "id" INTEGER PRIMARY KEY NOT NULL,
  "symbol" VARCHAR(25) NOT NULL,
  "chromosome" VARCHAR(25) DEFAULT NULL
);
CREATE TABLE "drug_bank"(
  "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "generic_name" VARCHAR(45) NOT NULL,
  "hgnc_gene_id" INTEGER NOT NULL,
  CONSTRAINT "fk_drug_bank_hgnc_gene1"
    FOREIGN KEY("hgnc_gene_id")
    REFERENCES "hgnc_gene"("id")
);
CREATE INDEX "drug_bank.fk_drug_bank_hgnc_gene1" ON "drug_bank"("hgnc_gene_id");
CREATE TABLE "refseq"(
  "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "genomic_refseq" VARCHAR(25),
  "protein_refseq" VARCHAR(25),
  "transcript_refseq" VARCHAR(25),
  "genomic_start" INTEGER,
  "genomic_end" INTEGER,
  "hgnc_gene_id" INTEGER NOT NULL,
  CONSTRAINT "fk_refseq_hgnc_gene1"
    FOREIGN KEY("hgnc_gene_id")
    REFERENCES "hgnc_gene"("id")
);
CREATE INDEX "refseq.fk_refseq_hgnc_gene1" ON "refseq"("hgnc_gene_id");
COMMIT;
