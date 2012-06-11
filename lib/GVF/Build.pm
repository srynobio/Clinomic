package GVF::Build;
use Moose;
use Bio::DB::Fasta;

extends 'GVF::Clin';

use File::Basename;


use Data::Dumper;


#-----------------------------------------------------------------------------
#------------------------------- Attributes ----------------------------------
#-----------------------------------------------------------------------------

has 'gvf_file' => (
    is       => 'rw',
    isa      => 'Str', 
    reader   => 'gvf_file',
    writer   => 'set_gvf_file',
    default  => 'none',
    trigger  => \&_build_feature_lines,
);

has 'gvf_data' => (
    is  => 'rw',
    isa => 'ArrayRef',
  
    writer => 'set_gvf_data',
    reader => 'get_gvf_data',
    
);

has 'fasta_file' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'none',
    writer  => 'set_fasta_file',
    reader  => 'get_fasta_file',
);

has 'ref_match' => (
    is      => 'rw',
    isa     => 'Int',
    reader  => 'get_ref_match',
    default => '80',
);




#-----------------------------------------------------------------------------
#------------------------------- Methods -------------------------------------
#-----------------------------------------------------------------------------

sub gvf_valadate {

    my $self = shift;
    
    # capture info.
    my $data = $self->get_gvf_data;
    my $dbxh = $self->get_mysql_dbxh;

    # file check
    if ( ! $data->[0]->{'attribute'}->{'Variant_effect'} ) {
        die "Your GVF file does not have the required Variant_effect field...\n";
    }
    
    # db handle and indexing fasta file.
    my $db = Bio::DB::Fasta->new( $self->get_fasta_file, -debug=>1 ) || die "Fasta file not found $@\n";
    
    my ( $correct, $mismatch, $total );
    foreach my $i ( @{$data} ) {
    
        # keep track of the total number of line in file.     
        $total++;
        
        my $chr;
        if ( $i->{'seqid'} !~ /^chr/ ){
            $chr = "chr". $i->{'seqid'};
        }
        else {
            $chr = $i->{'seqid'};
        }
        
        my $start   = $i->{'start'};
        my $end     = $i->{'end'};
        
        my $ref_seq = uc($i->{'attribute'}->{'Reference_seq'});
        if ( $ref_seq eq '-'){ next }
        
        # call to Bio::DB. 
        my $seq = $db->seq("$chr:$start..$end");
        $seq = uc($seq);
        
        if ( $seq eq $ref_seq ) { $correct++; }
        else { $mismatch++; }

    }
    
    # check if passes default/given value.
    my $value = ($correct/$total) * 100;
    if ( $value <= $self->get_ref_match ){ die "Your file matches less than ", $self->get_ref_match, "%", "\n"; }
    else { print "File matched $value%\n"; }
    
    return ($value);
}

#-----------------------------------------------------------------------------

sub _build_feature_lines {
    
    my ( $self, $data ) = @_;

    my $feature_line = $self->_file_splitter('feature');
    
    my ( @return_list );
    foreach my $lines( @$feature_line ) {
        chomp $lines;
        
        my ($seq_id, $source, $type, $start, $end, $score, $strand, $phase, $attribute) = split(/\t/, $lines);
        my @attributes_list = split(/\;/, $attribute);

        my %atts;
        foreach my $attributes (@attributes_list) {
            $attributes =~ /(.*)=(.*)/g;
            $atts{$1} = $2;
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

    # check if gvf file matches reference build.
    #my $per_correct = $self->gvf_valadate(\@return_list);
    #if ( $per_correct <=  80 ) {
    #    die "The reference sequences match less than 80% ($per_correct), file will not be added to database\n";
    #}
    #else {
    #    $self->_populate_gvf_data(\@return_list);
    #}
    #
 
    $self->set_gvf_data(\@return_list);
 
    #print Dumper(@return_list);
    #$self->_populate_gvf_data(\@return_list);
}








1;