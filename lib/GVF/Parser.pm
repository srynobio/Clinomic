package GVF::Parser;
use Moose::Role;
use Carp;
use IO::File;


use Data::Dumper;

#------------------------------------------------------------------------------
#----------------------------- Methods ----------------------------------------
#------------------------------------------------------------------------------

# make a collection of genes from NCBI limited by HGNC.

sub genes {
     my $self = shift;
    
    my $ncbi = $self->ncbi_gene;
    my $hgnc = $self->hgnc;
    
    # combine the two set based on matching symbols.
    my $match = $self->match_builder($hgnc, $ncbi, 'gene');    

    $self->_populate_genes($match);
}

#------------------------------------------------------------------------------

sub ncbi_gene {
    
    my $self = shift;    

    # uses the relationship file to collect ncbi_gene information 
    my $ncbi_file = $self->get_directory . "/" . 'NCBI_Gene' . "/" . "gene_info";
    my $ncbi_fh   = IO::File->new($ncbi_file, 'r') || die "Can not open NCBI_Gene/gene_info file\n";

    my @ncbi_list;
    foreach my $line ( <$ncbi_fh> ){
        chomp $line;
        next if $line =~ /^#/;
        
        my @ncbi = split /\t/, $line;
        
        # this allow user to only build on known human gene symbols.
        unless ( $ncbi[0] =~ /\b9606\b/ ) { next }
        
        my $ncbi = {
            gene_id  => $ncbi[1], 
            symbol   => uc($ncbi[2]),
            location => $ncbi[7], 
            dbxref   => $ncbi[5],
        };
        push @ncbi_list, $ncbi;        
    }
    $ncbi_fh->close;

    return (\@ncbi_list);
}

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
        my ( $hgnc_id, $symbol, $name, $chromo, $acc_numb, $pubmed, $refseqid, $omim, undef ) = split /\t/, $line;
 
        my $hgnc = {
            hgnc_id   => $hgnc_id,
            symbol    => $symbol,
            name      => $name,
            chromo    => $chromo,
            acc_num   => $acc_numb,
            pubmed_id => $pubmed,
            refseq    => $refseqid, 
            omim      => $omim,
        };
        push @hgnc_list, $hgnc;        
    }
    $hgnc_fh->close;
    
    return(\@hgnc_list);
}

#------------------------------------------------------------------------------

sub gene_relationship {
    my $self = shift;
    
    # uses the relationship file to collect gene_relationship information 
    my $gene_relationship_file = $self->get_directory . "/" . 'NCBI_Gene' . "/" . "gene_group";
    my $gene_relationship_fh   = IO::File->new($gene_relationship_file, 'r') || die "Can not open NCBI_Gene/gene_group file\n";

    my @gene_relation_list;
    foreach my $line ( <$gene_relationship_fh> ){
        chomp $line;
        
        next if $line =~ /^#/;
        my @rel = split /\t/, $line;   
     
        # this allow user to only build on known human gene symbols.
        unless ( $rel[0] =~ /\b9606\b/ ) { next }
       
        # but not with that women.
        my $relations = {
            gene_id       => $rel[1], 
            relationship  => $rel[2], 
            other_gene_id => $rel[4],
        };
        push @gene_relation_list, $relations;       
    }
    $gene_relationship_fh->close;
    
    $self->_populate_gene_relation(\@gene_relation_list);
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
        
        my $gene_asso = {
            symbol  => $list[8],
            disease => $list[5],
            pubmed  => $list[13],
        };
        push @gene_asso, $gene_asso;
    }
    $genetic_assos_fh->close;
    
    $self->_populate_genetic_assoc(\@gene_asso);
}

#------------------------------------------------------------------------------

