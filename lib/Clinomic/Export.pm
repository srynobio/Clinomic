package Clinomic::Export;
use Moose::Role;
use IO::File;
use File::Basename;
use XML::Generator;

use Data::Dumper;

with 'MooseX::Getopt';

#-----------------------------------------------------------------------------
#------------------------------- Attributes ----------------------------------
#-----------------------------------------------------------------------------

has 'export' => (
  is      => 'rw',
  isa     => 'Str',
  reader  => 'get_export',
  default => 'gvfclin',
  documentation => q(Export GVF file to various formats.  Options: gvfclin, xml, hl7, all.  Default is gvfclin.),
);

has 'xmlTemp' => (
    traits  => ['NoGetopt'],
    is      => 'rw',
    isa     => 'Str',
    reader  => 'get_xmlTemp',
    writer  => 'set_xmlTemp',
    default => '../data/XML/GVFClinTemplate.xml',
);

#-----------------------------------------------------------------------------
#------------------------------- Methods -------------------------------------
#-----------------------------------------------------------------------------

sub exporter {
    my ( $self, $gvf ) = @_;

    my $type = $self->get_export;

    if ( $type eq 'gvfclin' ) {
        warn "{Clinomic} Building GVFClin file.\n";
        $self->pragma_writer($gvf);
        $self->feature_writer($gvf);
    }
    elsif ( $type eq 'xml' ) {
        warn "{Clinomic} Building XML.\n";
        $self->gvf2XML($gvf);
        $self->_completeXML;
    }
    elsif ( $type eq 'hl7' ) {
        warn "{Clinomic} Building HL7-XML file.\n";
        $self->gvf2XML($gvf);
        $self->_completeXML;
        $self->_toGTR($gvf);
    }
    elsif ( $type eq 'all' ) {
        warn "{Clinomic} Building all output files.\n";
        $self->pragma_writer($gvf);
        $self->feature_writer($gvf);
        $self->gvf2XML($gvf);
        $self->_completeXML;
        $self->_toGTR($gvf);
    }
}

#-----------------------------------------------------------------------------
sub pragma_writer {

  my $self = shift;
  my $pragmas = $self->get_pragmas;

  # get the file name
  my $basename = basename( $self->get_file, ".gvf" );
  my $outfile  = "$basename" . '.gvfclin';
  my $outFH    = IO::File->new( "$outfile", 'a+' );

  # slice of start and end of pragma data, then remove it from hash.
  my ($version, $seq_region) = @{$pragmas}{'gvf_version', 'sequence_region'};
  delete $pragmas->{'gvf_version'};
  delete $pragmas->{'sequence_region'};

  # print version first.
  print $outFH "##gvf-version $version->[0]\n";

  # print out pragma values.
  while ( my ( $k, $v ) = each %{$pragmas} ) {
    $k =~ s/\_/\-/g;
    if ( ref $v->[0] ) {
      print $outFH "##$k ";
      while ( my ( $key, $v ) = each %{ $v->[0] } ) {
        print $outFH "$key=$v;";
      }
      print $outFH "\n";
    }
    else { print $outFH "##$k " . $v->[0], "\n"; }
  }

  # then print out sequence_region
  map {
    print $outFH "##sequence-region $_\n";
  } @{$seq_region};

}
#-----------------------------------------------------------------------------

sub feature_writer {
    my ( $self, $gvf ) = @_;

    # get the file name
    my $basename = basename( $self->get_file, ".gvf" );
    my $outfile = "$basename" . '.gvfclin';

    my $outFH = IO::File->new( "$outfile", 'a+' );

    # print out in gvf format.
    foreach my $i ( @{$gvf} ) {

      my $first8 = "$i->{'seqid'}\t$i->{'source'}\t$i->{'type'}\t"
          . "$i->{'start'}\t$i->{'end'}\t$i->{'score'}\t$i->{'strand'}\t.";

      print $outFH "$first8\t";

      while ( my ( $k2, $v2 ) = each %{ $i->{'attribute'} } ) {

        if ( $k2 eq 'clin' ) {
          while ( my ( $k, $v ) = each %{$v2} ) {
            print $outFH "$k=$v;" if $v;
          }
        }
        elsif ( $k2 eq 'Variant_effect' ) {
          next unless (scalar @{$v2} > 0 );
          print $outFH "Variant_effect=";

          my $line;
          foreach ( @{$v2} ) {

            my $fields = join( ' ',
            $_->{'sequence_variant'}, $_->{'index'},
            $_->{'feature_type'},     $_->{'feature_id'} );

            # create one line seperated by comma.
            $line .= $fields;
            $line .= ',';
          }

          # remove last comma, and print line
          $line =~ s/(.*)\,$/$1;/ if $line;
          print $outFH $line if $line;
        }
        else {
          print $outFH "$k2=$v2;" if $v2;
        }
      }
      print $outFH "\n";
    }
    $outFH->close;
}
#-----------------------------------------------------------------------------

