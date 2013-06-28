package Clinomic::Parser;
use Moose::Role;
use Carp;
use namespace::autoclean;
use IO::File;

##-----------------------------------------------------------------------------
##------------------------------- Attributes ----------------------------------
##-----------------------------------------------------------------------------

has 'data_directory' => (
  traits  => ['NoGetopt'],
  is      => 'rw',
  isa     => 'Str',
  default => '../data/',
  writer  => 'set_directory',
  reader  => 'get_directory',
);

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

        $refseq{ $refs[1] } = {
          rna_acc => $refs[3],
          pro_acc => $refs[5],
          gen_acc => $refs[7],
        };
    }
    $ref_fh->close;
    return ( \%refseq );
}
#------------------------------------------------------------------------------

sub gvfParser {
    my $self = shift;
    warn "{Clinomic} Creating Data Structures\n";

    my $feature_line = $self->_file_splitter('feature');

    # extract out pragmas and store them in object;
    $self->_pragmas;

    my @return_list;
    foreach my $lines ( @{$feature_line} ) {
        chomp $lines;

        my (
            $seq_id, $source, $type,  $start, $end,
            $score,  $strand, $phase, $attribute
           ) = split( /\t/, $lines );

        my @attributes_list = split( /\;/, $attribute ) if $attribute;

        next if ! $seq_id;
        if ($seq_id !~ /^chr/) {
          die "{Clinomic} requires the feature lines of ", $self->file, " to begin with the notation chr\#\#.\n";
        }

        my %atts;
        foreach my $attributes (@attributes_list) {
            $attributes =~ /(.*)=(.*)/g;
            $atts{$1} = $2;
        }
        my $value = $self->_variant_effect_builder( \%atts );

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
   return \@return_list;
}
#------------------------------------------------------------------------------

sub _pragmas {
  my $self = shift;

  # grab only pragma lines
  my $pragma_line = $self->_file_splitter('pragma');

  my %p;
  foreach my $i ( @{$pragma_line} ) {
    chomp $i;

    my ( $tag, $value ) = $i =~ /##(\S+)\s?(.*)$/g;
    $tag =~ s/\-/\_/g;

    $p{$tag} = [] unless exists $p{$tag};

    # if value has multiple tag value pairs, split them.
    if ( $value =~ /\=/ ) {
      my @lines = split /;/, $value;

      my %test;
      map {
        my ( $tag, $value ) = split /=/, $_;
        $test{$tag} = $value;
      } @lines;
      $value = \%test;
    }
    push @{ $p{$tag} }, $value;
  }

  # check or add only required pragma.
  if ( !exists $p{'gvf_version'} ) { $p{'gvf_version'} = [1.06] }
  $self->set_pragmas( \%p );
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

sub _variant_effect_builder {
  my ( $self, $atts ) = @_;

  my %vEffect;
  while ( my ( $keys, $value ) = each %{$atts} ) {

    if ( $keys eq 'Variant_effect' ) {
      my @effect = split /,/, $value;

      my @effectList;
      foreach (@effect) {
        my ( $sv, $index, $ft, $id ) = split /\s/, $_;

        my $effect = {
          sequence_variant => $sv,
          index            => $index,
          feature_type     => $ft,
          feature_id       => $id,
        };
        push @effectList, $effect;
      }
      $vEffect{$keys} = [@effectList];
    }
    else {
      $vEffect{$keys} = $value;
    }
  }
  return \%vEffect;
}
#------------------------------------------------------------------------------

no Moose;
1;
