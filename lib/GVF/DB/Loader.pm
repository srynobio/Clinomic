package GVF::DB::MySQL;
use Moose::Role;
use threads;
use Carp;
use GVF::DB::Connect;


use Data::Dumper;
#-----------------------------------------------------------------------------
#------------------------------- Attributes ----------------------------------
#-----------------------------------------------------------------------------

has 'mysql_user' => (
    is       => 'rw',
    isa      => 'HashRef',
    reader   => 'get_mysql_user',
    required => 1,
    trigger  =>\&_mysql_dbx_builder,
);

has 'mysql_dbx_handle' => (
    is      => 'rw',
    isa     => 'Object',
    writer  => 'set_mysql_dbxh',
    reader  => 'dbxh',
   # handles => 'dbxh'
);

has 'build_database' => (
    is         => 'rw',
    isa        => 'Int',
    trigger => \&_build_database,
);


#------------------------------------------------------------------------------
#----------------------------- Methods ----------------------------------------
#------------------------------------------------------------------------------

sub _mysql_dbx_builder {
    my $self = shift;
    
    my $user = $self->get_mysql_user;
    
    my $dbixclass = GVF::DB::Connect->connect( 'dbi:mysql:GVFClin', "$user->{'user'}", "$user->{passwd}" );
    $self->set_mysql_dbxh($dbixclass);
}

#------------------------------------------------------------------------------

sub _build_database {
    
    my $self = shift;

    my $dbxh = $self->dbxh;
    
    my $id     = $dbxh->resultset('Genes')->search;
    my $check   = $id->get_column('id');
    my $max_id = $check->max;
    
    my $threads = $self->threads;
    my @features = qw / clinvar_gene clinvar_hgmd gene_relationship
                        genetic_association drug_bank rsid gene2refseq gwas /;
                        
    if ( ! $max_id ) {
        
        # build gene table first
        print "Building Gene table\n";
        $self->genes;
        
        my @temp_features;    
        for(my $i = 0; $i <= $threads; $i++){
            my $feature = shift @features;
                push @temp_features, $feature;
        }
    
        my $child = $self->fork_threads(\@temp_features);
    
        foreach my $c (@{$child}){
            waitpid($c, 0);
        }
    }
    else { print "\nGVFClin database already exists\n"; }
}

#------------------------------------------------------------------------------

sub _populate_genes {
    my ($self, $genes) = @_;

    my $dbxh = $self->dbxh;
    
    foreach my $i ( @{$genes} ){
         $dbxh->resultset('Genes')->create({
             gene_id       => $i->[0]->{'gene_id'},
             symbol        => $i->[0]->{'symbol'},
             location      => $i->[0]->{'location'},
             dbxref        => $i->[0]->{'dbxref'},
             refseq_id     => $i->[1],
             name          => $i->[2],
             hgnc_id       => $i->[3],
             accession_num => $i->[4],
             omim          => $i->[5],
         });
    }
}

#------------------------------------------------------------------------------

sub _populate_gene_relation {
    my ($self, $relation) = @_;

    my $dbxh = $self->dbxh;    
    
    # capture list of gene_id's
    my $gene_id = $dbxh->resultset('Genes')->search (
        undef, { columns => [qw/ gene_id id /], }
    );
    
    my @ids;
    while ( my $result = $gene_id->next ){
        my $list = {
            gene_id => $result->gene_id,
            id      => $result->id,
        };
        push @ids, $list; 
    }
    
    my $match = $self->match_builder($relation, \@ids, 'relation');

    foreach my $i ( @{$match} ) {
        $dbxh->resultset('Gene2gene_relationship')->create({
            gene_id       => $i->[0]->{'gene_id'},
            relationship  => $i->[0]->{'relationship'},
            other_gene_id => $i->[0]->{'other_gene_id'},
            Genes_id      => $i->[1],
        });
    }
}

#------------------------------------------------------------------------------

