package Clinomic;
use Moose;
use Tabix;
use IO::File;
use File::Basename;
use Data::Dumper;

with 'Clinomic::Roles';
with 'MooseX::Getopt';

##-----------------------------------------------------------------------------
##------------------------------- Attributes ----------------------------------
##-----------------------------------------------------------------------------

has 'file' => (
    is            => 'rw',
    isa           => 'Str',
    reader        => 'get_file',
    required      => 1,
    documentation => q|[REQUIRED] Path to the GVF file you want to convert to Clinical document.|,
);

has 'fasta' => (
    traits   => ['NoGetopt'],
    is       => 'rw',
    isa      => 'Str',
    reader   => 'get_fasta',
    required => 1,
    default  => '../data/Fasta/chrAll.fa',
);

has 'feature' => (
    traits   => ['NoGetopt'],
    is       => 'rw',
    isa      => 'Str',
    reader   => 'get_gff',
    required => 1,
    default  => '../data/GFF/Updated.ref_GRCh37.sorted.gff3.gz',
);

has 'tabix_dbsnp' => (
    traits  => ['NoGetopt'],
    is      => 'rw',
    isa     => 'Str',
    reader  => 'get_db_tabix',
    default => '../data/dbSNP/Updated.00-All.vcf.gz',
);

has 'tabix_clinsig' => (
    traits  => ['NoGetopt'],
    is      => 'rw',
    isa     => 'Str',
    reader  => 'get_clin_tabix',
    default => '../data/ClinVar/clinvar_sig.vcf.gz',
);

has 'tabix_gtf' => (
    traits   => ['NoGetopt'],
    is       => 'rw',
    isa      => 'Str',
    reader   => 'get_gtf_tabix',
    required => 1,
    default  => '../data/GTF/Homo_sapiens.gtf.gz',
);

has 'pragma' => (
    traits    => ['NoGetopt'],
    is        => 'rw',
    isa       => 'HashRef',
    writer    => 'set_pragmas',
    reader    => 'get_pragmas',
);

has 'report' => (
  is            => 'rw',
  isa           => 'Str',
  reader        => 'get_report',
  default       => 'hgnc',
  documentation => q|Report all variants from original file, not just HGNC/LOINC annotated. Default hgnc. Options=hgnc, all|,
);

has 'cpu' => (
  is  => 'rw',
  isa => 'Int',
  reader => 'get_cpu',
  default => '1',
  documentation => q|Will set the total number of CPUs to run processes on. Default is 1.|,
);

has 'tmp_dir' => (
  is => 'rw',
  isa => 'Str',
  reader => 'get_tmpdir',
  default => '.',
  documentation => q|Set the temporary to write file to when using pClinomic. Default current directory.|,
);

##-----------------------------------------------------------------------------
##------------------------------- Methods -------------------------------------
##-----------------------------------------------------------------------------

sub gvfRelationBuild {
  my ( $self, $data ) = @_;

  my $stp0 = $self->gvfGeneFind($data);
  my $stp1 = $self->gvfRefBuild($stp0);
  my $stp2 = $self->snpCheck($stp1);
  my $stp3 = $self->variantTypeCheck($stp2);
  my $stp4 = $self->clinicalSig($stp3);
  my $stp5 = $self->allelicStateCheck($stp4);
  my $stp6 = $self->hgvsDNACheck($stp5);
  my $stp7 = $self->regionFinder($stp6);
  #my $stp8 = $self->hgvsProtCheck($stp7);

  return $stp7;
}
##-----------------------------------------------------------------------------

