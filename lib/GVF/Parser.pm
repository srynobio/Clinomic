package GVF::Parser;
use Moose::Role;
use Carp;
use IO::File;


use Data::Dumper;

#------------------------------------------------------------------------------
#----------------------------- Methods ----------------------------------------
#------------------------------------------------------------------------------

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

sub omim {
    
    my ( $self, $request ) = @_;
        
    # uses the relationship file to collect disease information 
    my $omim_file = $self->get_directory . "/" . 'OMIM' . "/" . "genemap";
    my $omim_fh   = IO::File->new($omim_file, 'r') || die "Can not open OMIM/genemap file\n";
    
    my ( %mim_rec, @info_list );
    foreach my $line ( <$omim_fh> ){
        chomp $line;
        
        my ( undef, undef, undef, undef, $cyto_location, $symbol, $status, $title, undef, $mim_num, undef)
            = split /\|/, $line;
        
        # split on , and space
        my @genes = split /, /, $symbol;
        $mim_rec{$mim_num} = [@genes];
        
        my $info = {
            cyto     => $cyto_location,
            status   => $status,
            disease  => $title,
            omim_num => $mim_num,
        };
        push @info_list, $info;
    }
    $omim_fh->close;

    return (%mim_rec) if $request eq 'gene';
    $self->_populate_omim_info(\@info_list) if $request eq 'populate';
}

#------------------------------------------------------------------------------

sub rsidgene {

    my ( $self, $request ) = @_;
    
    if (! $request ) { croak "please add request\n";}

    # uses the relationship file to collect disease information 
    my $rsid_file = $self->get_directory . "/" . 'PharmGKB' . "/" . "rsid.tsv";
    my $rsid_fh   = IO::File->new($rsid_file, 'r') || die "Can not open PharmGKB/rsid.tsv file\n";
    
    my %snp;
    foreach my $lines ( <$rsid_fh> ){
        chomp $lines;
        
        if ( $lines !~ /^rs/) { next }
        my ( $rsid, $gene_id, $symbol ) = split /\t/, $lines;
        
        my @genes = split /;/, $symbol;
        
        foreach my $name ( @genes ) {
            $snp{$name} = [] unless exists $snp{$name};
            push ( @{$snp{$name}}, $rsid );
        }
    }

    my %connected;
    while ( my ($key, $value) = each (%snp) ) {
        
        my $rs_values = join(':', @$value);        
        $connected{$key} = $rs_values;        
    }
    $self->_populate_rsid(\%connected) if $request eq 'populate';
    return(\%connected) if $request eq 'parse';
}

#------------------------------------------------------------------------------

sub _build_feature_lines {
    
    my ( $self, $data ) = @_;
    my $feature_line = $self->_file_splitter('feature');
    
    my ( @return_list );
    foreach my $lines( @$feature_line ) {
        chomp $lines;
        
        my ($seq_id, $source, $type, $start, $end, $score, $strand, $phase, $attribute) = split(/\t/, $lines);
        my @attributes_list = split(/\;/, $attribute);

        my %atts;
        foreach my $attributes (@attributes_list) {
            $attributes =~ /(.*)=(.*)/g;
            $atts{$1} = $2;
        }
        
        my $feature = {
            seqid  => $seq_id,
            source => $source,
            type   => $type,
            start  => $start,
            end    => $end,
            score  => $score,
            strand => $strand,
            phase  => $phase,
            attribute => {
                %atts
            },
        };
        push @return_list, $feature;
    }

    my $per_correct = $self->gvf_valadate(\@return_list);
    if ( $per_correct <=  80 ) { die "your file sucks\n";}
    print $per_correct, "\n";
    # send all data to populate db
    #$self->_populate_gvf_data(\@return_list);
}

#------------------------------------------------------------------------------

sub refgene {
    
    my ( $self, $request ) = @_;
        
    # uses the relationship file to collect disease information 
    my $ref_file = $self->get_directory . "/" . 'UCSC' . "/" . "refGene.txt";
    my $ref_fh   = IO::File->new($ref_file, 'r') || die "Can not open UCSC/refGene.txt file\n";
    
    my ( @mylist, %ref );
    foreach my $line ( <$ref_fh> ){
        chomp $line;
        
        my ( $bin, $name, $chrom, $strand, $txstart, $txend, undef, undef, undef, undef, undef, $score, $name2, undef)
            = split (/\t/, $line);

        $ref{$chrom} = {
            symbol => $name2,
            start  => $txstart,
            end    => $txend,
        };
        #push @mylist, $list;
    }
    
    # ???????????
    
    #my @new = sort { $a cmp $b }@mylist;
    #my @new = sort { $ref{$a} cmp $ref{$b} } keys %ref;
    #print Dumper(@new);
}
        
#------------------------------------------------------------------------------
        
        
        
        
        
        
        
1;