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
    required => 1,
    documentation => q(This is the location of the GVF file you want to convert to GVFClin. Only required option.),
);

has 'fasta_file' => (
    is      => 'rw',
    isa     => 'Str',
    reader  => 'get_fasta',
    default => '../data/genomes/hg19.fa',
    documentation => q(The location of desired reference fasta file.  Default is hg19.fa),
);

has 'validate' => (
    is      => 'rw',
    isa     => 'Int',
    reader  => 'get_percent',
    default => '80',
    documentation => q(Validate percentage compared to reference genome(ref_GRCh37).  Seqid much be in form chr#.  Default is 80%. ),
);

has 'tabix_gene' => (
    is      => 'rw',
    isa     => 'Str',
    reader  => 'get_gene_tabix',
    default => '../data/genomes/GRCh37.p5_top_level.gff3.bgz',
    documentation => q(Tabix created file to search for genes based on GVF files coordinates.),
);

has 'tabix_dbsnp' => (
    is      => 'rw',
    isa     => 'Str',
    reader  => 'get_db_tabix',
    default => '../data/dbSNP/dbsnp.bgz',
    documentation => q(Tabix created file to search for RSIDs based on GVF files coordinates.),
);

has 'pragma' => ( 
    traits    =>['NoGetopt'],
    is        => 'rw',
    isa       => 'HashRef',
    writer    => 'set_pragmas',
    reader    => 'get_pragmas',
    predicate => 'has_pragmas',
);

has 'tag_switch' => (
    traits    => ['Hash'],
    is        => 'rw',
    isa       => 'HashRef',
    predicate => 'need_switch',
    handles => {
        termExist => 'exists',
        access    => 'accessor',
    },
    documentation => q(Allows change in feature attribute tag from term to GVFClin term.  Example: Classification=Clin_disease_interpret.),
);

has 'export' => (
    is      => 'rw',
    isa     => 'Str',
    reader  => 'get_export',
    default => 'GVFClin',
    documentation => q(Export new GVFClin data via GVFClin, XML or Both.  Default GVFClin.)
);

# rewrite dbixclass att to use with builder scripts.
has '+dbixclass' => (
    traits  => ['NoGetopt'],
    default => sub {
        my $self = shift;
        my $dbix;
        my $file = basename($self->get_file);
        $file =~ s/()\.gvf/$1.db/;
    
        if ( -f "$file" ){
            $dbix = GVF::DB::Connect->connect({
                    dsn =>"dbi:SQLite:$file",
                    on_connect_do => "ATTACH DATABASE 'GeneDatabase.db' as GeneDatabase"
            });
        }
        else {
            system("sqlite3 $file < ../data/mysql/GVFClinSchema.sql");
            $dbix = GVF::DB::Connect->connect({
                    dsn =>"dbi:SQLite:$file",
                    on_connect_do => "ATTACH DATABASE 'GeneDatabase.db' as GeneDatabase"
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
    
    # extract out pragmas and store them in object;
    $self->_pragmas;
    
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
            attribute => {
                %{$value}
            },
        };
        push @return_list, $feature;
    }
    return \@return_list;
}

#-----------------------------------------------------------------------------

sub _pragmas {
    my $self = shift;
    
    # grab only pragma lines
    my $pragma_line = $self->_file_splitter('pragma');
        
    my %p;
    foreach my $i( @{$pragma_line} ) {
        chomp $i;
        
        my ($tag, $value) = $i =~ /##(\S+)\s?(.*)$/g;
        $tag =~ s/\-/\_/g;
        
        $p{$tag} = [] unless exists $p{$tag};
    
        # if value has multiple tag value pairs, split them.
        if ( $value =~ /\=/){
            my @lines = split/;/, $value;
            
            my %test;
            map {
                my($tag, $value) = split/=/, $_;
                $test{$tag} = $value;
            }@lines;
            $value = \%test
        }
        push @{$p{$tag}}, $value;
    }
    $self->set_pragmas(\%p);
}

#-----------------------------------------------------------------------------

sub gvfValadate {
    my ($self, $data) = @_;
    
    # db handle and indexing fasta file.
    my $db = Bio::DB::Fasta->new( $self->get_fasta, -debug=>1 ) || die "Fasta file not found $@\n";
    
    my ( $correct, $mismatch, $total);
    my $noRef = 0;
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
    if ( $mismatch == $total ) { die "No matches were found, possible no Reference_seq in file\n";}
    my $value = ($correct/($total-$noRef)) * 100;
    
    return \$value;
}

#------------------------------------------------------------------------------

sub geneFind {
    
    my ($self, $gvf) = @_;
    ##my $xcl = $self->get_dbixclass;

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
    my $tab = Tabix->new(-data => $self->get_gene_tabix) || die "Please input gene Tabix file\n";

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
        else {
            push @updateGVF, $i;
        }
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
            transcript  => $i->transcript_refseq, 
            omim        => $i->omim_id,
        }] unless exists $genedata{$i->symbol};
        
        my $ref = $i->refseq;
        while (my $r = $ref->next){
            push @{$genedata{$i->symbol}}, {
                genomic_ref  => $r->genomic_refseq,
                HGVS_protein => $r->protein_refseq,
            };
        }
    }
    # Call to add rsid from dbSNP file if found.
    my $clinGVF = $self->_snpMatch($gvf);    

    # add db clin informaton to gvf file.
    foreach my $t (@{$clinGVF}) {
        
        # Collect gene name from gvf file
        my $gene;
        foreach ( @{$t->{'attribute'}->{'Variant_effect'}} ) {
            if( $_->{'feature_type'} eq 'gene') {
                $gene = $_->{'feature_id1'};
                last;
            }
            else { next }
        }
        
        # search the db for matching gene names, and add all clin data
        # to working gvf file
        if ( $genedata{$gene} ){
            my $ref = $genedata{$gene};
            
            my $clin = {
                Clin_gene              => $gene,
                Omim_id                => $ref->[0]->{'omim'},
                Clin_transcript        => $ref->[0]->{'transcript'},
                Clin_genomic_reference => $ref->[1]->{'genomic_ref'},
                Clin_HGVS_protein      => $ref->[1]->{'HGVS_protein'},
            };
            $t->{'attribute'}->{'clin'} = $clin;
        }
    }
    $clinGVF = $self->_typeCheck($gvf);
    return $clinGVF;
}