sub _populate_genetic_assoc {
    my ($self, $genetic) = @_;
    
    my $dbxh = $self->dbxh;    
    my $match = $self->simple_match($genetic);    

    foreach my $i ( @{$match} ) {
        $dbxh->resultset('Genetic_association')->create({
            symbol        => $i->[0]->{'symbol'},
            mesh_disease  => $i->[0]->{'disease'},
            pubmed_id     => $i->[0]->{'pubmed'},
            Genes_id      => $i->[1],
        });
    }

=cut
    # use this idea to build a evidence map of pubmed/genes/disease
    
    # capture list of gene_id's
    my $gene_id = $dbxh->resultset('Genetic_association')->search (
        undef, { columns => [qw/ mesh_disease pubmed_id symbol/], }
    );
    
    my @symbols;
    while ( my $result = $gene_id->next ){
        my $list = {
            disease => $result->mesh_disease,
            pubmed  => $result->pubmed_id,
            symbol  => $result->symbol,
        };
        push @symbols, $list; 
    } 

    my %test;
    for my $t (@symbols){
        
        $test{$t->{'disease'}} = [] unless exists $test{$t->{'disease'}};
        
        push @{ $test{$t->{'disease'}} }, $t->{'pubmed'}, $t->{'symbol'};

        
        
    }
    print Dumper(%test);
=cut
}

#------------------------------------------------------------------------------

sub _populate_clinvar_gene {
    my ($self, $clin) = @_;
    
    my $dbxh = $self->dbxh;    
    my $match = $self->simple_match($clin);

    foreach my $i ( @{$match} ) {
        $dbxh->resultset('Clinvar_gene')->create({
            symbol          => $i->[0]->{'symbol'},
            condition_name  => $i->[0]->{'disease'},
            umls_concept_id => $i->[0]->{'umls'},
            source          => $i->[0]->{'source'},
            source_id       => $i->[0]->{'source_id'},
            omim_id         => $i->[0]->{'omim_id'},
            Genes_id        => $i->[1],
        });
    }
}

#------------------------------------------------------------------------------

sub _populate_clinvar_hgmd {
    my ($self, $hgmd) = @_;
    
    my $dbxh = $self->dbxh;    
    my $match = $self->simple_match($hgmd);
   
    foreach my $i ( @{$match} ) {
        $dbxh->resultset('Clinvar_hgmd')->create({
            symbol     => $i->[0]->{'symbol'},
            chromosome => $i->[0]->{'chromosome'},
            location   => $i->[0]->{'location'},
            so_feature => $i->[0]->{'so_feature'},
            rs_id      => $i->[0]->{'rs_id'},
            Genes_id   => $i->[1],
        });
    }
}

#------------------------------------------------------------------------------

sub _populate_drug_info {
    my ($self, $dbank) = @_;
    
    my $dbxh = $self->dbxh;    
    my $match = $self->simple_match($dbank);
   
    foreach my $i ( @{$match} ) {
       $dbxh->resultset('Drug_bank')->create({
            symbol       => $i->[0]->{'symbol'},
            hgnc_id      => $i->[0]->{'hgnc'},
            generic_name => $i->[0]->{'drug'},
            Genes_id     => $i->[1],
        });
    }
}

#------------------------------------------------------------------------------

sub _populate_rsid {
    my ($self, $rsid) = @_;
    
    my $dbxh = $self->dbxh;    
    my $match = $self->simple_match($rsid); 
    
    foreach my $i ( @{$match} ) {
       $dbxh->resultset('Rsid')->create({
            rsid         => $i->[0]->{'rsid'},
            source       => $i->[0]->{'source'},
            symbol       => $i->[0]->{'symbol'},
            Genes_id     => $i->[1],
        });
    }
}

#------------------------------------------------------------------------------

sub _populate_refseq {
    my ($self, $ref) = @_;
    
    my $dbxh = $self->dbxh;
    
    # capture list of gene_id's
    my $gene_id = $dbxh->resultset('Genes')->search (
        undef, { columns => [qw/ gene_id id /], }
    );
    
    my @ids;
    while ( my $result = $gene_id->next ){
        my $list = {
            gene_id => $result->gene_id,
            id      => $result->id,
        };
        push @ids, $list; 
    }

    my $match = $self->match_builder($ref, \@ids, 'relation');

    foreach my $i ( @{$match} ) {
       $dbxh->resultset('Gene2refseq')->create({
            rna_acc_version     => $i->[0]->{'rna_acc'},
            rna_gi              => $i->[0]->{'rna_gi'},
            start               => $i->[0]->{'start'},
            end                 => $i->[0]->{'end'},
            Genes_id            => $i->[1],
        });
    }
}

#------------------------------------------------------------------------------

