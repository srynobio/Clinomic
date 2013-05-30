package Clinomic::Parser;
use Moose::Role;
use Carp;
use namespace::autoclean;
use IO::File;

#------------------------------------------------------------------------------
#----------------------------- Methods ----------------------------------------
#------------------------------------------------------------------------------

sub hgncGene {

    my $self = shift;

    # create gene_id and symbol list from gene_info file.
    my $ncbi_gene = $self->get_directory . "/" . 'NCBI' . "/" . "gene_info9606";
    my $ncbi_fh = IO::File->new( $ncbi_gene, 'r' )
      || die "Can not open NCBI/gene_info file\n";

    # build hash of ncbi gene_id with only genes matching hgnc list
    my %ncbi;
    foreach my $line (<$ncbi_fh>) {
        chomp $line;

        unless ( $line =~ /^9606/ )      { next }
        unless ( $line =~ /HGNC:(\d+)/ ) { next }

        my ( $taxId, $geneId, $symbol, undef ) = split /\t/, $line;
        $ncbi{$geneId} = $symbol;
    }

    return \%ncbi;
}

#------------------------------------------------------------------------------

sub refseq {
    my $self = shift;

    # uses the relationship file to collect refseq information
    my $ref_file =
      $self->get_directory . "/" . 'NCBI' . "/" . "UpdatedRefSeq.txt";
    my $ref_fh = IO::File->new( $ref_file, 'r' )
      || die "Can not open NCBI/UpdatedRefSeq.txt file\n";

    my %refseq;
    foreach my $line (<$ref_fh>) {
        chomp $line;

        next if $line =~ /^#/;

        my @refs = split /\t/, $line;

        # exclude unwanted data
        unless ( $refs[7]  =~ /^NC_(.*)$/ )            { next }
        unless ( $refs[12] =~ /Reference GRCh37.p10/ ) { next }
        unless ( $refs[5] =~ /^AP_(.*)$/ || $refs[5] =~ /^NP_(.*)$/ ) { next }

        $refseq{ $refs[1] } = { protein_acc => $refs[3], };
    }
    $ref_fh->close;
    return ( \%refseq );
}

#------------------------------------------------------------------------------

sub gvfParser {
    my ( $self, $data ) = @_;

    my $feature_line = $self->_file_splitter('feature');

    # extract out pragmas and store them in object;
    $self->_pragmas;

    my ( @return_list, @seqWarn );
    foreach my $lines ( @{$feature_line} ) {
        chomp $lines;

        my (
            $seq_id, $source, $type,  $start, $end,
            $score,  $strand, $phase, $attribute
           ) = split( /\t/, $lines );

        my @attributes_list = split( /\;/, $attribute ) if $attribute;

        next if ! $seq_id;
        unless ( $seq_id =~ /^chr|(\d+)/ ) { push @seqWarn, $seq_id; next; }
        $seq_id =~ s/^chr(\d+|X|Y)/$1/g;

        my %atts;
        foreach my $attributes (@attributes_list) {
            $attributes =~ /(.*)=(.*)/g;
            $atts{$1} = $2;
        }
        my $value = $self->_variant_builder( \%atts );

        my $feature = {
            seqid     => $seq_id,
            source    => $source,
            type      => $type,
            start     => $start,
            end       => $end,
            score     => $score,
            strand    => $strand,
            attribute => { %{$value} },
        };
        push @return_list, $feature;
    }
    if ( scalar @seqWarn > 1 ) {
        die "One or more seqid did not start with chr# or #. Clinomic requires this.\n";
    }
    return \@return_list;
}

#------------------------------------------------------------------------------

sub _file_splitter {
    my ( $self, $request ) = @_;

    my $obj_fh;
    open( $obj_fh, "<", $self->get_file )
      || die "File " . $self->get_file . " can not be opened\n";

    my ( @pragma, @feature_line );
    foreach my $line (<$obj_fh>) {
        chomp $line;

        $line =~ s/^\s+$//g;

        # captures pragma lines.
        if ( $line =~ /^#{1,}/ ) {
            push @pragma, $line;
        }

        # or feature_line
        else { push @feature_line, $line; }
    }

    if ( $request eq 'pragma' )  { return \@pragma }
    if ( $request eq 'feature' ) { return \@feature_line }
}

#------------------------------------------------------------------------------

no Moose;
1;
