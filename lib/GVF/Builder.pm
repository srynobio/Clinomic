package GVF::Builder;
use Moose;
use Bio::DB::Fasta;
use Tabix;
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
    required => 1,
    trigger  => \&_build_feature_lines,
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
    default => '../data/genomes/GRCh37.p5_top_level.gff3.gz',
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

has '+dbixclass' => (
    traits  => ['NoGetopt'],
    default => sub {
        my $self = shift;
        my $dbix;
        #my $file = fileparse($self->get_file);
        #$file =~ s/(.*).gvf$/$1.db/g;
    
        if ( -f "../data/tmp.db" ){
            $dbix = GVF::DB::Connect->connect("dbi:SQLite:../data/tmp.db");
        }
        else {
            system("sqlite3 ../data/tmp.db < ../data/mysql/GVFSchema.sql");
            $dbix = GVF::DB::Connect->connect("dbi:SQLite:../data/tmp.db");
        }
        $self->set_dbixclass($dbix);
    },
);

has '+build_database' => (
    traits => ['NoGetopt'],
    #trigger => \&_build_feature_lines,
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
            $atts{$1} = $2;
        }
        my $value = $self->_atts_builder(\%atts);
        
        my $feature = {
            seqid => $seq_id,
            source => $source,
            type => $type,
            start => $start,
            end => $end,
            score => $score,
            strand => $strand,
            phase => $phase,
            attribute => {
                %{$value}
            },
        };
        push @return_list, $feature;
    }
    $self->set_gvf_data(\@return_list);
}

#-----------------------------------------------------------------------------

1;
