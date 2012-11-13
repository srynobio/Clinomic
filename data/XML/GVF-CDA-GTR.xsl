<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:output method="xml" indent="yes"/>   
    <xsl:template match="/">
        <ClinicalDocument xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="urn:hl7-org:v3" xsi:schemaLocation="urn:hl7-org:v3 GVF-CDA-GTR.xsd">
            <templateId root="2.16.840.1.113883.10.20.20"/>
            <code code="51969-4" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Genetic analysis summary report"/>
            <title>GVFclin-CDA-GTR</title>
            <component>
                <section>
                    <templateId root="2.16.840.1.113883.10.20.20.1.9"/>
                    <code code="35510-7" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="General information section"/>
                    <title>Background pragma section</title>
                    <component>
                        <section>
                            <templateId root="2.16.840.1.113883.10.20.20.1.9.1"/>
                            <code code="35511-5" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="Background information"/>
                             <title>Pragmas describing background information</title>
                            <simple_pragma>
                                <gvf-version>
                                    <xsl:value-of select="/GVFClin/simple_pragmas/gvf_version"/>
                                </gvf-version>
                                <reference-fasta>
                                    <xsl:value-of select="/GVFClin/simple_pragmas/reference_fasta"/>
                                </reference-fasta>
                                <feature-gff3>
                                    <xsl:value-of select="/GVFClin/simple_pragmas/feature_gff3"/>
                                </feature-gff3>
                                <file-version>
                                    <xsl:value-of select="/GVFClin/simple_pragmas/file_version"/>
                                </file-version>
                                <file-date>
                                    <xsl:value-of select="/GVFClin/simple_pragmas/file_date"/>
                                </file-date>
                                <individual-id>
                                    <xsl:value-of select="/GVFClin/simple_pragmas/individual_id"/>
                                </individual-id>
                                <population>
                                    <xsl:value-of select="/GVFClin/simple_pragmas/population"/>
                                </population>
                                <sex>
                                    <xsl:value-of select="/GVFClin/simple_pragmas/sex"/>
                                </sex>
                                <technology-platform-class>
                                    <xsl:value-of select="/GVFClin/simple_pragmas/technology_platform_class"/>
                                </technology-platform-class>
                                <technology-platform-name>
                                    <xsl:value-of select="/GVFClin/simple_pragmas/technology_platform_name"/>
                                </technology-platform-name>
                                <technology-platform-version>
                                    <xsl:value-of select="/GVFClin/simple_pragmas/technology_platform_version"/>
                                </technology-platform-version>
                                <technology-platform-machine-id>
                                    <xsl:value-of select="/GVFClin/simple_pragmas/technology_platform_machine_id"/>
                                </technology-platform-machine-id>
                                <technology-platform-read-length>
                                    <xsl:value-of select="/GVFClin/simple_pragmas/technology_platform_read_length"/>
                                </technology-platform-read-length>
                                <technology-platform-read-type>
                                    <xsl:value-of select="/GVFClin/simple_pragmas/technology_platform_read_type"/>
                                </technology-platform-read-type>
                                <technology-platform-read-pair-span>
                                    <xsl:value-of select="/GVFClin/simple_pragmas/technology_platform_read_pair_span"/>
                                </technology-platform-read-pair-span>
                                <technology-platform-average-coverage>
                                    <xsl:value-of select="/GVFClin/simple_pragmas/technology_platform_average_coverage"/>
                                </technology-platform-average-coverage>
                                <sequencing-scope>
                                    <xsl:value-of select="/GVFClin/simple_pragmas/sequencing_scope"/>
                                </sequencing-scope>
                                <capture-regions>
                                    <xsl:value-of select="/GVFClin/simple_pragmas/capture_regions"/>
                                </capture-regions>
                                <sequence-alignment>
                                    <xsl:value-of select="/GVFClin/simple_pragmas/sequence_alignment"/>
                                </sequence-alignment>
                                <variant-calling>
                                    <xsl:value-of select="/GVFClin/simple_pragmas/variant_calling"/>
                                </variant-calling>
                                <sample-description>
                                    <xsl:value-of select="/GVFClin/simple_pragmas/sample_description"/>
                                </sample-description>
                                <genomic-source>
                                    <xsl:value-of select="/GVFClin/simple_pragmas/genomic_source"/>
                                </genomic-source>
                                <multi-individual>
                                    <xsl:value-of select="/GVFClin/simple_pragmas/multi_individual"/>
                                </multi-individual>
                            </simple_pragma>
                            <structured-pragmas>
                                <technology-platform>
                                    <average_coverage>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/technology_platform/average_coverage"/>
                                    </average_coverage>
                                    <read_pair_span>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/technology_platform/read_pair_span"/>
                                    </read_pair_span>
                                    <read_type>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/technology_platform/read_type"/>
                                    </read_type>
                                    <read_length>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/technology_platform/read_length"/>
                                    </read_length>
                                    <platform_name>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/technology_platform/platform_name"/>
                                    </platform_name>
                                    <platform_class>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/technology_platform/platform_class"/>
                                    </platform_class>
                                    <comment>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/technology_platform/comment"/>
                                    </comment>
                                    <dbxref>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/technology_platform/dbxref"/>
                                    </dbxref>
                                    <type>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/technology_platform/type"/>
                                    </type>
                                    <source>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/technology_platform/source"/>
                                    </source>
                                    <seqid></seqid>
                                </technology-platform>
                                <data-source>
                                    <data_type>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/data_source/data_type"/>
                                    </data_type>
                                    <comment>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/data_source/comment"/>
                                    </comment>
                                    <dbxref>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/data_source/dbxref"/>
                                    </dbxref>
                                    <type>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/data_source/type"/>
                                    </type>
                                    <source>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/data_source/source"/>
                                    </source>
                                    <seqid>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/data_source/seqid"/>
                                    </seqid>
                                </data-source>
                                <score-method>
                                    <comment>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/score_method/comment"/>
                                    </comment>
                                    <dbxref>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/score_method/dbxref"/>
                                    </dbxref>
                                    <type>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/score_method/type"/>
                                    </type>
                                    <source>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/score_method/source"/>
                                    </source>
                                    <seqid>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/score_method/seqid"/>
                                    </seqid>
                                </score-method>
                                <source-method>
                                    <seqid>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/source_method/seqid"/>
                                    </seqid>
                                    <source>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/source_method/source"/>
                                    </source>
                                    <type>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/source_method/type"/>
                                    </type>
                                    <dbxref>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/source_method/dbxref"/>
                                    </dbxref>
                                    <comment>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/source_method/comment"/>
                                    </comment>
                                </source-method>
                                <attribute-method>
                                    <seqid>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/attribute_method/seqid"/>
                                    </seqid>
                                    <source>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/attribute_method/source"/>
                                    </source>
                                    <type>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/attribute_method/type"/>
                                    </type>
                                    <dbxref>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/attribute_method/dbxref"/>
                                    </dbxref>
                                    <comment>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/attribute_method/comment"/>
                                    </comment>
                                </attribute-method>
                                <phenotype-description>
                                    <seqid>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/phenotype_description/seqid"/>
                                    </seqid>
                                    <source>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/phenotype_description/source"/>
                                    </source>
                                    <type>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/phenotype_description/type"/>
                                    </type>
                                    <dbxref>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/phenotype_description/dbxref"/>
                                    </dbxref>
                                    <comment>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/phenotype_description/comment"/>
                                    </comment>
                                </phenotype-description>
                                <phased-genotypes>
                                    <seqid>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/phased_genotypes/seqid"/>
                                    </seqid>
                                    <source>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/phased_genotypes/source"/>
                                    </source>
                                    <type>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/phased_genotypes/type"/>
                                    </type>
                                    <dbxref>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/phased_genotypes/dbxref"/>
                                    </dbxref>
                                    <comment>
                                        <xsl:value-of select="/GVFClin/structured_pragmas/phased_genotypes/comment"/>
                                    </comment>
                                </phased-genotypes>
                            </structured-pragmas>
                        </section>
                    </component>
                </section>
            </component>
            <component>
                <section>
                    <templateId root="2.16.840.1.113883.10.20.20.1.1"/>
                    <code code="371534008" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMEDCT" displayName="Summary report"/>
                    <title>Summary of genetic variants</title>
                    <component>
                        <section>
                            <templateId root="2.16.840.1.113883.10.20.20.1.1.1"/>
                            <code code="2643614015" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMEDCT" displayName="Assessment section"/>
                            <title>GVFClin Interpretation</title>
                            <genetic-analysis-summary-panel>
                                <id>
                                    <xsl:value-of select="/GVFClin/structured_pragmas/genetic-analysis-summary-panel/id"/>
                                </id>
                                <comment>
                                    <xsl:value-of select="/GVFClin/structured_pragmas/genetic-analysis-summary-panel/comment"/>
                                </comment>
                                <GAMP>
                                    <xsl:value-of select="/GVFClin/structured_pragmas/genetic-analysis-summary-panel/GAMP"/>
                                </GAMP>
                            </genetic-analysis-summary-panel>
                            <genetic-analysis-discrete-sequence-variant-panel>
                                <comment>
                                    <xsl:value-of select="/GVFClin/structured_pragmas/genetic_analysis_discrete_sequence_variant_panel/comment"/>
                                </comment>
                            </genetic-analysis-discrete-sequence-variant-panel>
                        </section>
                    </component>
                    <component>
                        <section>
                            <templateId root="2.16.840.1.113883.10.20.20.1.1.5"/>
                            <code code="2643615019" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMEDCT" displayName="Plan section"/>
                            <title>Summary of the genetic analysis</title>
                            <genetic-analysis-discrete-report-panel>
                                <comment>
                                    <xsl:value-of select="/GVFClin/structured_pragmas/genetic_analysis_discrete_report_panel/comment"/>
                                </comment>
                            </genetic-analysis-discrete-report-panel>
                        </section>
                    </component>
                    <component>
                        <section>
                            <templateId root="2.16.840.1.113883.10.20.20.1.1.6"/>
                            <code code="405824009" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMEDCT" displayName="Genetic test"/>
                            <title>Summary of test preformed</title>
                            <genetic-analysis-master-panel>
                                <id>
                                    <xsl:value-of select="/GVFClin/structured_pragmas/genetic_analysis_master_panel/id"/>
                                </id>
                                <comment>
                                    <xsl:value-of select="/GVFClin/structured_pragmas/genetic_analysis_master_panel/comment"/>
                                </comment>
                                <OBR>
                                    <xsl:value-of select="/GVFClin/structured_pragmas/genetic_analysis_master_panel/OBR"/>
                                </OBR>
                            </genetic-analysis-master-panel>
                        </section>
                    </component>
                </section>
            </component>
            <!-- This section will have as many components as their are feature lines -->
            <component>
                <!-- Test Details Section -->
                <templateId root="2.16.840.1.113883.10.20.20.1.8"/>
                <code code="229059009" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMEDCT" displayName="Report"/>
                <!-- Clinical Genomic Statement Genetic Variation -->
                <!-- Start of the xslt looping translation -->
                <xsl:for-each select="GVFClin/feature">
                  <entry>
                      <templateId root="2.16.840.1.113883.10.20.20.2.1"/>
                      <code code="55208-3" codeSystemName="LOINC" displayName="DNA Analysis Discrete Sequence Variant Panel"/>
                      <title>GVFClin feature result</title>
                      <entryRelationship>
                      <observation>
                          <templateId root="2.16.840.1.113883.10.20.20.2.1.2"/>
                          <code code="48019-4" codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC" displayName="DNA sequence variation type"/>
                          <value>
                              <features>
                                  <seqid>
                                      <xsl:value-of select="/GVFClin/feature/seqid"/>
                                  </seqid>
                                  <source>
                                      <xsl:value-of select="/GVFClin/feature/source"/>
                                  </source>
                                  <type>
                                      <xsl:value-of select="/GVFClin/feature/type"/>
                                  </type>
                                  <start>
                                      <xsl:value-of select="/GVFClin/feature/start"/>
                                  </start>
                                  <end>
                                      <xsl:value-of select="/GVFClin/feature/end"/>
                                  </end>
                                  <score>
                                      <xsl:value-of select="/GVFClin/feature/score"/>
                                  </score>
                                  <strand>
                                      <xsl:value-of select="/GVFClin/feature/strand"/>
                                  </strand>
                                  <id>
                                      <xsl:value-of select="/GVFClin/feature/id"/>
                                  </id>
                                  <alias>
                                      <xsl:value-of select="/GVFClin/feature/alias"/>
                                  </alias>
                                  <dbxref>
                                      <xsl:value-of select="/GVFClin/feature/dbxref"/>
                                  </dbxref>
                                  <reference_aa>
                                      <xsl:value-of select="/GVFClin/feature/reference_aa"/>
                                  </reference_aa>
                                  <variant_aa>
                                      <xsl:value-of select="/GVFClin/feature/variant_aa"/>
                                  </variant_aa>
                                  <variant_reads>
                                      <xsl:value-of select="/GVFClin/feature/variant_reads"/>
                                  </variant_reads>
                                  <total_reads>
                                      <xsl:value-of select="/GVFClin/feature/total_reads"/>
                                  </total_reads>
                                  <zygosity>
                                      <xsl:value-of select="/GVFClin/feature/zygosity"/>
                                  </zygosity>
                                  <variant_freq>
                                      <xsl:value-of select="/GVFClin/feature/variant_freq"/>
                                  </variant_freq>
                                  <variant_effect>
                                      <sequence_variant_1>
                                          <xsl:value-of select="/GVFClin/feature/variant_effect/sequence_variant_1"/>
                                      </sequence_variant_1>
                                      <index_1>
                                          <xsl:value-of select="/GVFClin/feature/variant_effect/index_1"/>
                                      </index_1>
                                      <feature_type_1>
                                          <xsl:value-of select="/GVFClin/feature/variant_effect/feature_type_1"/>
                                      </feature_type_1>
                                      <feature_id1_1>
                                          <xsl:value-of select="/GVFClin/feature/variant_effect/feature_id1_1"/>
                                      </feature_id1_1>
                                      <feature_id2_1>
                                          <xsl:value-of select="/GVFClin/feature/variant_effect/feature_id2_1"/>
                                      </feature_id2_1>
                                      <sequence_variant_2>
                                          <xsl:value-of select="/GVFClin/feature/variant_effect/sequence_variant_2"/>
                                      </sequence_variant_2>
                                      <index_2>
                                          <xsl:value-of select="/GVFClin/feature/variant_effect/index_2"/>
                                      </index_2>
                                      <feature_type_2>
                                          <xsl:value-of select="/GVFClin/feature/variant_effect/feature_type_2"/>
                                      </feature_type_2>
                                      <feature_id1_2>
                                          <xsl:value-of select="/GVFClin/feature/variant_effect/feature_id1_2"/>
                                      </feature_id1_2>
                                      <feature_id2_2>
                                          <xsl:value-of select="/GVFClin/feature/variant_effect/feature_id2_2"/>
                                      </feature_id2_2>                      
                                      <sequence_variant_3>
                                          <xsl:value-of select="/GVFClin/feature/variant_effect/sequence_variant_3"/>
                                      </sequence_variant_3>
                                      <index_3>
                                          <xsl:value-of select="/GVFClin/feature/variant_effect/index_3"/>
                                      </index_3>
                                      <feature_type_3>
                                          <xsl:value-of select="/GVFClin/feature/variant_effect/feature_type_3"/>
                                      </feature_type_3>
                                      <feature_id1_3>
                                          <xsl:value-of select="/GVFClin/feature/variant_effect/feature_id1_3"/>
                                      </feature_id1_3>
                                      <feature_id2_3>
                                          <xsl:value-of select="/GVFClin/feature/variant_effect/feature_id2_3"/>
                                      </feature_id2_3>
                                  </variant_effect>
                                  <start_range>
                                      <xsl:value-of select="/GVFClin/feature/variant_effect/start_range"/>
                                  </start_range>
                                  <end_range>
                                      <xsl:value-of select="/GVFClin/feature/variant_effect/end_range"/>
                                  </end_range>
                                  <phased>
                                      <xsl:value-of select="/GVFClin/feature/phased"/>
                                  </phased>
                                  <genotype>
                                      <xsl:value-of select="/GVFClin/feature/genotype"/>
                                  </genotype>
                                  <individual>
                                      <xsl:value-of select="/GVFClin/feature/individual"/>
                                  </individual>
                                  <variant_codon>
                                      <xsl:value-of select="/GVFClin/feature/variant_codon"/>
                                  </variant_codon>
                                  <reference_codon>
                                      <xsl:value-of select="/GVFClin/feature/reference_codon"/>
                                  </reference_codon>
                                  <variant_aa>
                                      <xsl:value-of select="/GVFClin/feature/variant_aa"/>
                                  </variant_aa>
                                  <reference_aa>
                                      <xsl:value-of select="/GVFClin/feature/reference_aa"/>
                                  </reference_aa>
                                  <breakpoint_detail>
                                      <xsl:value-of select="/GVFClin/feature/breakpoint_detail"/>
                                  </breakpoint_detail>
                                  <sequence_context>
                                      <xsl:value-of select="/GVFClin/feature/sequence_context"/>
                                  </sequence_context>
                              </features>
                          </value>
                      </observation>
                      </entryRelationship>
                      <entryRelationship>
                          <observation>
                              <!-- Reference_seq -->
                              <code code="69547-8" codeSystemName="LOINC" displayName="Reference nucleotide"/>
                              <xsl:variable name="refseq">
                                  <xsl:value-of select="/GVFClin/feature/reference_seq"/>
                              </xsl:variable>
                              <value xsi:type="CD" code="{$refseq}" codeSystemName="GVF"/>
                          </observation>
                      </entryRelationship>
                      <entryRelationship>
                          <observation>
                              <!-- p-->
                              <code code="69551-0" codeSystemName="LOINC" displayName="Variable nucleotide"/>
                              <xsl:variable name="varseq">
                                  <xsl:value-of select="/GVFClin/feature/variant_seq"/>
                              </xsl:variable>
                              <value xsi:type="CD" code="{$varseq}" codeSystemName="GVF"/>
                          </observation>
                      </entryRelationship>
                      <entryRelationship typeCode="SUBJ">
                          <observation>
                              <!-- Clin_gene -->
                              <xsl:variable name="gene">
                                  <xsl:value-of select="/GVFClin/feature/clin_gene"/>
                              </xsl:variable>
                              <code code="48018-6" codeSystemName="LOINC" displayName="Gene identifier"/>
                              <value xsi:type="CD" code="{$gene}" codeSystemName="HGNC"/>
                          </observation>
                      </entryRelationship>
                      <entryRelationship typeCode="SUBJ">
                          <observation>
                              <!-- Clin_genomic_reference -->
                              <xsl:variable name="genRef">
                                  <xsl:value-of select="/GVFClin/feature/clin_genomic_reference"/>
                              </xsl:variable>
                              <code code="48013-7" codeSystemName="LOINC" displayName="Genomic reference sequence identifier"/>
                              <value xsi:type="CD" code="{$genRef}" codeSystemName="refSeq"/>
                          </observation>
                      </entryRelationship>
                      <entryRelationship typeCode="SUBJ">
                          <observation>
                              <!-- Clin_transcript -->
                              <xsl:variable name="clinTran">
                                  <xsl:value-of select="/GVFClin/feature/clin_transcript"/>
                              </xsl:variable>
                              <code code="51958-7" codeSystemName="LOINC" displayName="Transcript reference sequence identifier"/>
                              <value xsi:type="CD" code="{$clinTran}" codeSystemName="NCBI"/>
                          </observation>
                      </entryRelationship>
                      <entryRelationship typeCode="SUBJ">
                          <observation>
                              <!-- Clin_allele_name -->
                              <xsl:variable name="alleName">
                                  <xsl:value-of select="/GVFClin/feature/clin_allele_name"/>
                              </xsl:variable>
                              <code code="48008-7" codeSystemName="LOINC" displayName="Allele name"/>
                              <value xsi:type="CD" code="{$alleName}" codeSystemName="Published reports"/>
                          </observation>
                      </entryRelationship>
                      <entryRelationship typeCode="SUBJ">
                          <observation>
                              <!-- Clin_variant_id -->
                              <xsl:variable name="clinVar">
                                  <xsl:value-of select="/GVFClin/feature/clin_variant_id"/>
                              </xsl:variable>
                              <code code="48003-8" codeSystemName="LOINC" displayName="DNA sequence variation identifier"/>
                              <value xsi:type="CD" code="{$clinVar}" codeSystemName="dbSNP"/>
                          </observation>
                      </entryRelationship>
                      <entryRelationship typeCode="SUBJ">
                          <observation>
                              <!-- Clin_HGVS_DNA -->
                              <xsl:variable name="hgvsDNA">
                                  <xsl:value-of select="/GVFClin/feature/clin_HGVS_DNA"/>
                              </xsl:variable>
                              <code code="48004-6" codeSystemName="LOINC" displayName="DNA sequence variation"/>
                              <value xsi:type="CD" code="{$hgvsDNA}" codeSystemName="HGVS"/>
                          </observation>
                      </entryRelationship>        
                      <entryRelationship typeCode="SUBJ">
                          <observation>
                              <!-- Clin_variant_type -->
                              <xsl:variable name="clinVarType">
                                  <xsl:value-of select="/GVFClin/feature/clin_variant_type"/>
                              </xsl:variable>
                              <code code="48019-4" codeSystemName="LOINC" displayName="DNA sequence variation type"/>
                              <value xsi:type="CD" code="{$clinVarType}" codeSystemName="SO"/>
                          </observation>
                      </entryRelationship>
                      <entryRelationship typeCode="SUBJ">
                          <observation>
                              <!-- Clin_HGVS_protein -->
                              <xsl:variable name="hgvfPro">
                                  <xsl:value-of select="/GVFClin/feature/clin_HGVS_protein"/>
                              </xsl:variable>
                              <code code="48005-3" codeSystemName="LOINC" displayName="Amino acid change"/>
                              <value xsi:type="CD" code="{$hgvfPro}" codeSystemName="HGVS"/>
                          </observation>
                      </entryRelationship>
                      <entryRelationship typeCode="SUBJ">
                          <observation>
                              <!-- Clin_aa_change_type -->
                              <xsl:variable name="clinAAchange">
                                  <xsl:value-of select="/GVFClin/feature/clin_aa_change_type"/>
                              </xsl:variable>
                              <code code="48006-1" codeSystemName="LOINC" displayName="Amino acid change type"/>
                              <value xsi:type="CD" code="{$clinAAchange}" codeSystemName="LOINC"/>
                          </observation>
                      </entryRelationship>
                      <entryRelationship typeCode="SUBJ">
                          <observation>
                              <!-- Clin_DNA_region -->
                              <xsl:variable name="clinDNAreg">
                                  <xsl:value-of select="/GVFClin/feature/clin_DNA_region"/>
                              </xsl:variable>
                              <code code="47999-8" codeSystemName="LOINC" displayName="DNA region name"/>
                              <value xsi:type="CD" code="{$clinDNAreg}" codeSystemName="NCBI"/>
                          </observation>
                      </entryRelationship>
                      <entryRelationship typeCode="SUBJ">
                          <observation>
                              <!-- Clin_allelic_state -->
                              <xsl:variable name="clinAllicUT">
                                  <xsl:value-of select="/GVFClin/feature/clin_allelic_state"/>
                              </xsl:variable>
                              <code code="53034-5" codeSystemName="LOINC" displayName="Allelic state"/>
                              <value xsi:type="CD" code="{$clinAllicUT}" codeSystemName="LOINC"/>
                          </observation>
                      </entryRelationship>
                      <entryRelationship typeCode="SUBJ">
                          <observation>
                              <!-- Clin_variant_display_name -->
                              <xsl:variable name="clinDispName">
                                  <xsl:value-of select="/GVFClin/feature/clin_variant_display_name"/>
                              </xsl:variable>
                              <code code="47998-0" codeSystemName="LOINC" displayName="DNA sequence variation display name"/>
                              <value xsi:type="CD" code="{$clinDispName}"/>
                          </observation>
                      </entryRelationship>
                      <entryRelationship typeCode="SUBJ">
                          <observation>
                              <!-- Clin_disease_variant_interpret -->
                              <xsl:variable name="clinInterp">
                                  <xsl:value-of select="/GVFClin/feature/clin_disease_variant_interpret"/>
                              </xsl:variable>
                              <code code="53037-8" codeSystemName="LOINC" displayName="Genetic disease sequence variation interpretation"/>
                              <value xsi:type="CD" code="{$clinInterp}" codeSystemName="LOINC"/>
                          </observation>
                      </entryRelationship>
                      <entryRelationship typeCode="SUBJ">
                          <observation>
                              <!-- Clin_drug_metabolism_interpret -->
                              <xsl:variable name="clinDrugMet">
                                  <xsl:value-of select="/GVFClin/feature/clin_drug_metabolism_interpret"/>
                              </xsl:variable>
                              <code code="53040-2" codeSystemName="LOINC" displayName="Drug metabolism sequence variation interpretation"/>
                              <value xsi:type="CD" code="{$clinDrugMet}" codeSystemName="LOINC"/>
                          </observation>
                      </entryRelationship>
                      <entryRelationship typeCode="SUBJ">
                          <observation>
                              <!-- Clin_drug_efficacy_interpret -->
                              <xsl:variable name="clinDrugEff">
                                  <xsl:value-of select="/GVFClin/feature/clin_drug_efficacy_interpret"/>
                              </xsl:variable>
                              <code code="51961-1" codeSystemName="LOINC" displayName="Drug efficacy sequence variation interpretation"/>
                              <value xsi:type="CD" code="{$clinDrugEff}" codeSystemName="LOINC"/>
                          </observation>
                      </entryRelationship>
                  </entry>
                </xsl:for-each>
            </component>
        </ClinicalDocument>
    </xsl:template>
</xsl:stylesheet>