sub clinvar_gene {
    my $self = shift;
        
    # uses the file to collect clinvar information 
    my $clinvar_file = $self->get_directory . "/" . 'ClinVar' . "/" . "gene_condition_source_id";
    my $clinvar_fh   = IO::File->new($clinvar_file, 'r') || die "Can not open ClinVar/gene_condition_source_id file\n";
    
    my @clinvar_list;
    foreach my $line ( <$clinvar_fh> ){
        chomp $line;
    
        my ( $gene_id, $symbol, $concept, $name, $source, $source_id, $mim ) = split /\t/, $line;
        next if ! $symbol;    
    
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
    
    $self->_populate_clinvar_gene(\@clinvar_list);
}

#------------------------------------------------------------------------------

sub clinvar_hgmd {
    my $self = shift;
        
    # uses the file to collect clinvar information 
    my $clinvar_file = $self->get_directory . "/" . 'ClinVar' . "/" . "clinvar_hgmd.txt";
    my $clinvar_fh   = IO::File->new($clinvar_file, 'r') || die "Can not open ClinVar/clinvar_hgmd.txt file\n";
    
    my @hgmd_list;
    foreach my $line ( <$clinvar_fh> ){
        chomp $line;
    
        my ( $hgmd_id, $symbol, $chr, $location, $type, undef, $rs ) = split /\t/, $line;
        next if ! $symbol;    

        # change types to SO terms.
        if ( $type ){
            $type =~ s/D/deleation/;
            $type =~ s/I/insertion/;
            $type =~ s/M/complex_substitution/;
            $type =~ s/R/regulatory_region/;
            $type =~ s/S/substitution/;
            $type =~ s/X/indel/;
        }

        my $hgmd_file = {
            symbol     => $symbol,
            chromosome => $chr,
            location   => $location,
            so_feature => $type,
            rs_id      => $rs,
        };
        push @hgmd_list, $hgmd_file;
    }
    $clinvar_fh->close;
    
    $self->_populate_clinvar_hgmd(\@hgmd_list);
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
                hgnc   => $hgnc,
            };
            push @dbank, $drug;
        }
        else { next }
    }
    $drug_fh->close;
    
    $self->_populate_drug_info(\@dbank);
}

#------------------------------------------------------------------------------

sub rsid {

   my $self = shift;
        
    # uses the relationship file to collect rsid information 
    my $rsid_file = $self->get_directory . "/" . 'HuGE' . "/" . "Mapper.txt";
    my $rsid_fh   = IO::File->new($rsid_file, 'r') || die "Can not open HuGE/Mapper.txt file\n";
    
    my @rsid;
    foreach my $line ( <$rsid_fh> ){
        chomp $line;
        
        my ( $common, $rs, $symbol, $url, $source ) = split /\t/, $line;
        
        next if ! $symbol;
        next if ! $rs =~ /^rs/;
        $source =~ s/\s// if $source;

        my $mapped = {
            rsid        => $rs,
            #common_name => $common,
            symbol      => $symbol,
            source      => $source,
        };
        push @rsid, $mapped;
    }
    $rsid_fh->close;
    
    $self->_populate_rsid(\@rsid);
}

#------------------------------------------------------------------------------

sub gene2refseq {
    
    my $self = shift;
    
    # uses the relationship file to collect refseq information 
    my $ref_file = $self->get_directory . "/" . 'NCBI_Gene' . "/" . "gene2refseq";
    my $ref_fh   = IO::File->new($ref_file, 'r') || die "Can not open NCBI_Gene/gene2refseq file\n";
    
    my @refseq;
    foreach my $line ( <$ref_fh> ){
        chomp $line;
        
        next if $line =~ /^#/;
        
        my @refs = split /\t/, $line;
        
        unless ( $refs[0] =~ /\b9606\b/ ) { next }
        unless ( $refs[3] =~ /^NM_(.*)/ ) { next } 
        
        my $refhash = {
            gene_id     => $refs[1],
            rna_acc     => $refs[3],
            rna_gi      => $refs[4],
            start       => $refs[9],
            end         => $refs[10],
        };
        push @refseq, $refhash;
    }
    $ref_fh->close;

    $self->_populate_refseq(\@refseq);     
}

#------------------------------------------------------------------------------

# this method will be saved to offer support to users who want to use OMIM data.

sub omim {
    
    my $self = shift;
        
    # uses the relationship file to collect omim information 
    my $omim_file = $self->get_directory . "/" . 'OMIM' . "/" . "genemap";
    my $omim_fh   = IO::File->new($omim_file, 'r') || die "Can not open OMIM/genemap file\n";
    
    my @omim_list;
    foreach my $line ( <$omim_fh> ){
        chomp $line;
        
        my @omim = split /|/, $line;
        
        # just want the first symbol it's HGNC.
        $omim[5] =~ /^(\w+),?(.*)$/;
        
        
        my $omim = {
            cyto     => $omim[4], 
            status   => $omim[6], 
            disease  => $omim[7], 
            omim_num => $omim[10],
            symbol   => uc($1),
        };
        push @omim_list, $omim;        
    }
    $omim_fh->close;

    $self->_populate_omim_info(\@omim_list);
}

