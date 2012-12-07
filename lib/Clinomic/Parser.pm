package Clinomic::Parser;
use Moose::Role;
use Carp;
use namespace::autoclean;
use IO::File;

use Data::Dumper;

#------------------------------------------------------------------------------
#----------------------------- Methods ----------------------------------------
#------------------------------------------------------------------------------

sub hgnc {
    my $self = shift;
    
    # uses the relationship file to collect hgnc_gene information 
    my $hgnc_file = $self->get_directory . "/" . 'HGNC' . "/" . "HGNC_data";
    my $hgnc_fh   = IO::File->new($hgnc_file, 'r') || die "Can not open HGNC/HGNC_data file\n";

    my @hgnc_list;
    foreach my $line ( <$hgnc_fh> ){
        chomp $line;
        
        next if $line !~ /^HGNC:(\d+)/;
        my ( undef, $symbol, $name, $chromo, $acc_numb, $pubmed, $refseqid, $omim, $refseq ) = split /\t/, $line;
        
        if ( ! $symbol ){ next }
        
        my $hgnc = {
            symbol  => $symbol,
            chromo  => $chromo,
        };
        push @hgnc_list, $hgnc;
    }
    $hgnc_fh->close;
    $self->_populate_genes(\@hgnc_list);
}

#------------------------------------------------------------------------------

#sub drug_bank {
#    my $self = shift;
#        
#    # uses the relationship file to collect drug information
#    # better then contacting your dealer.
#    my $drug_file = $self->get_directory . "/" . 'Drug_Bank' . "/" . "drugbank.txt";
#    my $drug_fh   = IO::File->new($drug_file, 'r') || die "Can not open Drug_Bank/drugbank.txt file\n";
#    
#    local $/ = '#';
#    my ( $drug, $target, $hgnc, @dbank );
#    
#    foreach my $line ( <$drug_fh> ){
#        chomp $line;
#    
#        $line =~ s/\n//g;
#        $line =~ s/^\s//g;
#        
#        if ( $line =~ /^Generic_Name:(.*)/ ) {
#            $drug = $1;
#        }
#        elsif ( $line =~ /^Drug_Target_1_Gene_Name:(.*)/ ) {
#            $target = $1;
#        }
#        elsif ( $line =~ /^Drug_Target_1_HGNC_ID:(.*)/ ) {
#            $hgnc = $1;
#    
#            my $drug = {
#                drug   => $drug,
#                symbol => $target,
#            };
#            push @dbank, $drug;
#        }
#        else { next }
#    }
#    $drug_fh->close;
#    $self->_populate_drug_info(\@dbank);
#}

#------------------------------------------------------------------------------

sub refseq {
    my $self = shift;
    
    # uses the relationship file to collect refseq information 
    my $ref_file = $self->get_directory . "/" . 'NCBI' . "/" . "UpdatedRefSeq.txt";
    my $ref_fh   = IO::File->new($ref_file, 'r') || die "Can not open NCBI/UpdatedRefSeq.txt file\n";
    
    my @refseq;
    foreach my $line ( <$ref_fh> ){
        chomp $line;
        
        next if $line =~ /^#/;
        
        my @refs = split /\t/, $line;
        
        # exclude unwanted data
        unless ( $refs[7] =~ /^NC_(.*)$/ ) { next }
        unless ( $refs[12] =~ /Reference GRCh37.p10/ ) { next }
        unless ( $refs[5] =~ /^AP_(.*)$/ || $refs[5] =~ /^NP_(.*)$/) { next }
        
        my $refhash = {
            symbol        => $refs[1],
            transcript_id => $refs[3],
            prot_acc      => $refs[5],
            genomic_acc   => $refs[7],
            start         => $refs[9],
            end           => $refs[10],
        };
        push @refseq, $refhash;
    }
    $ref_fh->close;
    $self->_populate_refseq(\@refseq);    
}

#------------------------------------------------------------------------------

no Moose;
1;
