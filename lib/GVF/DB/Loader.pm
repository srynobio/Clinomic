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

## start of the ClinBuilder methods ##
=cut
sub populate_gvf_data {

    my $self = shift;
    
    #my $dbxh = $self->dbxh;
    my $data = $self->get_gvf_data;

    my @geneName;
    foreach my $i ( @{$data} ) {
    
        if ( ! $i->{'attribute'}->{'Variant_effect'} ) { next }
        $i->{'attribute'}->{'Variant_effect'} =~ /\s+gene\s+(\S+),?/;

        my $gene = {
            symbol => uc($1),
        };
        push @geneName, $gene;
    }
    
    #### may delete later
    if ( ! scalar @geneName >= 1 ) { die "\nCannot locate gene information in Variant_effect attribute of your GVF file\n"; }

    # match to the database of gene names.
    my $match = $self->simple_match(\@geneName);
    
    # a hack to create uniq gene name with db id's.
    my %g;
    foreach my $i (@{$match}) {
        my $gene = uc($i->[0]->{'symbol'});
        my $id   = $i->[1];
        
        $g{$gene} = [] unless exists $g{$gene};
        push @{$g{$gene}}, [$id];
    }
    
    # build db
    foreach my $i ( @{$data} ) {
        chomp $i;

        if ( $i->{'attribute'}->{'Reference_seq'} eq $i->{'attribute'}->{'Variant_seq'} ) {  print Dumper($i); next;}
        
        # Get gene from variant_effect
        $i->{'attribute'}->{'Variant_effect'} =~ /\s+gene\s+(\S+),?/;
        
        if ( $g{$1} ) {
            $dbxh->resultset('GVFclin')->create({
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
                Genes_id          => $g{$1}->[0]->[0],
            });
        }
    }
}
=cut
#------------------------------------------------------------------------------


1;