#------------------------------------------------------------------------------

sub gwas {

    my $self = shift;
        
    # uses the relationship file to collect gwas information 
    my $gwas_file = $self->get_directory . "/" . 'HuGE' . "/" . "GWAS.txt";
    my $gwas_fh   = IO::File->new($gwas_file, 'r') || die "Can not open HuGE/GWAS.txt file\n";
    
    my @gwas_list;
    foreach my $line ( <$gwas_fh> ){
        chomp $line;
    
        my ( $rs, $gene, $region, $trait, undef, $journal, undef, $pubmedId, undef, $alleleRisk, undef ) = split /\t/, $line;
        
        # clean up
        if ( ! $rs ) { next }
        if ( $rs !~ /^rs/ ) { next }
        if ( $rs =~ /\,/ ) { next }
        $rs =~ /^(rs\d+)\(.*\)/;
        my $rsid = $1;

        $alleleRisk =~ /rs(\d+)-(\S)\[(.*)\]$/;
        my $allele = $2;
        my $risk   = $3;
 
        my $gwas = {
            rsid        => $rsid,
            trait       => $trait,
            symbol      => $gene,
            gene_region => $region,
            journal     => $journal,
            pubmed_id   => $pubmedId,
            allele      => $allele,
            risk        => $risk,
        };
        push @gwas_list, $gwas;
    }
    $gwas_fh->close;
       
    $self->_populate_gwas(\@gwas_list);
}

#------------------------------------------------------------------------------




1;

__END__


sub pharmGKB_gene {

    my ( $self, $request ) = @_;
    
    if (! $request ) { croak "please add request\n";}
    
    my $gene_file = $self->get_directory . "/" . 'PharmGKB' . "/" . "genes.tsv";
    my $gene_fh   = IO::File->new($gene_file, 'r') || die "Can not open PharmGKB/gene.tsv file\n";

    my @pharm_gene;
    foreach my $lines ( <$gene_fh> ){
        chomp $lines;
        
        if ( $lines =~ /^PharmGKB/) { next }

        my ( $pharm_acc_id, $entz_id, $enseb_id, $name, $symbol, $alt_name, $alt_symbol, $vip, $variant_annotation, $references )
            = split /\t/, $lines;

        my $pharm_data = {
            pharm_id  => $pharm_acc_id,
            gene_name => $symbol,
            gene_info => $references,
        };
        push @pharm_gene, $pharm_data;
    }
    # send data to populate the database
    $self->_populate_pharmgkb_gene(\@pharm_gene) if $request eq 'populate';
    return (\@pharm_gene) if $request eq 'parse';
    
    $gene_fh->close;
}

#------------------------------------------------------------------------------

sub pharmGKB_disease {

    my ( $self, $request ) = @_;
    
    if (! $request ) { croak "please add request\n";}

    # uses the relationship file to collect disease information 
    my $relationship_file = $self->get_directory . "/" . 'PharmGKB' . "/" . "relationships.tsv";
    my $relationship_fh   = IO::File->new($relationship_file, 'r') || die "Can not open PharmGKB/relationships.tsv file\n";
    
    my (@pharm_relationships, @drugs); 
    foreach my $lines ( <$relationship_fh> ){
        chomp $lines;
    
        if ( $lines =~ /^Entity1_id/) { next }
    
        my ( $entity1_id, $entity1_name, $entity2_id, $entity2_name, $evidence, $evidence_source, $pharmdym, $pharmkin )
            = split /\t/, $lines;
        
        # grab gene id, not name
        $entity1_id =~ /(Gene)\:(.*)$/g;
        my $gene_id = $2;       
        
        if (! $gene_id ) { next }
        
        # send non disease data to attribute to use later   
        if ( $entity2_id !~ /Disease:/ ){
            my $drug = join('-', $entity2_id, $evidence, $gene_id, $entity2_name );
            push @drugs, $drug if $entity2_id =~ /Drug:/;
            next;
        }
        
        # just grab the id
        $entity2_id =~ /(Disease)\:(.*)$/g;
        my $disease_id = $2;
        
        my $pharm_disease = {
            gene_id           => $gene_id,
            disease_id        => $disease_id,
            disease_name      => $entity2_name,
            gene_disease_evid => $evidence,
        };
        push @pharm_relationships, $pharm_disease;
    }
    # send data to populate the database
    $self->_populate_pharmgkb_disease(\@pharm_relationships) if $request eq 'populate';

    # send drug arrayref to use in drug db
    $self->_pharmGKB_drug_genes(\@drugs, 'populate') if $request eq 'populate';
    
    # or return if just want parsed data.
    return(\@pharm_relationships) if $request eq 'parse';
    
    $relationship_fh->close;    
}

