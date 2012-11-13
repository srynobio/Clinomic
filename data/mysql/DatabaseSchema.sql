-- Creator:       MySQL Workbench 5.2.37/ExportSQLite plugin 2009.12.02
-- Author:        Shawn Rynearson
-- Caption:       New Model
-- Project:       Name of the project
-- Changed:       2012-10-12 15:41
-- Created:       2012-07-30 13:55
PRAGMA foreign_keys = OFF;

-- Schema: GeneDatabase
BEGIN;
CREATE TABLE "hgnc_gene"(
  "id" INTEGER PRIMARY KEY NOT NULL,
  "symbol" VARCHAR(25) NOT NULL,
  "chromosome" VARCHAR(25) DEFAULT NULL
);
CREATE TABLE "genetic_association"(
  "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "symbol" VARCHAR(20),
  "mesh_disease" VARCHAR(45) NOT NULL,
  "disease_class" VARCHAR(20) DEFAULT NULL,
  "pubmed_id" INTEGER DEFAULT NULL,
  "hgnc_gene_id" INTEGER NOT NULL,
  CONSTRAINT "fk_genetic_association_hgnc_gene1"
    FOREIGN KEY("hgnc_gene_id")
    REFERENCES "hgnc_gene"("id")
);
CREATE INDEX "genetic_association.fk_genetic_association_hgnc_gene1" ON "genetic_association"("hgnc_gene_id");
CREATE TABLE "drug_bank"(
  "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "generic_name" VARCHAR(45) NOT NULL,
  "hgnc_gene_id" INTEGER NOT NULL,
  CONSTRAINT "fk_drug_bank_hgnc_gene1"
    FOREIGN KEY("hgnc_gene_id")
    REFERENCES "hgnc_gene"("id")
);
CREATE INDEX "drug_bank.fk_drug_bank_hgnc_gene1" ON "drug_bank"("hgnc_gene_id");
CREATE TABLE "clinvar"(
  "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "umls_concept_id" VARCHAR(25),
  "snomed_id" VARCHAR(25),
  "disease" VARCHAR(45),
  "hgnc_gene_id" INTEGER NOT NULL,
  CONSTRAINT "fk_clinvar_hgnc_gene1"
    FOREIGN KEY("hgnc_gene_id")
    REFERENCES "hgnc_gene"("id")
);
CREATE INDEX "clinvar.fk_clinvar_hgnc_gene1" ON "clinvar"("hgnc_gene_id");
CREATE TABLE "refseq"(
  "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "genomic_refseq" VARCHAR(25),
  "protein_refseq" VARCHAR(25),
  "transcript_refseq" VARCHAR(25),
  "hgnc_gene_id" INTEGER NOT NULL,
  CONSTRAINT "fk_refseq_hgnc_gene1"
    FOREIGN KEY("hgnc_gene_id")
    REFERENCES "hgnc_gene"("id")
);
CREATE INDEX "refseq.fk_refseq_hgnc_gene1" ON "refseq"("hgnc_gene_id");
CREATE TABLE "clinvar_clin_sig"(
  "id" INTEGER PRIMARY KEY NOT NULL,
  "ref_seq" VARCHAR(20) NOT NULL,
  "var_seq" VARCHAR(20) NOT NULL,
  "rsid" VARCHAR(30),
  "location" INTEGER NOT NULL,
  "clnsig" VARCHAR(45),
  "clncui" VARCHAR(45),
  "clnhgvs" VARCHAR(45),
  "hgnc_gene_id" INTEGER NOT NULL,
  CONSTRAINT "fk_clinvar_clin_sig_hgnc_gene1"
    FOREIGN KEY("hgnc_gene_id")
    REFERENCES "hgnc_gene"("id")
);
CREATE INDEX "clinvar_clin_sig.fk_clinvar_clin_sig_hgnc_gene1" ON "clinvar_clin_sig"("hgnc_gene_id");
COMMIT;