sub gvf2XML {
    my ( $self, $data ) = @_;

    # get pragma data and make IO file
    my $pragmaData = $self->get_pragmas;
    my $xmlFH = IO::File->new( "temp.xml", 'a+' );

    # make XML::Generator object
    my $X = XML::Generator->new(':pretty');

    # simple pragmas
    my $simplePragma = $X->simple_pragmas(
        $X->gvf_version( $pragmaData->{gvf_version}[0] ),
        $X->reference_fasta( $pragmaData->{reference_fasta}[0] ),
        $X->feature_gff3( $pragmaData->{feature_gff3}[0] ),
        $X->file_version( $pragmaData->{file_version}[0] ),
        $X->file_date( $pragmaData->{file_date}[0] ),
        $X->individual_id( $pragmaData->{individual_id}[0] ),
        $X->population( $pragmaData->{population}[0] ),
        $X->sex( $pragmaData->{sex}[0] ),
        $X->technology_platform_class(
            $pragmaData->{technology_platform_class}[0]
        ),
        $X->technology_platform_name(
            $pragmaData->{technology_platform_name}[0]
        ),
        $X->technology_platform_version(
            $pragmaData->{technology_platform_version}[0]
        ),
        $X->technology_platform_machine_id(
            $pragmaData->{technology_platform_machine_id}[0]
        ),
        $X->technology_platform_read_length(
            $pragmaData->{technology_platform_read_length}[0]
        ),
        $X->technology_platform_read_type(
            $pragmaData->{technology_platform_read_type}[0]
        ),
        $X->technology_platform_read_pair_span(
            $pragmaData->{technology_platform_read_pair_span}[0]
        ),
        $X->technology_platform_average_coverage(
            $pragmaData->{technology_platform_average_coverage}[0]
        ),
        $X->sequencing_scope( $pragmaData->{sequencing_scope}[0] ),
        $X->capture_regions( $pragmaData->{capture_regions}[0] ),
        $X->sequence_alignment( $pragmaData->{sequence_alignment}[0] ),
        $X->variant_calling( $pragmaData->{variant_calling}[0] ),
        $X->genomic_source( $pragmaData->{genomic_source}[0] ),
        $X->multi_individual( $pragmaData->{multi_individual}[0] ),
    );

    # structured pragmas
    my $structPragma = $X->structured_pragmas(
        $X->technology_platform(
            $X->seqid( $pragmaData->{technology_platform}[0]->{Seqid} ),
            $X->source( $pragmaData->{technology_platform}[0]->{Source} ),
            $X->type( $pragmaData->{technology_platform}[0]->{Type} ),
            $X->dbxref( $pragmaData->{technology_platform}[0]->{Dbxref} ),
            $X->comment( $pragmaData->{technology_platform}[0]->{Comment} ),
            $X->platform_class(
                $pragmaData->{technology_platform}[0]->{Platform_class}
            ),
            $X->platform_name(
                $pragmaData->{technology_platform}[0]->{Platform_name}
            ),
            $X->read_length(
                $pragmaData->{technology_platform}[0]->{Read_length}
            ),
            $X->read_type( $pragmaData->{technology_platform}[0]->{Read_type} ),
            $X->read_pair_span(
                $pragmaData->{technology_platform}[0]->{Read_pair_span}
            ),
            $X->average_coverage(
                $pragmaData->{technology_platform}[0]->{Average_coverage}
            ),
        ),
        $X->data_source(
            $X->seqid( $pragmaData->{data_source}[0]->{Seqid} ),
            $X->source( $pragmaData->{data_source}[0]->{Source} ),
            $X->type( $pragmaData->{data_source}[0]->{Type} ),
            $X->dbxref( $pragmaData->{data_source}[0]->{Dbxref} ),
            $X->comment( $pragmaData->{data_source}[0]->{Comment} ),
            $X->data_type( $pragmaData->{data_source}[0]->{Data_type} ),
        ),
        $X->score_method(
            $X->seqid( $pragmaData->{score_method}[0]->{Seqid} ),
            $X->source( $pragmaData->{score_method}[0]->{Source} ),
            $X->type( $pragmaData->{score_method}[0]->{Type} ),
            $X->dbxref( $pragmaData->{score_method}[0]->{Dbxref} ),
            $X->comment( $pragmaData->{score_method}[0]->{Comment} ),
        ),
        $X->attribute_method(
            $X->seqid( $pragmaData->{attribute_method}[0]->{Seqid} ),
            $X->source( $pragmaData->{attribute_method}[0]->{Source} ),
            $X->type( $pragmaData->{attribute_method}[0]->{Type} ),
            $X->dbxref( $pragmaData->{attribute_method}[0]->{Dbxref} ),
            $X->comment( $pragmaData->{attribute_method}[0]->{Comment} ),
        ),
        $X->phenotype_description(
            $X->seqid( $pragmaData->{phenotype_description}[0]->{Seqid} ),
            $X->source( $pragmaData->{phenotype_description}[0]->{Source} ),
            $X->type( $pragmaData->{phenotype_description}[0]->{Type} ),
            $X->dbxref( $pragmaData->{phenotype_description}[0]->{Dbxref} ),
            $X->comment( $pragmaData->{phenotype_description}[0]->{Comment} ),
        ),
        $X->phased_genotypes(
            $X->seqid( $pragmaData->{phased_genotypes}[0]->{Seqid} ),
            $X->source( $pragmaData->{phased_genotypes}[0]->{Source} ),
            $X->type( $pragmaData->{phased_genotypes}[0]->{Type} ),
            $X->dbxref( $pragmaData->{phased_genotypes}[0]->{Dbxref} ),
            $X->comment( $pragmaData->{phased_genotypes}[0]->{Comment} ),
        ),
        ## start of the GVFClin terms
        $X->genetic_analysis_master_panel(
            $X->genetic_analysis_master_panel(
                $pragmaData->{genetic_analysis_master_panel}[0]->{ID}
            ),
            $X->comment(
                $pragmaData->{genetic_analysis_master_panel}[0]->{Comment}
            ),
            $X->obr( $pragmaData->{genetic_analysis_master_panel}[0]->{OBR} ),
        ),
        $X->genetic_analysis_summary_panel(
            $X->id( $pragmaData->{genetic_analysis_summary_panel}[0]->{ID} ),
            $X->comment(
                $pragmaData->{genetic_analysis_summary_panel}[0]->{Comment}
            ),
            $X->gamp(
                $pragmaData->{genetic_analysis_summary_panel}[0]->{GAMP}
            ),
        ),
        $X->genetic_analysis_discrete_report_panel(
            $X->comment(
                $pragmaData->{'genetic_analysis_discrete_report_panel'}[0]
                  ->{'Comment'}
            ),
        ),
        $X->genetic_analysis_discrete_sequence_variant_panel(
            $X->comment(
                $pragmaData->{
                    'genetic_analysis_discrete_sequence_variant_panel'}[0]
                  ->{'Comment'}
            ),
        ),
    );

    # Collect the two different pragma sets
    my $pragmaSection = $X->pragma( $simplePragma, $structPragma );

    my @list;
    foreach my $i ( @{$data} ) {
        chomp $i;

        my @effectList;
        if ( $i->{attribute}->{Variant_effect} ) {
            my $count;
            foreach my $xml ( @{ $i->{attribute}->{Variant_effect} } ) {

                # reset the count
                if ( $xml->{seqid} ) { $count = 0 }

                $count++;
                my $id =
                  $X->feature_id( { effect => $count }, $xml->{feature_id} );
                my $index = $X->index( { effect => $count }, $xml->{index} );
                my $seq_var = $X->sequence_variant( { effect => $count },
                    $xml->{sequence_variant} );
                my $type =
                  $X->feature_type( { effect => $count },
                    $xml->{feature_type} );

                push @effectList, $id, $index, $seq_var, $type;
            }
        }

        my $featureLine = $X->feature(
            $X->seqid( $i->{seqid} ),
            $X->source( $i->{source} ),
            $X->type( $i->{type} ),
            $X->start( $i->{start} ),
            $X->end( $i->{end} ),
            $X->score( $i->{score} ),
            $X->strand( $i->{strand} ),

            # attribute xml elements
            $X->id( $i->{attribute}->{ID} ),
            $X->alias( $i->{attribute}->{Alias} ),
            $X->dbxref( $i->{attribute}->{Dbxref} ),
            $X->variant_seq( $i->{attribute}->{Variant_seq} ),
            $X->reference_seq( $i->{attribute}->{Reference_seq} ),
            $X->variant_reads( $i->{attribute}->{Variant_reads} ),
            $X->total_reads( $i->{attribute}->{Total_reads} ),
            $X->zygosity( $i->{attribute}->{Zygosity} ),
            $X->variant_freq( $i->{attribute}->{Variant_freq} ),
            $X->variant_effect(@effectList),
            $X->start_range( $i->{attribute}->{Start_range} ),
            $X->end_range( $i->{attribute}->{End_range} ),
            $X->phased( $i->{attribute}->{Phased} ),
            $X->genotype( $i->{attribute}->{Genotype} ),
            $X->individual( $i->{attribute}->{Individual} ),
            $X->variant_codon( $i->{attribute}->{Variant_codon} ),
            $X->reference_codon( $i->{attribute}->{Reference_codon} ),
            $X->variant_aa( $i->{attribute}->{Variant_aa} ),
            $X->reference_aa( $i->{attribute}->{Reference_aa} ),
            $X->breakpoint_detail( $i->{attribute}->{Breakpoint_detail} ),
            $X->sequence_context( $i->{attribute}->{Sequence_context} ),

            # Clin terms
            $X->clin_gene( $i->{attribute}->{clin}->{Clin_gene} ),
            $X->clin_genomic_reference(
                $i->{attribute}->{clin}->{Clin_genomic_reference}
            ),
            $X->clin_transcript( $i->{attribute}->{clin}->{Clin_transcript} ),
            $X->clin_allele_name( $i->{attribute}->{clin}->{Clin_allele_name} ),
            $X->clin_variant_id( $i->{attribute}->{clin}->{Clin_variant_id} ),
            $X->clin_HGVS_DNA( $i->{attribute}->{clin}->{Clin_HGVS_DNA} ),
            $X->clin_variant_type(
                $i->{attribute}->{clin}->{Clin_variant_type}
            ),
            $X->clin_HGVS_protein(
                $i->{attribute}->{clin}->{Clin_HGVS_protein}
            ),
            $X->clin_aa_change_type(
                $i->{attribute}->{clin}->{Clin_aa_change_type}
            ),
            $X->clin_DNA_region( $i->{attribute}->{clin}->{Clin_DNA_region} ),
            $X->clin_allelic_state(
                $i->{attribute}->{clin}->{Clin_allelic_state}
            ),
            $X->clin_variant_display_name(
                $i->{attribute}->{clin}->{Clin_variant_display_name}
            ),
            $X->clin_disease_variant_interpret(
                $i->{attribute}->{clin}->{Clin_disease_variant_interpret}
            ),
            $X->clin_drug_metabolism_interpret(
                $i->{attribute}->{clin}->{Clin_drug_metabolism_interpret}
            ),
            $X->clin_drug_efficacy_interpret(
                $i->{attribute}->{clin}->{Clin_drug_efficacy_interpret}
            ),
        );
        push @list, $featureLine;
    }
    print $xmlFH $X->GVFClin( $pragmaSection, @list );
    $xmlFH->close;
}