#------------------------------------------------------------------------------

# This method can only be used if pharmGKB_disease has been called first.

sub _pharmGKB_drug_genes {

    my ( $self, $data, $request ) = @_;
    
    if (! $request ) { croak "please add request\n";}

    my @drug_train;
    foreach my $e ( @{$data} ) {
        my ( $id, $evidence, $gene_id, $drug_name ) = split /-/, $e;
        
        $id =~ /(Drug:)(.*)/g;
        
        my $drugs = {
            drug_id        => $2,
            gene_drug_evid => $evidence,
            drug_name      => $drug_name,
            gene_id        => $gene_id,
        };
        push @drug_train, $drugs;
    }
    $self->_populate_pharmgkb_drug(\@drug_train) if $request eq 'populate';
}

#------------------------------------------------------------------------------

sub pharmGKB_drug_info {

    my ( $self, $request ) = @_;
    
    if (! $request ) { croak "please add request\n";}

    # uses the relationship file to collect disease information 
    my $drugs_file = $self->get_directory . "/" . 'PharmGKB' . "/" . "drugs.tsv";
    my $drugs_fh   = IO::File->new($drugs_file, 'r') || die "Can not open PharmGKB/drugs.tsv file\n";
    
    my @drug_file; 
    foreach my $lines ( <$drugs_fh> ){
        chomp $lines;
    
        if ( $lines =~ /^PharmGKB/) { next }
        my ( $drug_id, $drug_name, undef, undef, undef, $type, $reference, undef, undef )
            = split /\t/, $lines;
    
        my $drugs = {
            drug_id   => $drug_id,
            drug_name => $drug_name,
            drug_info => $reference,
        };
        push @drug_file, $drugs;
    }
    
    #if ($request eq 'populate') { croak "Method pharmGKB_drugs is not used to populate a database, only parse\n"; }
    
    if ($request eq 'populate') { $self->_populate_drug_info(\@drug_file); }
    return (\@drug_file) if $request eq 'parse'; 

    $drugs_fh->close;
}

#------------------------------------------------------------------------------


#------------------------------------------------------------------------------

#------------------------------------------------------------------------------

#sub _build_feature_lines {
#    
#    my ( $self, $data ) = @_;
#    my $feature_line = $self->_file_splitter('feature');
#    
#    my ( @return_list );
#    foreach my $lines( @$feature_line ) {
#        chomp $lines;
#        
#        my ($seq_id, $source, $type, $start, $end, $score, $strand, $phase, $attribute) = split(/\t/, $lines);
#        my @attributes_list = split(/\;/, $attribute);
#
#        my %atts;
#        foreach my $attributes (@attributes_list) {
#            $attributes =~ /(.*)=(.*)/g;
#            $atts{$1} = $2;
#        }
#        
#        my $feature = {
#            seqid  => $seq_id,
#            source => $source,
#            type   => $type,
#            start  => $start,
#            end    => $end,
#            score  => $score,
#            strand => $strand,
#            phase  => $phase,
#            attribute => {
#                %atts
#            },
#        };
#        push @return_list, $feature;
#    }
#
#    # check if gvf file matches reference build.
#    #my $per_correct = $self->gvf_valadate(\@return_list);
#    #if ( $per_correct <=  80 ) {
#    #    die "The reference sequences match less than 80% ($per_correct), file will not be added to database\n";
#    #}
#    #else {
#    #    $self->_populate_gvf_data(\@return_list);
#    #}
#    #
# 
#    $self->_populate_gvf_data(\@return_list);
#}

#------------------------------------------------------------------------------
        
        
        
        
        
        
        
1;