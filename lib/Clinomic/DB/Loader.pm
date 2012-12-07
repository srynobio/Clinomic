package Clinomic::DB::Loader;
use Moose::Role;
use Carp;
use namespace::autoclean;
use Clinomic::DB::Connect;

use Data::Dumper;

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
        my $dbix = Clinomic::DB::Connect->connect('dbi:SQLite:GeneDatabase.sqlite');
        $self->set_dbixclass($dbix);
    },
);

#------------------------------------------------------------------------------
#----------------------------- Methods ----------------------------------------
#------------------------------------------------------------------------------

sub _build_database {
    my $self = shift;
    my $dbix;
    
    if ( -f 'GeneDatabase.sqlite' ){
        die "\nGeneDatabase already exists\n";
    }
    else {
        system("sqlite3 GeneDatabase.sqlite < ../data/mysql/DatabaseSchema.sql");
        $dbix = Clinomic::DB::Connect->connect('dbi:SQLite:GeneDatabase.sqlite');
    }
    $self->set_dbixclass($dbix);

    # build all the db sections.
    warn "{ClinDatabase} Building Database\n";
    $self->hgnc;
    $self->refseq;
    ###$self->drug_bank;
}

#------------------------------------------------------------------------------

sub _populate_genes {
    my ($self, $genes) = @_;
    
    my $xcl = $self->get_dbixclass;
    
    foreach my $i ( @{$genes} ){
         $xcl->resultset('Hgnc_gene')->create({
             symbol            => $i->{'symbol'},
             chromosome        => $i->{'chromo'},
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
            genomic_refseq    => $i->[0]->{'genomic_acc'},
            protein_refseq    => $i->[0]->{'prot_acc'},
            transcript_refseq => $i->[0]->{'transcript_id'},
            genomic_start     => $i->[0]->{'start'},
            genomic_end       => $i->[0]->{'end'},
            hgnc_gene_id      => $i->[1],
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

no Moose;
1;