#------------------------------------------------------------------------------

sub _snpMatch {
    my ($self, $gvf) = @_;
    
    # create tabix object
    my $tab = Tabix->new(-data => $self->get_db_tabix) || die "Please input dbSNP Tabix file\n";
    
    foreach my $i (@{$gvf}){
    
        my $chr;
        if ( $i->{'seqid'} !~ /^chr/i ){ $chr = "chr". $i->{'seqid'}; }
        else { $chr = $i->{'seqid'}; }
        
        my $start = $i->{'start'};
        my $end   = $i->{'end'};

        # check the tabix file for matching regions
        my $iter = $tab->query($chr, $start - 1, $end + 1);
        
        while (my $read = $tab->read($iter)) {
            
            my @rsMatch = split /\t/, $read;
            my $chr2   = $rsMatch[0];
            my $start2 = $rsMatch[1];
            my $rsid   = $rsMatch[2];
            my $ref    = $rsMatch[3];
            my $var    = $rsMatch[4];
            
            # add rsid file to gvf if found
            if ($i->{'start'} eq $start2){
                $i->{'attribute'}->{'Clin_variant_id'} = $rsid;
            }
        }
    }
    return $gvf;
}

#------------------------------------------------------------------------------

sub termUpdate {
    my ($self, $gvf) = @_;

    # Takes the list of values from term_switch and looks in $gvf hash
    # for the value, then replaces with new key and deletes the old one.
    my @returnList;
    foreach my $i ( @{$gvf} ){
    
        while ( my($k, $v) = each %{$i->{'attribute'}} ){
            if ( $self->termExist($k) ){
                $i->{'attribute'}->{'clin'}->{$self->access($k)} = $v;
                delete $i->{'attribute'}->{$k};
            }
        }
        push @returnList, $i; 
    }
    return \@returnList;
}

#------------------------------------------------------------------------------

sub _typeCheck {
    my ($self, $gvf) = @_;
    
    my @variantType = qw(deletion wild-type duplication insertion
                         inversion substitution indel);

    foreach my $i (@{$gvf}){
        chomp $i;
        
        my $type = lc($i->{'type'});
        
        foreach (@variantType){
            if ($type eq $_){
                $i->{'attribute'}->{'clin'}->{'Clin_variant_type'} = $type;
            }
        }
    }
    return $gvf;
}

#------------------------------------------------------------------------------

1;