#-----------------------------------------------------------------------------

sub _completeXML {
    my $self = shift;

    my $basename = basename( $self->get_file, ".gvf" );

    my $xmlFH = IO::File->new( 'temp.xml', 'r' )
      || die "XML temp file not found\n";
    my $outfile = "$basename" . '.xml';

    my $xmlNEW = IO::File->new( "$outfile", 'a+' );

    print $xmlNEW '<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="GVF-CDA-GTR.xsl"?>', "\n";

    while (<$xmlFH>) {

        # Only print lines which have data
        if ( $_ =~ /(><\/)/ ) { next }

        print $xmlNEW $_;
    }

    # remove the temp file
    `rm temp.xml`;

    $xmlFH->close;
    $xmlNEW->close;
}

#-----------------------------------------------------------------------------

sub _toGTR {
    my ( $self, $gvf ) = @_;

    # get the file name
    my $basename = basename( $self->get_file, ".gvf" );
    my $outfile = "$basename" . '_hl7.xml';

    my $outFH = IO::File->new( "$outfile", 'r' );

    # get xml file to use for XSLT
    my $xmlFile = "$basename" . ".xml";

    # use Saxon to do transformation.
    # and change gt lt and &amp.
    system("java -jar ../data/Saxon/saxon9he.jar -xsl:../data/XML/GVF-CDA-GTR.xsl -s:$xmlFile -o:$outfile");
    system("perl -p -i -e 's/&gt;/>/g' $outfile");
    system("perl -p -i -e 's/&lt;/</g' $outfile");
    system("perl -p -i -e 's/&amp;/&/g' $outfile");
}

#-----------------------------------------------------------------------------

no Moose;
1;
