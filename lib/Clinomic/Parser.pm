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
#
#sub genetic_association {
#    my $self = shift;
#    
#    # uses the relationship file to collect genetic association information 
#    my $genetic_assos_file = $self->get_directory . "/" . 'Genetic_Association' . "/" . "all.txt";
#    my $genetic_assos_fh   = IO::File->new($genetic_assos_file, 'r') || die "Can not open Genetic_Association/all.txt file\n";
#
#    my @gene_asso;
#    foreach my $line ( <$genetic_assos_fh> ){
#        chomp $line;
#        next if $line !~ /^\d+/;
#        
#        my @list = split /\t/, $line;
#        
#        # bit of clean up.
#        next if ! $list[5];
#        next if ! $list[8];
#        next if $list[13] !~ /^(\d+)$/;
#
#        my $gene_asso = {
#            symbol    => $list[8],
#            disease   => $list[5],
#            class     => $list[3],
#            pubmed    => $list[13],
#        };
#        push @gene_asso, $gene_asso;
#    }
#    $genetic_assos_fh->close;
#    $self->_populate_genetic_assoc(\@gene_asso);
#}

#------------------------------------------------------------------------------

############
use Data::Dumper;

sub clinvar {
    my ($self, $request) = @_;
        
    # uses the file to collect clinvar information
    my $clinvar_file = $self->get_directory . "/" . 'ClinVar' . "/" . "gene_condition_source_id";
    my $clinvar_fh   = IO::File->new($clinvar_file, 'r') || die "Can not open ClinVar/gene_condition_source_id file\n";
    
    my @clinvar_list;
    foreach my $line ( <$clinvar_fh> ){
        chomp $line;
    
        my ( $gene_id, $symbol, $concept, $name, $source, $source_id, $mim ) = split /\t/, $line;

        # select only SNOMEDCT terms and terms from UMLS. 
        next if ! $symbol;    
        if ( $source =~ /SNOMEDCT/) { next }
        if ( $concept =~ /^CN(\d+)/) { next }
    
        my $var_file = {
            symbol    => $symbol,
            umls      => $concept,
            disease   => $name,
            source    => $source,
            source_id => $source_id,
        };
        push @clinvar_list, $var_file;
    }
    $clinvar_fh->close;
    
    if ($request) { return \@clinvar_list; }
    else { $self->_populate_clinvar(\@clinvar_list); }
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
#
#sub clinInterpret {
#    my $self = shift;
#        
#    # uses the file to collect clinvar information
#    # rename to clin sig file
#    my $clinInt_file = $self->get_directory . "/" . 'ClinVar' . "/" . "clinvar_sigfile.vcf";
#    my $clinInt_fh   = IO::File->new($clinInt_file, 'r') || die "Can not open ClinVar/clinvar_sigfile.vcf file\n";
#    
#    my @clinSig;
#    foreach my $line ( <$clinInt_fh> ){
#        chomp $line;
#    
#        # meta data means nothing to me!
#        if ($line =~ /^#{1,}/){ next }
#        
#        my ($chrom, $pos, $id, $ref, $var, undef, undef, $info) = split /\t/, $line;
#        $chrom =~ s/^/chr/g;
#
#        # grep only what were looking for    
#        my @infoList = split(/\;/, $info);
#        
#        foreach (@infoList){
#            if ( $_ =~ /CLNSIG/ or /CLNDSDB/ or /CLNDSDBID/ ){
#               # print $_, "\n";
#            }
#        }
#
#
#
#
#
#
#
#        ##################
#        my @clinList = grep { $_ =~ /CLNDSDBID/ || /CLNHGVS/ || /CLNSIG/ || /GENEINFO/ }@infoList;
#        
#        # split up the clin data        
#        my %atts;
#        foreach my $i (@clinList) {
#            
#             $i =~ /^(.*)=(.*)/g;
#             my $tag   = $1;
#             my $value = $2;
#             
#             #####print "$tag\n"; #$value\n";
#             
#             if ($tag eq 'GENEINFO'){
#                my ($gene, undef) = split/:/, $value;
#                $value = $gene;
#             }
#             ####################################
#             #elsif ($tag eq 'CLNDSDBID'){
#                #print "$tag\t$value\t"; 
#             #}
#             ####################################
#             elsif ($tag eq 'CLNDSDB'){
#                #print "$tag\t$value\n"; 
#             }
#                         
#             
#             
#             $atts{$tag} = $value;
#        }
#        # hashref of parts.
#        my $t = {
#            chr       => $chrom,
#            pos       => $pos,
#            rsid      => $id,
#            ref_seq   => $ref,
#            var_seq   => $var,
#            clin_data => \%atts,
#        };
#        push @clinSig, $t;
#    }
#    
#    $clinInt_fh->close;
#    $self->_populate_clinInterpret(\@clinSig);
#}

#------------------------------------------------------------------------------

no Moose;
1;
