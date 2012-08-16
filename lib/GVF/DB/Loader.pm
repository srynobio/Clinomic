package GVF::DB::Loader;
use Moose::Role;
use Carp;
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
        
        if ( -f '../data/GeneDatabase.db' ){
            die "\nGeneDatabase already exists\n";
        }
        else {
            system("sqlite3 ../data/GeneDatabase.db < ../data/mysql/DatabaseSchema.sql");
            $dbix = GVF::DB::Connect->connect('dbi:SQLite:../data/GeneDatabase.db');
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

    my @hColumns = qw/ transcript_refseq id  /;
    my $trans_id = $self->xclassGrab('Hgnc_gene', \@hColumns);
    
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

## start of the ClinBuilder methods ##

use Data::Dumper;

sub _populate_gvf_data {
    my $self = shift;   

    my $gvf = $self->get_gvf_data;
    print Dumper($gvf);



=cut    
    # build feature db.
    foreach my $i ( @{$match} ) {
        $xcl->resultset('GVFClin')->create({
            seqid  => $i->[0]->{'seqid'},
            source => $i->[0]->{'source'},
            type   => $i->[0]->{'type'},
            start  => $i->[0]->{'start'},
            end    => $i->[0]->{'end'},
            score  => $i->[0]->{'score'},
            strand => $i->[0]->{'strand'},
            phase  => $i->[0]->{'phase'},
            attributes_id     => $i->[0]->{'attribute'}->{'ID'},
            alias             => $i->[0]->{'attribute'}->{'Alias'},
            dbxref            => $i->[0]->{'attribute'}->{'Dbxref'},
            variant_seq       => $i->[0]->{'attribute'}->{'Variant_seq'},
            reference_seq     => $i->[0]->{'attribute'}->{'Reference_seq'},
            variant_reads     => $i->[0]->{'attribute'}->{'Variant_reads'},
            total_reads       => $i->[0]->{'attribute'}->{'Total_reads'},
            zygosity          => $i->[0]->{'attribute'}->{'Zygosity'},
            variant_freq      => $i->[0]->{'attribute'}->{'Variant_freq'},
            start_range       => $i->[0]->{'attribute'}->{'Start_range'},
            end_range         => $i->[0]->{'attribute'}->{'End_range'},
            phased            => $i->[0]->{'attribute'}->{'Phased'},
            genotype          => $i->[0]->{'attribute'}->{'Genotype'},
            individual        => $i->[0]->{'attribute'}->{'Individual'},
            variant_codon     => $i->[0]->{'attribute'}->{'Variant_codon'},
            reference_codon   => $i->[0]->{'attribute'}->{'Reference_codon'},
            variant_aa        => $i->[0]->{'attribute'}->{'Variant_aa'},
            breakpoint_detail => $i->[0]->{'attribute'}->{'Breakpoint_detail'},
            sequence_context  => $i->[0]->{'attribute'}->{'Sequence_context'},
        });
    }
=cut    
    
    
    
    
    
}

#------------------------------------------------------------------------------



1;


