package GVF::ClinBuilder;
use Moose;
use Tabix;
use Bio::DB::Fasta;
use File::Basename;

extends 'GVF::Clin';
with 'MooseX::Getopt';

use lib '../lib';

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
    documentation => q(Validate percentage compared to reference genome(hg19.fa).  Seqid much be in form chr#.  Default is 80%. ),
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

has 'tabix_clinvar' => (
    is      => 'rw',
    isa     => 'Str',
    reader  => 'get_clin_tabix',
    default => '../data/ClinVar/clinvar_20120616.vcf.bgz',
    documentation => q(Tabix created file to search for Clin_disease_variant_interpret based on GVF files coordinates, and RSID),
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
    documentation => q(Allows change in feature attribute tag from term to GVFClin term.  Example: disease=Clin_disease_interpret.),
);

has 'export' => (
    is      => 'rw',
    isa     => 'Str',
    reader  => 'get_export',
    default => 'gvfclin',
    documentation => q(Export GVF data to various formats.  Options: gvfclin, xml, hl7, all.  Default is gvfclin.)
);

has 'ref_update' =>(
    is        => 'rw',
    isa       => 'Bool',
    #default   => '0',
    predicate => 'updateRef',
    documentation => q(Allows in-place change of reference sequence to match current build. Options are 1 or 0, default is 0.  If this option is used validate option not needed.),
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

sub gvfParser {
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
        
        my $gvfRef = uc($i->{'attribute'}->{'Reference_seq'});
        
        if ( $gvfRef eq '-'){ $noRef++; next; }
        
        # call to Bio::DB. 
        my $bioSeq = $db->seq("$chr:$start..$end");
        $bioSeq = uc($bioSeq);
        
        if ( $bioSeq eq $gvfRef ) {
            $correct++;
        }
        else {
            $mismatch++;
            # if user wants to update ref to current build this is where it happens.
            if ( $self->updateRef ) {
                $i->{'attribute'}->{'Reference_seq'} = $bioSeq;
                $correct++;
            }
        }
    }

    # check if passes default/given value.
    if ( $mismatch == $total ) { die "No matches were found, possible no Reference_seq in file\n";}
    my $value = ($correct/($total-$noRef)) * 100;
    
    return \$value;
}

#------------------------------------------------------------------------------

sub geneFind {
    
    my ($self, $gvf) = @_;

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

    # add db clin informaton to gvf file.
    foreach my $t (@{$gvf}) {
        
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
    
    # Call to add rsid from dbSNP file if found and disease_variant_interpret
    # from GeneDatabase.  
    my $clinGVF = $self->_snpMatch($gvf);
    $clinGVF    = $self->_typeCheck($gvf);
    $clinGVF    = $self->_sigCheck($gvf);

    return $clinGVF;
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
        
        my $gvfRef   = $i->{'attribute'}->{'Reference_seq'};
        my $gvfVar   = $i->{'attribute'}->{'Variant_seq'};
        
        # check the tabix file for matching regions
        my $iter = $tab->query($chr, $start - 1, $end + 1);
        
        while (my $read = $tab->read($iter)) {
            
            my @rsMatch = split /\t/, $read;
            my $chr2   = $rsMatch[0];
            my $start2 = $rsMatch[1];
            my $rsid   = $rsMatch[2];
            my $ref    = $rsMatch[3];
            my $var    = $rsMatch[4];
            
            # first step clean up
            if ( $ref ne $gvfRef) { next }
            
            if ($var =~ /\,{1,}/){
                my @refvars = split/,/, $var;
                foreach (@refvars){
                    if ( $_ eq $gvfVar){
                        $var = $_;
                    }
                }
            }
            # add rsid file to gvf if found
            if ($start eq $start2 && $gvfVar eq $var){
                $i->{'attribute'}->{'clin'}->{'Clin_variant_id'} = $rsid;
            }
        }
    }
    return $gvf;
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

sub _sigCheck {
    my ($self, $gvf) = @_;
    
    my $xcl = $self->get_dbixclass;
    
    # hashref of concept => { disease, gene }
    my $concept = $self->_conceptList;

    # capture data from GeneDatabase sqlite3 file.
    my $clindb = $xcl->resultset('Clinvar_clin_sig');
    
    my %clin;
    while ( my $rt = $clindb->next ){
    
        $clin{$rt->location} = {
            ref     => $rt->ref_seq,
            var     => $rt->var_seq,
            rsid    => $rt->rsid,
            sig     => $rt->clnsig,
            cui     => $rt->clncui,
            hgvsDNA => $rt->clnhgvs,
        };
    }
    # search for matches in gvf file.
    foreach my $i ( @{$gvf} ){
        my $gstart  = $i->{'start'};
        my $gvfGene = $i->{'attribute'}->{'clin'}->{'Clin_gene'};
        
        if ( $clin{$gstart} ){
            # make results easy to match with.
            my $matchRef = $i->{'attribute'}->{'Reference_seq'};
            my $matchVar = $i->{'attribute'}->{'Variant_seq'};
            my $clinRef  = $clin{$gstart}->{'ref'};
            my $clinVar  = $clin{$gstart}->{'var'};
            my $clinOmim = $clin{$gstart}->{'omim'};
            
            # give me what I want!
            next unless ( $matchRef eq $clinRef && $matchVar eq $clinVar );
            
            # what to add.
            my $clinSig  = $clin{$gstart}->{'sig'};
            my $clinCui  = $clin{$gstart}->{'cui'};
            
            # will take clinCui and split it into parts
            my $sep = $self->_conceptSplit($clinCui, $concept);

            #search clinvar disease names            
            my $dName;
            foreach my $i ( @{$sep} ){
                if ( $concept->{$i} && $concept->{$i}->{'gene'} eq $gvfGene ){
                    $dName .= "$concept->{$i}->{'disease'}|";
                }
                else { next; }
            }
            $dName =~ s/\|$//g if $dName;
            
            # change numbers into values.            
            my $pMatch = {
                0 => 'unknown',
                1 => 'unknown',
                2 => 'benign',
                3 => 'presumed_benign',
                4 => 'presumed_pathogenic',
                5 => 'pathogenic',
                6 => 'unknown',
                7 => 'unknown',
                255 => 'unknown',
            };
            
            # split up and change the sig values.  
            my $sigValue;
            if ( $clinSig =~ /^(\d+)$/ ) {
                if ($pMatch->{$1}){
                    $sigValue = "$pMatch->{$1}";
                }
            }
            elsif ($clinSig =~ /(\d+\|(.*)$)/ ) {
                my @numList = split/\|/, $1;
                
                my $sigUpd;
                foreach (@numList){
                    if ($pMatch->{$_}){
                        $sigUpd .= "$pMatch->{$_},";
                    }
                }
                $sigUpd =~ s/^(.*),$/$1/;
                $sigValue = $sigUpd;
            }
            # add discovered items to gvfclin file.
            $i->{'attribute'}->{'clin'}->{'Clin_HGVS_DNA'} = $clin{$gstart}->{'hgvsDNA'};
            $i->{'attribute'}->{'clin'}->{'Clin_variant_id'} = $clin{$gstart}->{'rsid'};
            $i->{'attribute'}->{'clin'}->{'Clin_disease_variant_interpret'} = "$sigValue $dName";
        }
    }        
    return $gvf;
}

#------------------------------------------------------------------------------

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

#------------------------------------------------------------------------------

no Moose;
1;

