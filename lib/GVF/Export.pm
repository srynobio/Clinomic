package GVF::Export;
use Moose::Role;
use IO::File;
use File::Basename;
use XML::Twig;

with 'MooseX::Getopt';

use lib '../lib';
use Data::Dumper;

#-----------------------------------------------------------------------------
#------------------------------- Attributes ----------------------------------
#-----------------------------------------------------------------------------

has 'xmlTemp' => (
    traits   =>['NoGetopt'],
    is       => 'rw',
    isa      => 'Str',
    reader   => 'get_xmlTemp',
    writer   => 'set_xmlTemp',
    default => '../data/XML/GVFClinTemplate.xml',
);

#-----------------------------------------------------------------------------
#------------------------------- Methods -------------------------------------
#-----------------------------------------------------------------------------

sub exporter {
    my ($self, $gvf) = @_;
    
    my $type = $self->get_export;
    
    if ($type eq 'GVFClin'){
        $self->toGVF($gvf);
    }
    elsif ( $type eq 'XML'){
        $self->toXML($gvf);
    }
    elsif( $type eq 'Both'){
        $self->toGVF($gvf);
        $self->toXML($gvf);
    }
}

#-----------------------------------------------------------------------------

sub toGVF {
    my ($self, $gvf) = @_;

    # get the file name
    my $basename = basename($self->get_file, ".gvf");
    my $outFH = IO::File->new("$basename.gvfclin", 'a+');
    
    # check for pragama values.
    my $pragma;
    if ($self->has_pragmas){
        $pragma = $self->get_pragmas;
    }

    # print out pragma values.    
    while (my ($k, $v ) = each %{$pragma}){
        if (ref $v->[0]) {
                print $outFH "##$k ";
            while (my ($key, $v) = each %{$v->[0]}){
                print $outFH "$key=$v;";
            }
            print $outFH "\n";
        }
        else { print $outFH "##$k " . $v->[0], "\n"; }
    }

    # print out in gvf format.    
    foreach my $i ( @{$gvf} ){

        my $first8 =
        "$i->{'seqid'}\t$i->{'source'}\t$i->{'type'}\t" .
        "$i->{'start'}\t$i->{'end'}\t$i->{'score'}\t$i->{'strand'}\t.\t";
        
        print $outFH "$first8\t";
        
        while ( my ($k2, $v2) = each %{$i->{'attribute'}} ){
            
            if ( $k2 eq 'clin'){
                while ( my ($k, $v) = each %{$v2} ){
                    print $outFH "$k=$v;" if $v;
                }
            }
            elsif ( $k2 eq 'Variant_effect'){
                print $outFH "Variant_effect=";
                
                my $line;
                foreach (@{$v2}){
                    my $fields = join(' ', $_->{'sequence_variant'}, $_->{'index'}, $_->{'feature_type'}, $_->{'feature_id1'});
                    
                    # add this if it's around
                    $fields .= $_->{'feature_id2'} if $_->{'feature_id2'};
                    
                    # create one line seperated by comma.
                    $line .= $fields;
                    $line .= ',';
                }
                # remove last comma, and print line
                $line =~ s/(.*)\,$/$1;/;
                print $outFH $line;
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

sub toXML {
    
    # Im guessing, forever from this day I will regret the day I
    # ever knew XML::Twig existed.
    my ($self, $gvf) = @_;
    my $fh = IO::File->new('temp.xml', 'a+');

    if ( keys %{$self->get_pragmas} ){
        my $spTwig = $self->simplePragmaXML($gvf, $fh);
        my $stTwig = $self->structPragmaXML($gvf, $fh);
    }
    my $featTwig = $self->featureXML($gvf, $fh);
    $fh->close;
}

#-----------------------------------------------------------------------------

sub simplePragmaXML {
    my ($self, $gvf, $fh) = @_;

    # get pragma data.    
    my $p = $self->get_pragmas;
    
    #parse the gvf data to xml
    my $twig = XML::Twig->new(
        pretty_print  => 'indented',
        twig_roots    => { simple_pragmas => 1 },
        twig_handlers => {
            gvf_version                          => sub {$_->set_text($p->{'gvf_version'}[0])},
            reference_fasta                      => sub {$_->set_text($p->{'reference_version'}[0])},
            feature_gff3                         => sub {$_->set_text($p->{'feature_gff3'}[0])},
            file_version                         => sub {$_->set_text($p->{'file_version'}[0])},
            file_date                            => sub {$_->set_text($p->{'file_date'}[0])},
            individual_id                        => sub {$_->set_text($p->{'individual_id'}[0])},
            population                           => sub {$_->set_text($p->{'population'}[0])},
            sex                                  => sub {$_->set_text($p->{'sex'}[0])},
            technology_platform_class            => sub {$_->set_text($p->{'technology_platform_class'}[0])},
            technology_platform_name             => sub {$_->set_text($p->{'technology_platform_name'}[0])},
            technology_platform_version          => sub {$_->set_text($p->{'technology_platform_version'}[0])},
            technology_platform_machine_id       => sub {$_->set_text($p->{'technology_platform_machine_id'}[0])},
            technology_platform_read_length      => sub {$_->set_text($p->{'technology_platform_read_length'}[0])},
            technology_platform_read_type        => sub {$_->set_text($p->{'technology_platform_read_type'}[0])},
            technology_platform_read_pair_span   => sub {$_->set_text($p->{'technology_platform_read_pair_span'}[0])},
            technology_platform_average_coverage => sub {$_->set_text($p->{'technology_platform_average_coverage'}[0])},
            sequencing_scope                     => sub {$_->set_text($p->{'sequencing_scope'}[0])},
            capture_regions                      => sub {$_->set_text($p->{'capture_regions'}[0])},
            sequence_alignment                   => sub {$_->set_text($p->{'sequence_alignment'}[0])},
            variant_calling                      => sub {$_->set_text($p->{'variant_calling'}[0])},
            variant_calling                      => sub {$_->set_text($p->{'variant_calling'}[0])},
            genomic_source                       => sub {$_->set_text($p->{'genomic_source'}[0])},
        },
    );
    $twig->parsefile($self->get_xmlTemp);
    $twig->flush($fh);
}

#-----------------------------------------------------------------------------

sub structPragmaXML {
    my ($self, $gvf, $fh) = @_;
    
    # get pragma data.    
    my $p = $self->get_pragmas;
    
    # parse the pragma data to xml insert_new_elt will create a new
    # element for each child term regardless if value exists.
    my $twig = XML::Twig->new(
        pretty_print  => 'indented',
        twig_roots    => { structured_pragmas => 1 },
        twig_handlers => {
            technology_platform => sub {
                $_->insert_new_elt('seqid', $p->{'technology_platform'}[0]->{'Seqid'}),
                $_->insert_new_elt('source', $p->{'technology_platform'}[0]->{'Source'}),
                $_->insert_new_elt('type', $p->{'technology_platform'}[0]->{'Type'}),
                $_->insert_new_elt('dbxref', $p->{'technology_platform'}[0]->{'Dbxref'}),
                $_->insert_new_elt('comment', $p->{'technology_platform'}[0]->{'Comment'}),
                $_->insert_new_elt('platform_class', $p->{'technology_platform'}[0]->{'Platform_class'}),
                $_->insert_new_elt('platform_name', $p->{'technology_platform'}[0]->{'Platform_name'}),
                $_->insert_new_elt('read_length', $p->{'technology_platform'}[0]->{'Read_length'}),
                $_->insert_new_elt('read_type', $p->{'technology_platform'}[0]->{'Read_type'}),
                $_->insert_new_elt('read_pair_span', $p->{'technology_platform'}[0]->{'Read_pair_span'}),
                $_->insert_new_elt('average_coverage', $p->{'technology_platform'}[0]->{'Average_coverage'}),
            },
            data_source => sub {
                $_->insert_new_elt('seqid', $p->{'data_source'}[0]->{'Seqid'}),
                $_->insert_new_elt('source', $p->{'data_source'}[0]->{'Source'}),
                $_->insert_new_elt('type', $p->{'data_source'}[0]->{'Type'}),
                $_->insert_new_elt('dbxref', $p->{'data_source'}[0]->{'Dbxref'}),
                $_->insert_new_elt('comment', $p->{'data_source'}[0]->{'Comment'}),
                $_->insert_new_elt('data_type', $p->{'data_source'}[0]->{'Data_type'}),
            },
            score_method => sub {
                $_->insert_new_elt('seqid', $p->{'score_method'}[0]->{'Seqid'}),
                $_->insert_new_elt('source', $p->{'score_method'}[0]->{'Source'}),
                $_->insert_new_elt('type', $p->{'score_method'}[0]->{'Type'}),
                $_->insert_new_elt('dbxref', $p->{'score_method'}[0]->{'Dbxref'}),
                $_->insert_new_elt('comment', $p->{'score_method'}[0]->{'Comment'}),
            },
            attribute_method => sub {
                $_->insert_new_elt('seqid', $p->{'attribute_method'}[0]->{'Seqid'}),
                $_->insert_new_elt('source', $p->{'attribute_method'}[0]->{'Source'}),
                $_->insert_new_elt('type', $p->{'attribute_method'}[0]->{'Type'}),
                $_->insert_new_elt('dbxref', $p->{'attribute_method'}[0]->{'Dbxref'}),
                $_->insert_new_elt('comment', $p->{'attribute_method'}[0]->{'Comment'}),
            },
            phenotype_description => sub {
                $_->insert_new_elt('seqid', $p->{'phenotype_description'}[0]->{'Seqid'}),
                $_->insert_new_elt('source', $p->{'phenotype_description'}[0]->{'Source'}),
                $_->insert_new_elt('type', $p->{'phenotype_description'}[0]->{'Type'}),
                $_->insert_new_elt('dbxref', $p->{'phenotype_description'}[0]->{'Dbxref'}),
                $_->insert_new_elt('comment', $p->{'phenotype_description'}[0]->{'Comment'}),                
            },
            phased_genotypes => sub {
                $_->insert_new_elt('seqid', $p->{'phased_genotypes'}[0]->{'Seqid'}),
                $_->insert_new_elt('source', $p->{'phased_genotypes'}[0]->{'Source'}),
                $_->insert_new_elt('type', $p->{'phased_genotypes'}[0]->{'Type'}),
                $_->insert_new_elt('dbxref', $p->{'phased_genotypes'}[0]->{'Dbxref'}),
                $_->insert_new_elt('comment', $p->{'phased_genotypes'}[0]->{'Comment'}),                                
            },
            # start of the GVFClin terms
            genetic_analysis_master_panel => sub {
                $_->insert_new_elt('id', $p->{'genetic_analysis_master_panel'}[0]->{'ID'}),
                $_->insert_new_elt('comment', $p->{'genetic_analysis_master_panel'}[0]->{'Comment'}),
                $_->insert_new_elt('obr', $p->{'genetic_analysis_master_panel'}[0]->{'OBR'}),
            },
            genetic_analysis_summary_panel => sub {
                $_->insert_new_elt('id', $p->{'genetic_analysis_summary_panel'}[0]->{'ID'}),
                $_->insert_new_elt('comment', $p->{'genetic_analysis_summary_panel'}[0]->{'Comment'}),
                $_->insert_new_elt('gamp', $p->{'genetic_analysis_summary_panel'}[0]->{'GAMP'}),
            },
            genetic_analysis_discrete_report_panel => sub {
                $_->insert_new_elt('comment', $p->{'genetic_analysis_discrete_report_panel'}[0]->{'Comment'}),
            },
            genetic_analysis_discrete_sequence_variant_panel => sub {
                $_->insert_new_elt('comment', $p->{'genetic_analysis_discrete_sequence_variant_panel'}[0]->{'Comment'}),
            },
        },
    );
    $twig->parsefile($self->get_xmlTemp);
    $twig->flush($fh);
}

#-----------------------------------------------------------------------------

sub featureXML {
    my ($self, $gvf, $fh) = @_;

    my $twig;
    foreach my $f (@{$gvf}){
        my $eff = $f->{'attribute'}->{'Variant_effect'};
        
        $twig = XML::Twig->new(
            pretty_print  => 'indented',
            twig_roots    => { feature => 1 },
            twig_handlers => {
                seqid             => sub {$_->set_text($f->{'seqid'})},
                source            => sub {$_->set_text($f->{'source'})},
                type              => sub {$_->set_text($f->{'type'})},
                start             => sub {$_->set_text($f->{'start'})},
                end               => sub {$_->set_text($f->{'end'})},
                score             => sub {$_->set_text($f->{'score'})},
                strand            => sub {$_->set_text($f->{'strand'})},                
                id                => sub {$_->set_text($f->{'attribute'}->{'ID'})},
                alias             => sub {$_->set_text($f->{'attribute'}->{'Alias'})},
                dbxref            => sub {$_->set_text($f->{'attribute'}->{'Dbxref'})},
                variant_seq       => sub {$_->set_text($f->{'attribute'}->{'Variant_seq'})},
                reference_seq     => sub {$_->set_text($f->{'attribute'}->{'Reference_seq'})},
                variant_reads     => sub {$_->set_text($f->{'attribute'}->{'Variant_reads'})},
                total_reads       => sub {$_->set_text($f->{'attribute'}->{'Total_reads'})},
                zygosity          => sub {$_->set_text($f->{'attribute'}->{'Zygosity'})},
                variant_freq      => sub {$_->set_text($f->{'attribute'}->{'Variant_freq'})},
                start_range       => sub {$_->set_text($f->{'attribute'}->{'Start_range'})},
                end_range         => sub {$_->set_text($f->{'attribute'}->{'End_range'})},
                phased            => sub {$_->set_text($f->{'attribute'}->{'Phased'})},
                genotype          => sub {$_->set_text($f->{'attribute'}->{'Genotype'})},
                individual        => sub {$_->set_text($f->{'attribute'}->{'Individual'})},
                variant_codon     => sub {$_->set_text($f->{'attribute'}->{'Variant_codon'})},
                reference_codon   => sub {$_->set_text($f->{'attribute'}->{'Reference_codon'})},
                variant_aa        => sub {$_->set_text($f->{'attribute'}->{'Variant_aa'})},
                reference_aa      => sub {$_->set_text($f->{'attribute'}->{'Reference_aa'})},
                breakpoint_detail => sub {$_->set_text($f->{'attribute'}->{'Breakpoint_detail'})},
                sequence_context  => sub {$_->set_text($f->{'attribute'}->{'Sequence_context'})},
                
                # Creating variant effect xml data.
                variant_effect => sub {
                            $_->insert_new_elt('sequence_variant', $eff->[0]->{'sequence_variant'}),
                            $_->insert_new_elt('feature_id', $eff->[0]->{'feature_id1'}),
                            $_->insert_new_elt('sequence_variant', $eff->[0]->{'sequence_variant'}),
                            $_->insert_new_elt('feature_id', $eff->[0]->{'feature_id2'}),
                            $_->insert_new_elt('feature_type', $eff->[0]->{'feature_type'}),
                            
                            $_->insert_new_elt('sequence_variant', $eff->[1]->{'sequence_variant'}),
                            $_->insert_new_elt('feature_id', $eff->[1]->{'feature_id1'}),
                            $_->insert_new_elt('sequence_variant', $eff->[1]->{'sequence_variant'}),
                            $_->insert_new_elt('feature_id', $eff->[1]->{'feature_id2'}),
                            $_->insert_new_elt('feature_type', $eff->[1]->{'feature_type'}),
                    
                            $_->insert_new_elt('sequence_variant', $eff->[1]->{'sequence_variant'}),
                            $_->insert_new_elt('feature_id', $eff->[1]->{'feature_id1'}),
                            $_->insert_new_elt('sequence_variant', $eff->[1]->{'sequence_variant'}),
                            $_->insert_new_elt('feature_id', $eff->[1]->{'feature_id2'}),
                            $_->insert_new_elt('feature_type', $eff->[1]->{'feature_type'}),
                },
                # start of GVFClin features
                clin_gene                      => sub {$_->set_text($f->{'attribute'}->{'clin'}->{'Clin_gene'})},
                clin_genomic_reference         => sub {$_->set_text($f->{'attribute'}->{'clin'}->{'Clin_genomic_reference'})},
                clin_transcript                => sub {$_->set_text($f->{'attribute'}->{'clin'}->{'Clin_transcript'})},
                clin_allele_name               => sub {$_->set_text($f->{'attribute'}->{'clin'}->{'Clin_allele_name'})},
                clin_variant_id                => sub {$_->set_text($f->{'attribute'}->{'Clin_variant_id'})},
                clin_HGVS_DNA                  => sub {$_->set_text($f->{'attribute'}->{'clin'}->{'Clin_HGVS_DNA'})},
                clin_variant_type              => sub {$_->set_text($f->{'attribute'}->{'clin'}->{'Clin_variant_type'})},
                clin_HGVS_protein              => sub {$_->set_text($f->{'attribute'}->{'clin'}->{'Clin_HGVS_protein'})},
                clin_aa_change_type            => sub {$_->set_text($f->{'attribute'}->{'clin'}->{'Clin_aa_change_type'})},
                clin_DNA_region                => sub {$_->set_text($f->{'attribute'}->{'clin'}->{'Clin_DNA_region'})},
                clin_allelic_state             => sub {$_->set_text($f->{'attribute'}->{'clin'}->{'clin_allelic_state'})},
                clin_variant_display_name      => sub {$_->set_text($f->{'attribute'}->{'clin'}->{'Clin_variant_display_name'})},
                clin_disease_interpret         => sub {$_->set_text($f->{'attribute'}->{'clin'}->{'Clin_disease_interpret'})},
                clin_drug_metabolism_interpret => sub {$_->set_text($f->{'attribute'}->{'clin'}->{'Clin_drug_metabolism_interpret'})},
                clin_drug_efficacy_interpret   => sub {$_->set_text($f->{'attribute'}->{'clin'}->{'Clin_drug_efficacy_interpret'})},
            },
        );
        $twig->parsefile($self->get_xmlTemp);
        $twig->flush($fh);
    }
}

#-----------------------------------------------------------------------------

sub completeXML {
    my $self = shift;

    my $basename = basename($self->get_file, ".gvf");
    
    my $xmlFH  = IO::File->new('temp.xml', 'r') || die "XML temp file not found\n";
    my $xmlNEW = IO::File->new("$basename.xml", 'a+');
    
    print $xmlNEW '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE GVFClin SYSTEM "GVFClin.dtd">
<?xml-stylesheet type="text/xsl" href="GVFClin"?>
<GVFClin>';
    
    while( <$xmlFH> ) {
        print $xmlNEW $_;
    }
    print $xmlNEW "\n</GVFClin>\n";

    # remove the temp file
    `rm temp.xml`;
    
    $xmlFH->close;
    $xmlNEW->close;
}

#-----------------------------------------------------------------------------



1;
