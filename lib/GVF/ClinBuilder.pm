package GVF::ClinBuilder;
use Moose;
use Tabix;
use Bio::DB::Fasta;
use File::Basename;

extends 'GVF::Clin';
with 'MooseX::Getopt';

use lib '../lib';
use Data::Dumper;

#-----------------------------------------------------------------------------
#------------------------------- Attributes ----------------------------------
#-----------------------------------------------------------------------------

has 'file' => (
    is       => 'rw',
    isa      => 'Str', 
    reader   => 'get_file',
    writer   => 'set_file',
);

has 'fasta_file' => (
    is      => 'rw',
    isa     => 'Str',
    reader  => 'get_fasta',
    default => '../data/genomes/hg19.fa',
);

has 'per_validate' => (
    is      => 'rw',
    isa     => 'Int',
    reader  => 'get_percent',
    default => '80',
);

has 'tabix_file' => (
    is     => 'rw',
    isa    => 'Str',
    reader => 'get_tabix',
    default => '../data/genomes/GRCh37.p5_top_level.gff3.bgz',
);

has 'gvf_data' => (
    traits => ['NoGetopt'],
    is => 'rw',
    isa => 'ArrayRef',
    writer => 'set_gvf_data',
    reader => 'get_gvf_data',
);

has 'export' => (
    is      => 'rw',
    isa     => 'Str',
    reader  => 'get_export',
    default => 'gvf',
);

# rewrite dbixclass att to use with builder scripts.
has '+dbixclass' => (
    traits  => ['NoGetopt'],
    default => sub {
        my $self = shift;
        my $dbix;
        my $file = basename($self->get_file);
        $file =~ s/()\.gvf/$1.db/;
    
        if ( -f "../data/$file" ){
            $dbix = GVF::DB::Connect->connect({
                    dsn =>"dbi:SQLite:../data/$file",
                    on_connect_do => "ATTACH DATABASE '../data/GeneDatabase.db' as GeneDatabase"
            });
        }
        else {
            system("sqlite3 ../data/$file < ../data/mysql/GVFClinSchema.sql");
            $dbix = GVF::DB::Connect->connect({
                    dsn =>"dbi:SQLite:../data/$file",
                    on_connect_do => "ATTACH DATABASE '../data/GeneDatabase.db' as GeneDatabase"
            });
        }
        $self->set_dbixclass($dbix);
    },
);

#-----------------------------------------------------------------------------
#------------------------------- Methods -------------------------------------
#-----------------------------------------------------------------------------

sub build_gvf {
    
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
            $atts{$1} = $2;
        }
        my $value = $self->_variant_builder(\%atts);
        
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
                clin => [],
                %{$value}
            },
        };
        push @return_list, $feature;
    }
    return \@return_list;
}

#-----------------------------------------------------------------------------

sub gvfValadate {
    my ($self, $data) = @_;
    
    # db handle and indexing fasta file.
    my $db = Bio::DB::Fasta->new( $self->get_fasta, -debug=>1 ) || die "Fasta file not found $@\n";
    
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
        
        if ( $ref_seq eq '-'){ $noRef++; next; }
        
        # call to Bio::DB. 
        my $seq = $db->seq("$chr:$start..$end");
        $seq = uc($seq);
        
        if ( $seq eq $ref_seq ) { $correct++; }
        else { $mismatch++; }
    }

    # check if passes default/given value.
    if ( $mismatch == $total ) { warn "No matches were found, possible no Reference_seq in file\n";}
    my $value = ($correct/($total-$noRef)) * 100;
    
    return \$value;
}

#------------------------------------------------------------------------------