sub _populate_omim_info {

    my ($self, $omim) = @_;

    my $dbxh = $self->dbxh;
    my $match = $self->simple_match($omim);

    foreach my $i ( @{$match} ) {
       $dbxh->resultset('Omim')->create({
            cytogenetic_location => $i->[0]->{'cyto'},
            omim_disease         => $i->[0]->{'disease'},
            status_code          => $i->[0]->{'status'},
            symbol               => $i->[0]->{'symbol'},
            omim_number          => $i->[0]->{'omim_num'},
            HGNC_id              => $i->[1],
        });
    }
}

#------------------------------------------------------------------------------

sub _populate_gwas {
    
    my ($self, $gwas) = @_;
    
    my $dbxh = $self->dbxh;
    my $match = $self->simple_match($gwas);

    foreach my $i ( @{$match} ) {
       $dbxh->resultset('Gwas')->create({
            rsid        => $i->[0]->{'rsid'}, 
            trait       => $i->[0]->{'trait'},
            symbol      => $i->[0]->{'symbol'},
            gene_region => $i->[0]->{'gene_region'}, 
            journal     => $i->[0]->{'journal'},
            pubmed_id   => $i->[0]->{'pubmed_id'},
            allele      => $i->[0]->{'allele'},
            risk        => $i->[0]->{'risk'},
            Genes_id    => $i->[1],
        });
    }
}

#------------------------------------------------------------------------------

sub _populate_gvf_data {

    my ( $self, $data ) = @_;
    
=cut
    my $dbxh = $self->dbxh;
    
    # make a list of gene names
    my @gene_names = map {
        my $gene = $_->{'attribute'}->{'Variant_effect'};
        $gene =~ m/(\w+)\s+(\d+)\s+(gene)\s+(\w+)/gi;
        $4;
    } @$data;
    
    # capture list of gene names and id's from db
    my $gene_id = $dbxh->resultset('PharmGkbGene')->search(
        undef, { columns => [qw/ id symbol /], }
    );
    
    my @gene_list;
    while ( my $result = $gene_id->next ){
        my $list = {
            gene => $result->symbol,
            id   => $result->id,
        };
        push @gene_list, $list; 
    }    
    
    # genetate a match of gene list and db
    my %gene = $self->match_builder( \@gene_names, \@gene_list, 'gvf' );  
    
    # build db
    foreach my $i ( @{$data} ) {
        chomp $i;
        
        my $variant_effect = $i->{'attribute'}->{'Variant_effect'};
        if ( ! $variant_effect ) { next }
        if ( $variant_effect !~ /(\bgene\b)/ ) { next }
    
        $variant_effect =~ m/(\w+)\s+(\d+)\s+(gene)\s+(\w+)/gi;
    
        
        if ( $gene{$4} ) {
            $dbxh->resultset('Gvf')->create({
                seqid             => $i->{'seqid'},
                source            => $i->{'source'},
                type              => $i->{'type'},
                start             => $i->{'start'},
                end               => $i->{'end'},
                score             => $i->{'score'},
                strand            => $i->{'strand'},                
                attributes_id     => $i->{'attribute'}->{'ID'},
                alias             => $i->{'attribute'}->{'Alias'},
                dbxref            => $i->{'attribute'}->{'Dbxref'},
                variant_seq       => $i->{'attribute'}->{'Variant_seq'},
                reference_seq     => $i->{'attribute'}->{'Reference_seq'},
                variant_reads     => $i->{'attribute'}->{'Variant_reads'},
                total_reads       => $i->{'attribute'}->{'Total_reads'},
                zygosity          => $i->{'attribute'}->{'Zygosity'},
                variant_freq      => $i->{'attribute'}->{'Variant_freq'},
                variant_effect    => $i->{'attribute'}->{'Variant_effect'},
                start_range       => $i->{'attribute'}->{'Start_range'},
                end_range         => $i->{'attribute'}->{'End_range'},
                phased            => $i->{'attribute'}->{'Phased'},
                genotype          => $i->{'attribute'}->{'Genotype'},
                individual        => $i->{'attribute'}->{'Individual'},
                variant_codon     => $i->{'attribute'}->{'Variant_codon'},
                reference_codon   => $i->{'attribute'}->{'Reference_codon'},
                variant_aa        => $i->{'attribute'}->{'Variant_aa'},
                breakpoint_detail => $i->{'attribute'}->{'Breakpoint_detail'},
                sequence_context  => $i->{'attribute'}->{'Sequence_context'},
                PharmGKB_gene_id  => $gene{$4},
            });
        }
    }

=cut
}

#------------------------------------------------------------------------------









1;