sub gvfGeneFind {
    my ( $self, $data ) = @_;
    warn "{Clinomic} Building gene relationships.\n";

    # build hgnc approved gene list.
    my $ncbi = $self->hgncGene;

    # create tabix object
    my $tab = Tabix->new( -data => $self->get_gff )
      || die "Cannot locate GFF Tabix file\n";

    # search the golden set file for a match
    my @updateGVF;
    foreach my $i ( @{$data} ) {

        my $chr     = $i->{'seqid'};
        my $start   = $i->{'start'};
        my $end     = $i->{'end'};
        my $ref_seq = $i->{'attribute'}->{'Reference_seq'};
        my $var_seq = $i->{'attribute'}->{'Variant_seq'};

        # get the index of the variant
        if ( $var_seq =~ /\,/ ) { $var_seq =~ s/\,// }
        my $pos = index($var_seq, $ref_seq);

        # create the index
        my $index;
        ($pos == '0') ? $index  = 1 :
        ($pos == '1') ? $index  = 0 :
        ($pos == '-1') ? $index = 0 : $index = 0;

        # check the tabix file for matching regions
        my $iter = $tab->query( $chr, $start - 1, $end + 1 );

        my %atts;
        while ( my $read = $tab->read($iter) ) {

            my @gffMatch = split /\t/, $read;
            my @attsList = split /;/,  $gffMatch[8];

            # Collect just gene_id from the matches
            map {
                if ( $_ =~ /^Dbxref/ )
                {
                    $_ =~ /(.*)=(.*)/g;
                    my ( $gene, undef ) = split /,/, $2;
                    my ( $tag, $value ) = split /:/, $gene;

                    my $geneMatch =
                      ( $ncbi->{$value} ) ? $ncbi->{$value} : 'NULL';
                    next if $geneMatch eq 'NULL';

                    my $effect = {
                        index            => $index,
                        feature_id       => $geneMatch,
                        sequence_variant => 'gene_variant',
                        feature_type     => 'gene',
                    };
                    $atts{'GeneID'} = $effect;
                }
            } @attsList;
        }
        push @{ $i->{'attribute'}->{'Variant_effect'} }, $atts{'GeneID'} if $atts{'GeneID'};
        push @updateGVF, $i;
    }

    ## This section removes any variants which have no gene match.
    ## Little reference witchcraft to try to keep speed and grep only Variant_effect with values.
    my @kept;
    if ($self->get_report eq 'hgnc') {
      my $updateGVF = \@updateGVF;
      @kept = grep { $_->{'attribute'}->{'Variant_effect'}->[0]->{'feature_type'} } @{$updateGVF};
    }
    # return one of the two
    ($self->get_report eq 'hgnc') ? return \@kept : return \@updateGVF;
}
##------------------------------------------------------------------------------

sub gvfRefBuild {
    my ( $self, $data ) = @_;
    warn "{Clinomic} Checking refseq files.\n";

    my $refInfo = $self->refseq;

    # add db clin informaton to gvf file.
    foreach my $t ( @{$data} ) {

        # Collect gene name from gvf file
        my $gene;
        foreach ( @{$t->{'attribute'}->{'Variant_effect'}} ) {
          next unless $_->{'feature_type'} eq 'gene';
          next if $_->{'feature_id'} =~ /^gene/;
          $gene = $_->{'feature_id'};
        }
        unless ($gene) { next }

        # add gene if found.
        $t->{'attribute'}->{'clin'}->{'Gene_identifier'} = "LOINC:40018-6 HGNC:$gene";

        # search for matching gene names, and add all clin data
        # to working gvf file
        if ( $refInfo->{$gene} ) {
          $t->{'attribute'}->{'clin'}->{'Genomic_reference_sequence_identifier'} =
            "LOINC:48013-7 NCBI:$refInfo->{$gene}->{gen_acc}";

          $t->{'attribute'}->{'clin'}->{'Transcript_reference_sequence_identifier'} =
            "LOINC:51958-7 NCBI:$refInfo->{$gene}->{rna_acc}";
        }
    }
    return $data;
}
##------------------------------------------------------------------------------

sub snpCheck {
    my ( $self, $data ) = @_;
    warn "{Clinomic} Checking dbSNP file.\n";

    # create tabix object
    my $tab = Tabix->new( -data => $self->get_db_tabix )
      || die "Cannot locate dbSNP Tabix file\n";

    foreach my $i ( @{$data} ) {
        my $chr     = $i->{'seqid'};
        my $start   = $i->{'start'};
        my $end     = $i->{'end'};
        my $dataRef = $i->{'attribute'}->{'Reference_seq'};
        my $dataVar = $i->{'attribute'}->{'Variant_seq'};

        # check the tabix file for matching regions
        my $iter = $tab->query( $chr, $start - 1, $end + 1 );

        while ( my $read = $tab->read($iter) ) {
            my @rsMatch = split /\t/, $read;
            my $dbChr   = $rsMatch[0];
            my $dbStart = $rsMatch[1];
            my $rsid    = $rsMatch[2];
            my $dbRef   = $rsMatch[3];
            my $dbVar   = $rsMatch[4];

            # check if reference are the same.
            if ($dbRef ne $dataRef) { next }


            my (@db, @data);
            if ( $dbVar =~ /\,/ ){
                @db = split /\,/, $dbVar;
            }
            else { push @db, $dbVar }

            if ( $dataVar =~ /\,/ ){
                @data = split /\,/, $dataVar;
            }
            else { push @data, $dataVar }

            my %dbTable  = map { $_ => 1 } @db;
            my @matches = grep { $dbTable{$_} } @data;

            if ( scalar @matches ) {
               $i->{'attribute'}->{'clin'}->{'DNA_sequence_variation_identifier'} = "LOINC:48003-8 dbSNP:$rsid";
            }
        }
    }
    return $data;
}
##------------------------------------------------------------------------------

sub variantTypeCheck {
    my ( $self, $data ) = @_;
    warn "{Clinomic} Checking SO file.\n";

    my $so_table = {
      deletion            => "LOINC:48019-4 deletion:LA6692-3",
      deleted_sequence    => "LOINC:48019-4 deletion:LA6692-3",
      nucleotide_deletion => "LOINC:48019-4 deletion:LA6692-3",
      copy_number_loss    => "LOINC:48019-4 deletion:LA6692-3",
      indel               => "LOINC:48019-4 insertion-deletion:LA6688-1",
      duplication            => "LOINC:48019-4 duplication:LA6686-5",
      nucleotide_duplication => "LOINC:48019-4 duplication:LA6686-5",
      tandem_duplication     => "LOINC:48019-4 duplication:LA6686-5",
      transgenic_duplication => "LOINC:48019-4 duplication:LA6686-5",
      copy_number_gain       => "LOINC:48019-4 duplication:LA6686-5",
      insertion              => "LOINC:48019-4 insertion:LA6687-3",
      nucleotide_insertion   => "LOINC:48019-4 insertion:LA6687-3",
      transgenic_insertion   => "LOINC:48019-4 insertion:LA6687-3",
      inversion              => "LOINC:48019-4 inversion:LA6689-9",
      snv                    => "LOINC:48019-4 substitution:LA6690-7",
      mnp                    => "LOINC:48019-4 substitution:LA6690-7",
      snp                    => "LOINC:48019-4 substitution:LA6690-7",
      point_mutation         => "LOINC:48019-4 substitution:LA6690-7",
      transition                => "LOINC:48019-4 substitution:LA6690-7",
      transversion              => "LOINC:48019-4 substitution:LA6690-7",
      complex_substitution      => "LOINC:48019-4 substitution:LA6690-7",
      sequence_length_variation => "LOINC:48019-4 substitution:LA6690-7",
   };

    foreach my $i ( @{$data} ) {
        chomp $i;
        my $type = lc( $i->{'type'} );

        if ( $so_table->{$type} ) {
            $i->{'attribute'}->{'clin'}->{'DNA_sequence_change_type'} =
              $so_table->{$type};
        }
    }
    return $data;
}
##------------------------------------------------------------------------------

sub clinicalSig {
    my ( $self, $data ) = @_;
    warn "{Clinomic} Checking ClinVar file.\n";

    # create tabix object
    my $tab = Tabix->new( -data => $self->get_clin_tabix )
      || die "Cannot locate Clinvar Tabix file\n";

    # LA: loinc answers then commented out Clinvar numbering system meanings.
    my $sigLookup = {
      0   => 'unknown:LA6682-4',
      1   => 'unknown:LA6682-4',
      2   => 'benign:LA6675-8',
      3   => 'presumed_benign:LA6674-1',
      4   => 'presumed_benign:LA6669-1',
      5   => 'pathogenic:LA6668-3',
      6   => 'unknown:LA6682-4',
      7   => 'unknown:LA6682-4',
      255 => 'unknown:LA6682-4',
    };

    my $source_class = {
     0 => 'unknown:18197-6',
     1 => 'germline:6683-2',
     2 => 'somatic:6684-0',
    };

    # search for matches in gvf file.
    foreach my $i ( @{$data} ) {
        chomp $i;

        # Basic data needed from GVF file.
        my $gvfChr   = $i->{'seqid'};
        my $gvfStart = $i->{'start'};
        my $gvfEnd   = $i->{'end'};
        my $gvfRef   = $i->{'attribute'}->{'Reference_seq'};
        my $gvfVar   = $i->{'attribute'}->{'Variant_seq'};

        # check the tabix file for matching regions
        my $iter = $tab->query( $gvfChr, $gvfStart - 1, $gvfEnd + 1 );

        my %clinMatch;
        while ( my $read = $tab->read($iter) ) {

            # split the vcf line into parts.
            my @tabReturn = split( /\;/, $read );

            # capture then check chr, ref, var for correct match
            my @fst8 = split /\t/, $tabReturn[0];

            # get var from clinvar file and check that ref are of equal size
            my $varClin = $fst8[4];
            my $refClin = $fst8[3];
            unless (length $refClin eq length $gvfRef) { next }

            my (@clin, @gvf);
            if ( $varClin =~ /\,/ ){
                @clin = split /\,/, $varClin;
            }
            else { push @clin, $varClin }

            if ( $gvfVar =~ /\,/ ){
                @gvf = split /\,/, $gvfVar;
            }
            else { push @gvf, $gvfVar }

            my %clinTable  = map { $_ => 1 } @clin;
            my @matches = grep { $clinTable{$_} } @gvf;

            if ( scalar @matches ) {
              $varClin =~ s/\,//;
              my $index = index($varClin, $matches[0]);

              my @clin_find;
              foreach my $clin (@tabReturn) {
                next unless ( $clin =~ /(CLNSIG|CLNDSDB|CLNDSDBID)/ );

                $clin =~ /^(.*)=(.*)/g;
                my $tag   = $1;
                my $value = $2;

                # check if more then one value, if not change index.
                my @clinResults;
                if ( $value =~ /\,/ ){
                  @clinResults = split /\,/, $value;
                }
                else {
                  push @clinResults, $value;
                }
                if ( $tag eq 'CLNSIG'){
                  #next unless ($clinResults[$index]);
                  # quick change the numbers into loinc value
                  $clinResults[$index] =~ s/(\d+)/$sigLookup->{$1}/g;
                  push @clin_find, "LOINC:53037-8 $clinResults[$index]";
                }
                elsif ( $tag eq 'CLNDSDBID') {
                  #next unless ($clinResults[$index]);
                  push @clin_find, $clinResults[$index];
                }
                elsif ($tag eq 'CLNDSDB'){
                  #next unless ($clinResults[$index]);
                  push @clin_find, $clinResults[$index];
                }
              }
              my $clin_result = join(',', @clin_find) if scalar @clin_find >= 1;
              $i->{'attribute'}->{'clin'}->{'Genetic_disease_analysis_variation_interpreation'} = $clin_result;
            }
          }
    }
    return $data;
}
##------------------------------------------------------------------------------

sub allelicStateCheck {
  my ( $self, $data ) = @_;
  warn "{Clinomic} Checking allelic state.\n";

  my $answer = {
    hemizygous    => "LOINC:53034-5 hemizygous:LA6707-9",
    heteroplasmic => "LOINC:53034-5 heteroplasmic:LA6703-8",
    homoplasmic   => "LOINC:53034-5 homoplasmic:LA6704-6",
    heterozygous  => "LOINC:53034-5 heterozygous:LA6706-1",
    homozygous    => "LOINC:53034-5 homozygous:LA6705-3",
  };

  foreach my $i ( @{$data} ) {
    chomp $i;

    my $zyg    = $i->{'attribute'}->{'Zygosity'};
    my $varSeq = $i->{'attribute'}->{'Variant_seq'};

    if ($zyg) {
      $zyg =~ s/$zyg/$answer->{$zyg}/;
      $i->{'attribute'}->{'clin'}->{'Allelic_state'} = $zyg;
      next;
    }
    elsif ( $varSeq =~ /\,/ ) {
      my ( $a, $b ) = split /,/, $varSeq;

      my $state;
      ($b eq '!') ? $state = 'hemizygous' : $state = 'heterozygous';
      $state =~ s/$state/$answer->{$state}/;
      $i->{'attribute'}->{'clin'}->{'Allelic_state'} = $state;
    }
    else {
      my $remain = $answer->{'homozygous'};
      $i->{'attribute'}->{'clin'}->{'Allelic_state'} = $remain;
    }
  }
  return $data;
}
##------------------------------------------------------------------------------

sub regionFinder {
    my ( $self, $data ) = @_;
    warn "{Clinomic} Checking for region information.\n";

    # create tabix object
    my $tab = Tabix->new( -data => $self->get_gtf_tabix )
      || die "Cannot locate GTF Tabix file\n";

    # search for matches in gvf file.
    foreach my $i ( @{$data} ) {
        chomp $i;

        # Basic data needed from GVF file.
        my $gvfChr   = $i->{'seqid'};
        my $gvfStart = $i->{'start'};
        my $gvfEnd   = $i->{'end'};

        # check the tabix file for matching regions
        my $iter = $tab->query( $gvfChr, $gvfStart - 1, $gvfEnd + 1 );

        my %regions;
        while ( my $read = $tab->read($iter) ) {
            my @columns = split /\t/, $read;
            my @atts    = split /;/,  $columns[8];

            next if ( $columns[2] eq 'CDS' );

            my ( undef, $feature ) = ( $atts[2] =~ /(\S+)\s+\"(\d+)\"/ );
            my ( undef, $trans )   = ( $atts[5] =~ /(\S+)\s+\"(\S+)\"/ );

            push @{ $regions{ $columns[2] } },
              {
                feature_number => $feature,
                id             => $gvfStart,
                transcript     => $trans,
              };
        }

        my $clinRegion;
        while ( my ( $feature, $matches ) = each %regions ) {
            foreach my $fd ( @{$matches} ) {
              # based on the current version gtf file, only exon and start/stop
              # condons exist.
                if ( $feature eq 'exon' ) {
                    my $addLine = "$feature $fd->{feature_number} $fd->{transcript},";
                    $clinRegion .= $addLine;
                }
                else {
                    my $addLine = "$feature $fd->{transcript},";
                    $clinRegion .= $addLine;
                }
            }
        }
        # add data to gvf reference
        if ($clinRegion) {
            $clinRegion =~ s/\,$//g;
            $i->{'attribute'}->{'clin'}->{'DNA_region_name'} = "LOINC:47999-8 region:$clinRegion";
        }
    }
    return ($data);
}
##------------------------------------------------------------------------------

sub hgvsDNACheck {
    my ( $self, $data ) = @_;
    warn "{Clinomic} Checking for hgvs DNA matches.\n";

    ## list of accepted types. Must be SO sequence_alteration child and hgvs accepted.
    my $soType = {
      snv           => 1,
      deletion      => 1,
      duplication   => 1,
      insertion     => 1,
      indel         => 1,
      inversion     => 1,
    };

    foreach my $i ( @{$data} ) {
        chomp $i;

        # need ref id to make HGVS notation.
        next unless ($i->{'attribute'}->{'clin'}->{'Genomic_reference_sequence_identifier'});
        my $genoRef = $i->{'attribute'}->{'clin'}->{'Genomic_reference_sequence_identifier'};

        # get the ref id back from the LOINC notation
        my ($ref_id) = $genoRef =~ /LOINC:48013-7 NCBI:(\S+)/;

        # the gvf kids are all here.
        my $start = $i->{'start'};
        my $end   = $i->{'end'};
        my $var   = $i->{'attribute'}->{'Variant_seq'};
        my $ref   = $i->{'attribute'}->{'Reference_seq'};
        my $type  = lc($i->{'type'});

        if ($type eq 'complex_substitution') {
          $type =~ s/complex_substitution/snv/;
        }
        if ( $type eq 'nucleotide_deletion') {
          $type =~ s/nucleotide_deletion/deletion/;
        }

        # skip if type is not one which is defined yet.
        if ( ! $soType->{$type} ) {
          warn "{Clinomic} WARN: change type $type is not an accepted SO or HGVS type. HGVS annotation will not be added.\n";
        }

        # collect the hets for insertion
        my (@var_seq, @gvf);
        if ( $var =~ /\,/ ){
          @var_seq = split /\,/, $var;
        }
        else { push @var_seq, $var }

        # get the index of the variant
        if ( $var =~ /\,/ ) { $var =~ s/\,// }
        my $pos = index($var, $ref);

        # create the index
        my $index;
        if    ($pos == 0)  { $index = 1 }
        elsif ($pos == 1)  { $index = 0 }
        elsif ($pos == -1) { $index = 0 }

        # just keep the correct index var to make hgvs.
        $var = substr $var, $index, 1;

        if ( $type eq 'snv') {
            my $hgvsS = "$ref_id:g.$start$ref>$var";
            $i->{'attribute'}->{'clin'}->{'DNA_sequence_variation'} = "LOINC:48004-6 HGVS:$hgvsS";
        }
        elsif ( $type eq 'deletion' ) {
            my $hgvsD = "$ref_id:g.$start" . "_" . "$end" . "del$ref";
            $i->{'attribute'}->{'clin'}->{'DNA_sequence_variation'} = "LOINC:48004-6 HGVS:$hgvsD";
        }
        elsif ( $type eq 'duplication' ) {
            my $hgvsDp = "$ref_id:g.$start" . "_" . "$end" . "dup";
            $i->{'attribute'}->{'clin'}->{'DNA_sequence_variation'} = "LOINC:48004-6 HGVS:$hgvsDp";
        }
        elsif ( $type eq 'insertion' ) {
            my $hgvsIn = "$ref_id:g.$start" . "_" . "$end" . "ins$var_seq[$index]";
            $i->{'attribute'}->{'clin'}->{'DNA_sequence_variation'} = "LOINC:48004-6 HGVS:$hgvsIn";
        }
        elsif ( $type eq 'indel' ) {
            my $hgvsIn = "$ref_id:g.$start" . "_" . "$end" . "delins$var";
            $i->{'attribute'}->{'clin'}->{'DNA_sequence_variation'} = "LOINC:48004-6 HGVS:$hgvsIn";
        }
        elsif ( $type eq 'inversion' ) {
            my $hgvsIn = "$ref_id:g.$start" . "_" . "$end" . "inv$var";
            $i->{'attribute'}->{'clin'}->{'DNA_sequence_variation'} = "LOINC:48004-6 HGVS:$hgvsIn";
        }
    }
    return $data;
}
##------------------------------------------------------------------------------

sub hgvsProtCheck {
    my ($self, $data) = @_;
    warn "{Clinomic} Checking for hgvs protein matches.\n";

    ####my $table = Bio::Tools::CodonTable->new();

    ## list of accepted types. Must be SO sequence_alteration child and hgvs accepted.
    my $soType = {
      snv           => 1,
      deletion      => 1,
      duplication   => 1,
      insertion     => 1,
      indel         => 1,
      inversion     => 1,
    };

    foreach my $i ( @{$data} ){
        # the gvf kids again.
        ##my $start = $i->{'start'};
        ###my $end   = $i->{'end'};
        my $type  = lc($i->{'type'});

        my $vCode = $i->{'attribute'}->{'Variant_codon'};
        my $vAA   = $i->{'attribute'}->{'Variant_aa'};
        my $rCode = $i->{'attribute'}->{'Reference_codon'};
        my $rAA   = $i->{'attribute'}->{'Reference_aa'};

        # skip if no codon/aa and type is not one which is defined yet.
        next unless ($vCode or $vAA and $rCode or $rAA);
        next unless ($soType->{$type});

        # get the index of the variant
        if ( $vAA =~ /\,/ ) { $vAA =~ s/\,// }
        my $pos = index($vAA, $rAA);

        # create the index of the variant from the index return of reference match
        my $index;
        ($pos == '0') ? $index  = 1 :
        ($pos == '1') ? $index  = 0 :
        ($pos == '-1') ? $index = 0 : die "cannot index postion the variant\n";

        # just keep the correct index var to make hgvs.
        my $var = substr $vAA, $pos, 1;

        my $ref_name = $self->aaSLC3Letter($rAA);
        my $var_name = $self->aaSLC3Letter($var);

        if ($var eq $rAA ) {
          $i->{'attribute'}->{'clin'}->{'Amino_acid_change'} = "LOINC:48005-3 HGVS:p.(=)";
        }
        elsif ($type eq 'deletion'){
          ###$line .= "$genoRef:p.$refName$start" ."del," unless $sameSeq eq 0;
        }
        elsif ($type eq 'duplication'){
          ##$line .= "$genoRef:g.$refName$start" . "_" . "$varName$end" . "dup," unless $sameSeq eq 0;
        }
        elsif ($type eq 'insertion'){
          ###$line .= "$genoRef:g.$refName$start" . "_" . "$varName$end" . "ins," unless $sameSeq eq 0;
        }
        #$i->{'attribute'}->{'clin'}->{'Clin_HGVS_protein'} = $line;
    }
    return $data;
}
##------------------------------------------------------------------------------

no Moose;
1;

=head1 NAME:

Clinomic::Builder

=head1 DESCRIPTION

...

=head1 FUNCTIONS

=head2 gvfParser

    Title   : gvfParser
    Usage   : $obj->gvfParser;
    Function: Creates a data structure for each feature line of the GVF files.
    Returns : Arrayref of hashrefs of each of the feature lines.


=head2 gvfRelationBuild

    Title   : gvfRelationBuild
    Usage   : $obj->gvfRelationBuild(GVF arrayref);
    Function: Wrapper method.
              Currently Runs:
                gvfValadate
                gvfGeneFind
                gvfRefBuild
                snpCheck
                soTypeCheck
                sigfCheck
                allelicCheck
    Returns : Arrayref of updated GVF file.


=head2 gvfValadate

    Title   : gvfValadate
    Usage   : $obj->gvfValadate(GVF arrayref);
    Function: Compares reference sequence entered to current genome build for accuracy.
              Script will automatically fail if reference match is below 90%.
              This can be changed if --validate is changed or --ref_update is used.
    Returns : Void.


=head2 gvfGeneFind

    Title   : gvfGeneFind
    Usage   : $obj->gvfGeneFind(GVF arrayref);
    Function: Takes parsed GVF file and searches for genes based on chromosome,
              start and end position.  Method uses a indexed version of GRCh37.p5_top_level.gff3.
    Returns : Arrayref of updated GVF file.


=head2 gvfRefBuild

    Title   : gvfRefBuild
    Usage   : $obj->gvfRefBuild(GVF arrayref);
    Function: Data Currently added:
                Clin_gene
                Clin_genomic_reference,
                Clin_HGVS_protein 
    Returns : Arrayref of updated GVF file.

=head2 snpCheck

    Title   : snpCheck
    Usage   : $obj->snpCheck(GVF arrayref);
    Function: Check indexed dbsnp file and adds rsid to Clin_variant_id to GVF file.
    Returns : Arrayref of updated GVF file.


=head2 soTypeCheck

    Title   : soTypeCheck
    Usage   : $obj->soTypeCheck(GVF arrayref);
    Function: Check list of SO sequence_alteration terms via feature type
              if match occurs will update Clin_variant_type term.
    Returns : Arrayref of updated GVF file.


=head2 sigfCheck

    Title   : sigfCheck
    Usage   : $obj->sigfCheck(GVF arrayref);
    Function: Will check GeneDatabase.db for known clinical significance
              and add to Clin_disease_variant_interpret tag.  Will also
              update any Clin_variant_id if present.
    Returns : Arrayref of updated GVF file.


=head2 allelicCheck

    Title   : allelicCheck
    Usage   : $obj->allelicCheck(GVF arrayref);
    Function: Will check for zygosity, if present will add to Clin_allelic_state
              or will infer based on Variant_seq.
    Returns : Arrayref of updated GVF file.


=head1 INTERNAL FUNCTIONS


=head2 _pragmas

    Title   : _pragmas
    Usage   : $obj->_pragmas;
    Function: Internal method to parse pragma information and store it
              in the object.
    Returns : Void (Stored in object).

=head2 _termUpdate

    Title   : _termUpdate
    Usage   : $obj->_termUpdate(GVF arrayref);
    Function: Uses command line information to switch current tag in attribute
              to Clin term.
    Returns : Arrayref of updated GVF file.

