package GVF::Parser;
use Moose;
use Carp;
use IO::File;

extends 'GVF::Clin';

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
    #my ( $self, $request, $drug_info ) = @_;
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
    
    #return(\@drugs) if $drug_info;
    
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

sub pharmGKB_drugs {
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
    
    if ($request eq 'populate') { $self->_populate_drug_info; }
    return (\@drug_file) if $request eq 'parse'; 

    $drugs_fh->close;
}

#------------------------------------------------------------------------------

sub omim {
    
    my ( $self, $request ) = @_;
        
    # uses the relationship file to collect disease information 
    my $omim_file = $self->get_directory . "/" . 'OMIM' . "/" . "??????";
    my $omim_fh   = IO::File->new($omim_file, 'r') || die "Can not open OMIM/???? file\n";
    
    my @omim_file; 
    foreach my $lines ( <$omim_fh> ){
        chomp $lines;
    
    
    
    
    }
    
    
    $omim_fh->close;
}










1;