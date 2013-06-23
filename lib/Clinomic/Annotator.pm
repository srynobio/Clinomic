package Clinomic::Annotator;
use Moose::Role;
use lib '/home/srynearson/GAL/lib';
use GAL::Annotation;



# still very much in dev!
use Data::Printer;
use Data::Dumper;

#-----------------------------------------------------------------------------
#------------------------------- Attributes ----------------------------------
#-----------------------------------------------------------------------------

has 'annotator' => (
    traits  => ['NoGetopt'],
    is       => 'rw',
    #isa      => 'Bool',
    isa      => 'Str',
    reader   => 'get_annot',
    writer   => 'set_annot',
    #lazy  => 1,
    #builder  => '_build_annotator',
    trigger => \&_build_annotator,
    #documentation => q(Path to the fasta reference file used for reference validation.  Default is hg19.
    #)
);

has 'gal_object' => (
    traits  => ['NoGetopt'],
    is     => 'rw',
    isa    => 'Object',
    reader => 'get_gal',
    writer => 'set_gal',
);

# will need to incorperate current gff file, but for now testing with this.

has 'gff_annot' => (
    traits  => ['NoGetopt'],
    is       => 'rw',
    isa      => 'Str',
    reader   => 'get_gff_annot',
    default  => '../bin/updated_complete_GRCh37.gff3',
);

#-----------------------------------------------------------------------------
#------------------------------- Methods -------------------------------------
#-----------------------------------------------------------------------------

sub _build_annotator {
    my $self = shift;
    
    my $gff3  = $self->get_gff_annot;
    my $fasta = $self->get_fasta;
    
    my $annotation = GAL::Annotation->new( $gff3, $fasta );
    
    $self->set_gal($annotation);
}

#-----------------------------------------------------------------------------

sub finderTest {

    my ($self, $data) = @_;
     
    # incoming GVF data.
    my %test;    
    foreach my $g ( @{$data} ){
        $test{ $g->{attribute}{clin}{Clin_gene} } = {
            id    => $g->{attribute}->{ID},
            start => $g->{start},
            end   => $g->{end},
            variant  => $g->{attribute}->{Variant_seq},
            referent => $g->{attribute}->{Reference_seq}
            
        };
    }

    # GAL objects
    my $gal = $self->get_gal;
    my $features = $gal->features->search( {type => 'mRNA'} );
    


    while (my $line = $features->next){

        my $atts    = $line->attributes_hash;
        my $gffGene = $atts->{gene}[0];
        
        # match gene
        if ( $test{$gffGene} ){

            my ($codon, $frame, $seq) = $line->codon_at_location( $test{$gffGene}->{start} );
            my $exons           = $line->exons;

            #####print Dumper ($codon, $frame, $seq);

            while (my $e = $exons->next){

                if ( $test{$gffGene}{start} >= $e->start && $test{$gffGene}{end} <= $e->end ) {
                    
                    push @{ $test{$gffGene}{exon_match} }, {
                        Clin_transcript => $atts->{transcript_id}[0],
                        exon_start => $e->start,
                        exon_end =>  $e->end,
                        exon_id  => $e->feature_id,
                        codon => $codon,
                        frame => $frame,
                    };
                }
            }
        }


    }

  #  print Dumper(%test);
#	print Dumper($data);
}







1;
