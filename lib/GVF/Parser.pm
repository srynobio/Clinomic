package GVF::Parser;
use Moose::Role;
use Carp;
use namespace::autoclean;
use IO::File;

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
        
        next if $line =~ /^HGNC\s+ID/;
        my ( undef, $symbol, $name, $chromo, $acc_numb, $pubmed, $refseqid, $omim, $refseq ) = split /\t/, $line;
 
        if ( ! $symbol ){ next }
        if ( ! $refseqid ) { next }
        
        my $hgnc = {
            symbol  => $symbol,
            chromo  => $chromo,
            omim_id => $omim,
            refseq  => $refseqid, 
        };
        push @hgnc_list, $hgnc;
    }
    $hgnc_fh->close;
    $self->_populate_genes(\@hgnc_list);
}

#------------------------------------------------------------------------------

sub genetic_association {
    my $self = shift;
    
    # uses the relationship file to collect genetic association information 
    my $genetic_assos_file = $self->get_directory . "/" . 'Genetic_Association' . "/" . "all.txt";
    my $genetic_assos_fh   = IO::File->new($genetic_assos_file, 'r') || die "Can not open Genetic_Association/all.txt file\n";

    my @gene_asso;
    foreach my $line ( <$genetic_assos_fh> ){
        chomp $line;
        next if $line !~ /^\d+/;
        
        my @list = split /\t/, $line;
        
        # bit of clean up.
        next if ! $list[5];
        next if ! $list[8];
        next if $list[13] !~ /^(\d+)$/;

        my $gene_asso = {
            symbol    => $list[8],
            disease   => $list[5],
            class     => $list[3],
            pubmed    => $list[13],
        };
        push @gene_asso, $gene_asso;
    }
    $genetic_assos_fh->close;
    
    $self->_populate_genetic_assoc(\@gene_asso);
}

#------------------------------------------------------------------------------

sub clinvar {
    my $self = shift;
        
    # uses the file to collect clinvar information 
    my $clinvar_file = $self->get_directory . "/" . 'ClinVar' . "/" . "gene_condition_source_id";
    my $clinvar_fh   = IO::File->new($clinvar_file, 'r') || die "Can not open ClinVar/gene_condition_source_id file\n";
    
    my @clinvar_list;
    foreach my $line ( <$clinvar_fh> ){
        chomp $line;
    
        my ( $gene_id, $symbol, $concept, $name, $source, $source_id, $mim ) = split /\t/, $line;
    
        # some clean up and checking
        next if ! $symbol;    
        if ( $source ne 'SNOMEDCT') { next }
    
        my $var_file = {
            symbol    => $symbol,
            umls      => $concept,
            disease   => $name,
            source    => $source,
            source_id => $source_id,
            omim_id   => $mim,
        };
        push @clinvar_list, $var_file;
    }
    $clinvar_fh->close;
    
    $self->_populate_clinvar(\@clinvar_list);
}

#------------------------------------------------------------------------------

sub drug_bank {
    my $self = shift;
        
    # uses the relationship file to collect drug information
    # better then contacting your dealer.
    my $drug_file = $self->get_directory . "/" . 'Drug_Bank' . "/" . "drugbank.txt";
    my $drug_fh   = IO::File->new($drug_file, 'r') || die "Can not open Drug_Bank/drugbank.txt file\n";

    $/ = '#';
    my ( $drug, $target, $hgnc, @dbank );
    
    foreach my $line ( <$drug_fh> ){
        chomp $line;

        $line =~ s/\n//g;
        $line =~ s/^\s//g;
        
        if ( $line =~ /^Generic_Name:(.*)/ ) {
            $drug = $1;
        }
        elsif ( $line =~ /^Drug_Target_1_Gene_Name:(.*)/ ) {
            $target = $1;
        }
        elsif ( $line =~ /^Drug_Target_1_HGNC_ID:(.*)/ ) {
            $hgnc = $1;

            my $drug = {
                drug   => $drug,
                symbol => $target,
            };
            push @dbank, $drug;
        }
        else { next }
    }
    $drug_fh->close;
    
    $self->_populate_drug_info(\@dbank);
}

#------------------------------------------------------------------------------

sub refseq {
    my $self = shift;
    
    my $xcl = $self->get_dbixclass;
    
    # uses the relationship file to collect refseq information 
    my $ref_file = $self->get_directory . "/" . 'NCBI_Gene' . "/" . "UpdatedRefSeq.txt";
    my $ref_fh   = IO::File->new($ref_file, 'r') || die "Can not open NCBI_Gene/UpdatedRefSeq.txt file\n";
    
    my @refseq;
    foreach my $line ( <$ref_fh> ){
        chomp $line;
        
        next if $line =~ /^#/;
        
        my @refs = split /\t/, $line;
        
        #unless ( $refs[7] =~ /^NC_(.*)$/ || $refs[7] =~ /^AC_(.*)$/) { next }
        unless ( $refs[7] =~ /^NC_(.*)$/ ) { next }
        unless ( $refs[5] =~ /^AP_(.*)$/ || $refs[5] =~ /^NP_(.*)$/) { next }
        
        my $refhash = {
            symbol => $refs[1],
            rna_acc     => $refs[3],
            prot_acc    => $refs[5],
            genomic_acc => $refs[7],
        };
        push @refseq, $refhash;
    }
    $ref_fh->close;
    
    $self->_populate_refseq(\@refseq);    
}

#------------------------------------------------------------------------------


1;
