package GVF::DB::Loader;
use Moose::Role;
use Carp;
use namespace::autoclean;
use GVF::DB::Connect;

#-----------------------------------------------------------------------------
#------------------------------- Attributes ----------------------------------
#-----------------------------------------------------------------------------

has 'dbixclass' => (
    is      => 'rw',
    isa	    => 'Object',
    reader  => 'dbixclass',
    writer  => 'set_dbixclass',
    reader  => 'get_dbixclass',
    default => sub {
        my $self = shift;
        my $dbix;
        
        if ( -f 'GeneDatabase.db' ){
            die "\nGeneDatabase already exists\n";
        }
        else {
            system("sqlite3 GeneDatabase.db < ../data/mysql/DatabaseSchema.sql");
            $dbix = GVF::DB::Connect->connect('dbi:SQLite:GeneDatabase.db');
        }
        $self->set_dbixclass($dbix);
    },
);

#------------------------------------------------------------------------------
#----------------------------- Methods ----------------------------------------
#------------------------------------------------------------------------------

sub _build_database {
    my $self = shift;
    
    warn "Building Database\n";
    $self->hgnc;
    $self->refseq;
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

    my @hColumns = qw/ symbol id  /;
    my $trans_id = $self->xclassGrab('Hgnc_gene', \@hColumns);
    
    my @transcript;
    while ( my $result = $trans_id->next ){
        my $list = {
            symbol => $result->symbol,
            id    => $result->id,
        };
        push @transcript, $list; 
    }
    my $match = $self->match_builder($ref, \@transcript, 'refseq');

    foreach my $i ( @{$match} ) {
        $xcl->resultset('Refseq')->create({
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
    
    my @gColumns = qw/ symbol id  /;
    my $genetic = $self->xclassGrab('Hgnc_gene', \@gColumns);

    my @symbols;
    while ( my $result = $genetic->next ){
        my $list = {
            symbol => $result->symbol,
            id     => $result->id,
        };
        push @symbols, $list; 
    } 
    my $match = $self->match_builder($clin, \@symbols, 'simple');

    foreach my $i (@{$match}) {
        $xcl->resultset('Clinvar')->create({
            umls_concept_id => $i->[0]->{'umls'},
            snomed_id       => $i->[0]->{'source_id'},
            hgnc_gene_id    => $i->[1],
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