sub geneFind {
    
    my ($self, $gvf) = @_;
    my $xcl = $self->get_dbixclass;

    my @hColumns = qw/ symbol id /;
    my $hgnc = $self->xclassGrab('Hgnc_gene', \@hColumns);

    my %hgnc;
    while ( my $result = $hgnc->next ){
        $hgnc{$result->symbol} = $result->id;
    }
    
    # create gene_id and symbol list from gene_info file.
    my $ncbi_gene = $self->get_directory . "/" . 'NCBI_Gene' . "/" . "gene_info";
    my $ncbi_fh   = IO::File->new($ncbi_gene, 'r') || die "Can not open NCBI_Gene/gene_info file\n";
    
    # build hash of ncbi gene_id with only genes matching hgnc list
    my %ncbi;
    foreach my $line ( <$ncbi_fh> ){
        chomp $line;
        
        if ($line !~ /^9606/ ) { next }
        my ($taxId, $geneId, $symbol, undef) = split/\t/, $line;
        if ($hgnc{$symbol}){
            $ncbi{$geneId} = $symbol;
        }
    }

    # create tabix object
    my $tab = Tabix->new(-data => $self->get_tabix) || die "Please input Tabix file\n";

    # search the golden set file for a match
    my @updateGVF;
    foreach my $i (@{$gvf}) {

        # will check to see if file has gene annotation.
        # and skip check if it does.
        my $gene;
        foreach ( @{$i->{'attribute'}->{'Variant_effect'}} ) {
              if( $_->{'feature_type'} eq 'gene') { $gene = '1' }
        }

        # look for a match if has no gene annotation.
        if ( ! $gene ){

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
                
                # Collect just gene_id from the matches
                map {
                    if ( $_ =~ /^Dbxref/) {
                        $_ =~ /(.*)=(.*)/g;
                        my ($gene, undef) = split /,/, $2;
                        my ($tag, $value) = split /:/, $gene;
                        my $geneMatch = ( $ncbi{$value} ) ? $ncbi{$value} : 'NULL';
                        next if $geneMatch eq 'NULL';
                        
                        my $effect = {
                            index            => '0',
                            feature_id1       => $geneMatch,
                            sequence_variant => 'gene_variant',
                            feature_type     => 'gene',
                        };
                        $atts{'GeneID'} = $effect;
                    }
                }@attsList;
            }
            push @{$i->{'attribute'}->{'Variant_effect'}}, $atts{'GeneID'} if $atts{'GeneID'};
            push @updateGVF, $i;
        }
            push @updateGVF, $i;
    }
    
    # Little reference witchcraft to try to keep speed and grep only Variant_effect with values.
    my $updateGVF = \@updateGVF;
    my @kept      = grep { $_->{'attribute'}->{'Variant_effect'}->[0]->{'feature_type'} } @{$updateGVF};
    if (scalar @kept == '0') { die "no gene matches were found for your GVF file.\n"; }
    
    return(\@kept);
}

#------------------------------------------------------------------------------

sub gvfRelationBuild {
    my ($self, $gvf) = @_;
    my $xcl = $self->get_dbixclass;

    # capture data from GeneDatabase sqlite3 file.
    my $hgnc = $xcl->resultset('Hgnc_gene')->search([
        undef,
        { columns => [qw/ symbol transcript_refseq omim_id id /] },
        {
            +columns => [qw/ refseq.genomic_refseq refseq.protein_refseq /],
            join => ['refseq'],
        }
    ]);
    
    # generate arrayref of hashrefs
    my %genedata;
    while (my $i = $hgnc->next){
        
        $genedata{$i->symbol} = [{
            clin_transcript  => $i->transcript_refseq,
            omim_id          => $i->omim_id,
        }] unless exists $genedata{$i->symbol};
        
        my $ref = $i->refseq;
        while (my $r = $ref->next){
            push @{$genedata{$i->symbol}}, {
                clin_genomic_reference => $r->genomic_refseq,
                clin_HGVS_protein      => $r->protein_refseq,
            };
        }
    }
    
    foreach my $t (@{$gvf}) {
    
        # could add call to dbMatch
    
        
        my $gene;
        foreach ( @{$t->{'attribute'}->{'Variant_effect'}} ) {
            if( $_->{'feature_type'} eq 'gene') {
                $gene = $_->{'feature_id1'};
            }
            else { next }
        }
        #if (! $gene){ next }

        if ( $genedata{$gene} ){
            push @{$t->{'attribute'}->{'clin'}}, @{$genedata{$gene}};
        }
    }
    return $gvf;
}

#------------------------------------------------------------------------------

1;
