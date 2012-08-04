package GVF::Build;
use Moose;
use Bio::DB::Fasta;
use Tabix;

extends 'GVF::Clin';

use File::Basename;


use lib '../lib';
use Data::Dumper;
use PostData;

#-----------------------------------------------------------------------------
#------------------------------- Attributes ----------------------------------
#-----------------------------------------------------------------------------

has 'gvf_file' => (
    is       => 'rw',
    isa      => 'Str', 
    reader   => 'gvf_file',
    writer   => 'set_gvf_file',
    required => 1,
    trigger  => \&_build_feature_lines,
);

has 'gvf_data' => (
    is       => 'rw',
    isa      => 'ArrayRef',
    writer   => 'set_gvf_data',
    reader   => 'get_gvf_data',
);

has 'fasta_file' => (
    is      => 'rw',
    isa     => 'Str',
    reader  => 'get_fasta_file',
    default => '../data/genomes/hg19.fa',
);

has 'ref_match' => (
    is      => 'rw',
    isa     => 'Int',
    reader  => 'get_ref_match',
    writer  => 'set_ref_match',
    default => '80',
);

has 'tabix_file' => (
    is     => 'rw',
    isa    => 'Str',
    reader => 'get_tabix_file',
    default => '../data/genomes/GRCh37.p5_top_level.gff3.gz',
);


#-----------------------------------------------------------------------------
#------------------------------- Methods -------------------------------------
#-----------------------------------------------------------------------------

sub _build_feature_lines {
    
    my ( $self, $data ) = @_;

    my $feature_line = $self->_file_splitter('feature');
    
    my ( @return_list );
    foreach my $lines( @{$feature_line} ) {
        chomp $lines;
        
        my ($seq_id, $source, $type, $start, $end, $score, $strand, $phase, $attribute) = split(/\t/, $lines);
        my @attributes_list = split(/\;/, $attribute);

        next if ! $seq_id;
        
        my %atts;
        foreach my $attributes (@attributes_list) {
            $attributes =~ /(.*)=(.*)/g;
            $atts{$1}   = $2;
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
    $self->set_gvf_data(\@return_list);
}

#-----------------------------------------------------------------------------

sub gvf_valadate {

    my $self  = shift;
    
    # capture info.
    my $data = $self->get_gvf_data;
    my $dbxh = $self->dbxh;

    # file check
    my $hasGene = ( $data->[0]->{'attribute'}->{'Variant_effect'} ) ? 'yes' : '';
    
    # db handle and indexing fasta file.
    my $db = Bio::DB::Fasta->new( $self->get_fasta_file, -debug=>1 ) || die "Fasta file not found $@\n";
    
    my ( $correct, $mismatch, $total);
    my $noRef = '0';
    foreach my $i ( @{$data} ) {
    
        # keep track of the total number of lines in file.     
        $total++;
        
        my $chr;
        if ( $i->{'seqid'} !~ /^chr/i ){
            $chr = "chr". $i->{'seqid'};
        }
        else {
            $chr = $i->{'seqid'};
        }
        
        my $start   = $i->{'start'};
        my $end     = $i->{'end'};
        
        my $ref_seq = uc($i->{'attribute'}->{'Reference_seq'});
        ## maybe exit if no reference sequence.
        ## or after complete check is done.
        
        if ( $ref_seq eq '-'){ $noRef++; next; }
        
        # call to Bio::DB. 
        my $seq = $db->seq("$chr:$start..$end");
        $seq = uc($seq);
        
        if ( $seq eq $ref_seq ) { $correct++; }
        else { $mismatch++; }
    }
    

    # check if passes default/given value.
    my $value = ($correct/($total-$noRef)) * 100;
    my $valid = ($value >= $self->get_ref_match) ? 'yes' : '';
    
    return (\$valid, \$hasGene, \$value);
}
    
#-----------------------------------------------------------------------------

sub tabix_build {
    
    #my $self = shift;
    my ( $self, $tabix ) = @_;
    
    my $dbxh = $self->dbxh;
    my $data = $self->get_gvf_data;

    # capture list of gene_id's
    my $gene_id = $dbxh->resultset('Genes')->search (
        undef, { columns => [qw/ gene_id symbol /], }
    );
    
    my %ncbi;
    while ( my $result = $gene_id->next ){
        $ncbi{$result->gene_id} = $result->symbol;
    }
    
    my $tab = Tabix->new(-data => $self->get_tabix_file) || die "Please input Tabix file\n";

    # search the golden set file for a match
    my @updateGVF;
    foreach my $i (@{$data}) {

        # check to make sure the file starts with chr.
        my $chr;
        if ( $i->{'seqid'} !~ /^chr/i ){ $chr = "chr". $i->{'seqid'}; }
        else { $chr = $i->{'seqid'}; }
        
        my $start = $i->{'start'};
        my $end   = $i->{'end'};
    
        # check the tabix file for matching regions
        my $iter = $tab->query($chr, $start - 1, $end + 1);
        
        my %atts;
        while (my $read = $tab->read($iter)) {
        
            my @gffMatch = split /\t/, $read;
            my @attsList = split /;/, $gffMatch[8];
            
            # Collect just gene_id from the matches and DBIx resultset data.
            map {
                if ( $_ =~ /^Dbxref/) {
                    $_ =~ /(.*)=(.*)/g;
                    my ($gene, undef) = split /,/, $2;
                    my ($tag, $value) = split /:/, $gene;
                    my $geneMatch = ( $ncbi{$value} ) ? $ncbi{$value} : 'NULL';
                    my $effect        = "gene_variant 0 gene " . $geneMatch, if $geneMatch ne 'NULL';
                    $atts{'GeneID'}   = $effect;
                }
            }@attsList;
        }
        $i->{'attribute'}->{'Variant_effect'} = $atts{'GeneID'} if $atts{'GeneID'};
        push @updateGVF, $i;        
    }
    
    # Little reference witchcraft to try to keep speed.
    my $updateGVF = \@updateGVF;
    my @kept      = grep { $_->{'attribute'}->{'Variant_effect'} } @{$updateGVF};
    my $kept      = \@kept;

    $self->set_gvf_data($kept);
    $self->populate_gvf_data;
}

#-----------------------------------------------------------------------------

sub populate_gvf_data {

    my $self = shift;
    
    my $dbxh = $self->dbxh;
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

#-----------------------------------------------------------------------------


1;