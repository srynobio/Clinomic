package GVF::DB::Loader;
use Moose::Role;
use Carp;
use GVF::DB::Connect;

#-----------------------------------------------------------------------------
#------------------------------- Attributes ----------------------------------
#-----------------------------------------------------------------------------

has 'build_database' => (
    is         => 'rw',
    isa        => 'Int',
    trigger => \&_build_database,
);

has 'dbh' => (
    is         => 'rw',
    isa        => 'Object',
    writer     => 'set_dbh',
    reader     => 'dbh',
    lazy_build => 1,
);

has 'dbixclass' => (
    is         => 'rw',
    isa	       => 'Object',
    reader     => 'dbixclass',
    writer     => 'set_dbixclass',
    reader     => 'get_dbixclass',
    lazy_build => 1,
);

#------------------------------------------------------------------------------
#----------------------------- Methods ----------------------------------------
#------------------------------------------------------------------------------

sub _build_dbh {

    my $self = shift;
    
    my $dbh;

    if ( -f '../data/GVFClin.db' ){
        die "GVFClin database already exists\n";
        $dbh = GVF::DB::Connect->connect('dbi:SQLite:../data/GVFClin.db');
    }
    else {
        system("sqlite3 ../data/GVFClin.db < ../data/mysql/GVFClinLite.sql");
        $dbh = GVF::DB::Connect->connect('dbi:SQLite:../data/GVFClin.db');
    }
    $self->set_dbh($dbh);
}

#-----------------------------------------------------------------------------

sub _build_dbixclass {
  
    my $self = shift;
    my $dbixclass = GVF::DB::Connect->connect("dbi:SQLite:../data/GVFClin.db");

    $self->set_dbixclass($dbixclass);
}

#------------------------------------------------------------------------------

sub _build_database {

    my $self = shift;
    my $dbh = $self->dbh;
    
    warn "Building Database\n";
    $self->hgnc;
    $self->refseq;
    $self->clinvar_hgmd;
    $self->genetic_association;
    $self->clinvar;
    $self->drug_bank;
}

#------------------------------------------------------------------------------

sub _populate_genes {
    my ($self, $genes) = @_;
    
    my $xcl = $self->get_dbixclass;
    
    foreach my $i ( @{$genes} ){
         $xcl->resultset('Hgnc_gene')->create({
             symbol            => $i->{'symbol'},
             name              => $i->{'name'},
             chromosome        => $i->{'chromo'},
             omim_id           => $i->{'omim_id'},
             transcript_refseq => $i->{'refseq'},
         });
    }
}

#------------------------------------------------------------------------------

sub _populate_refseq {

    my ($self, $ref) = @_;

    my $xcl = $self->get_dbixclass;

    # capture list of gene_id's
    my $trans_id = $xcl->resultset('Hgnc_gene')->search (
        undef, { columns => [qw/ transcript_refseq id /] }, 
    );

    my @transcript;
    while ( my $result = $trans_id->next ){
        my $list = {
            trans => $result->transcript_refseq,
            id    => $result->id,
        };
        push @transcript, $list; 
    }
    my $match = $self->match_builder($ref, \@transcript, 'refseq');

    foreach my $i ( @{$match} ) {
        $xcl->resultset('Refseq')->create({
            position       => $i->[0]->{'position'},
            genomic_refseq => $i->[0]->{'genomic_acc'},
            protein_refseq => $i->[0]->{'prot_acc'},
            hgnc_gene_id   => $i->[1],
        });
    }
}

#------------------------------------------------------------------------------

sub _populate_genetic_assoc {
    my ($self, $genetic) = @_;

    my $xcl = $self->get_dbixclass;
    my $match = $self->simple_match($genetic);    

    foreach my $i ( @{$match} ) {
        $xcl->resultset('Genetic_association')->create({
            symbol        => $i->[0]->{'symbol'},
            mesh_disease  => $i->[0]->{'disease'},
            disease_class => $i->[0]->{'class'},
            pubmed_id     => $i->[0]->{'pubmed'},
            hgnc_gene_id  => $i->[1],
        });
    }
}

#------------------------------------------------------------------------------

sub _populate_clinvar {
    my ($self, $clin) = @_;
    
    my $xcl = $self->get_dbixclass;
    
    # capture list of gene_id's
    my $gene_id = $xcl->resultset('Genetic_association')->search (
        undef, { columns => [qw/ symbol id /] }, 
    );

    my @symbols;
    while ( my $result = $gene_id->next ){
        my $list = {
            symbol => $result->symbol,
            id     => $result->id,
        };
        push @symbols, $list; 
    } 
    my $match = $self->match_builder($clin, \@symbols, 'simple');

    foreach my $i (@{$match}) {
        $xcl->resultset('Clinvar')->create({
            umls_concept_id        => $i->[0]->{'umls'},
            snomed_id              => $i->[0]->{'source_id'},
            genetic_association_id => $i->[1],
        });
    }
}

#------------------------------------------------------------------------------

sub _populate_clinvar_hgmd {
    my ($self, $hgmd) = @_;
    
    my $xcl = $self->get_dbixclass;
    my $match = $self->simple_match($hgmd);

    foreach my $i ( @{$match} ) {
        $xcl->resultset('Clinvar_hgmd')->create({
            position     => $i->[0]->{'position'},
            so_feature   => $i->[0]->{'so_feature'},
            rsid         => $i->[0]->{'rsid'},
            hgnc_gene_id => $i->[1], 
        });
    }
}

#------------------------------------------------------------------------------

sub _populate_drug_info {
    my ($self, $dbank) = @_;
    
    my $xcl = $self->get_dbixclass;
    my $match = $self->simple_match($dbank);
   
    foreach my $i ( @{$match} ) {
       $xcl->resultset('Drug_bank')->create({
            generic_name => $i->[0]->{'drug'},
            hgnc_gene_id => $i->[1],
        });
    }
}

#------------------------------------------------------------------------------


1;


