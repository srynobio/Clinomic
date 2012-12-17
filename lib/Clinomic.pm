package Clinomic; 
use Moose;
use Tabix;
use IO::File;
use List::Util qw(first);
use Bio::DB::Fasta;
use Bio::Tools::CodonTable;  
use File::Basename;

with 'Clinomic::Roles';
with 'MooseX::Getopt';

#-----------------------------------------------------------------------------
#------------------------------- Attributes ----------------------------------
#-----------------------------------------------------------------------------

has 'data_directory' => (
    traits    =>['NoGetopt'],
    is       => 'rw',
    isa      => 'Str',
    default  => '../data/',
    writer   => 'set_directory',
    reader   => 'get_directory',
);

has 'file' => (
    is       => 'rw',
    isa      => 'Str', 
    reader   => 'get_file',
    writer   => 'set_file',
    required => 1,
    documentation => q(REQUIRED.  Path to the GVF file you want to convert to Clinical document.
    )
);

has 'fasta_file' => (
    is       => 'rw',
    isa      => 'Str',
    reader   => 'get_fasta',
    default  => '../data/Fasta/hg19.fa',
    documentation => q(Path to the fasta reference file used for reference validation.  Default is hg19.
    )
);

has 'gff_file' => (
    traits    =>['NoGetopt'],
    is       => 'rw',
    isa      => 'Str',
    reader   => 'get_gff',
    default  => '../data/GFF/Updated.ref_GRCh37.gff3.gz',
);

has 'validate' => (
    is      => 'rw',
    isa     => 'Int',
    reader  => 'get_percent',
    default => '90',
    documentation => q(Validate percentage compared to reference genome fasta file.  Default is 90%.
    ),
);

has 'tabix_dbsnp' => (
    traits    =>['NoGetopt'],
    is      => 'rw',
    isa     => 'Str',
    reader  => 'get_db_tabix',
    default => '../data/dbSNP/Updated.00-All.vcf.gz',
);

has 'tabix_clinsig' => (
    traits    =>['NoGetopt'],
    is      => 'rw',
    isa     => 'Str',
    reader  => 'get_clin_tabix',
    default => '../data/ClinVar/clinvar_sig.vcf.gz',
);

has 'tabix_gtf' => (
    traits    =>['NoGetopt'],
    is      => 'rw',
    isa     => 'Str',
    reader  => 'get_gtf_tabix',
    default => '../data/GTF/Homo_sapiens.gtf.gz',
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
    documentation => q(Change user attribute tag to a Clin accepted tag.  Example: disease -> Clin_disease_interpret.
    ),
);

has 'export' => (
    is      => 'rw',
    isa     => 'Str',
    reader  => 'get_export',
    default => 'gvfclin',
    documentation => q(Export GVF file to various formats.  Options: gvfclin, xml, hl7, all.  Default is gvfclin.
    )
);

has 'revise_ref' => (
    is        => 'rw',
    isa       => 'Bool',
    predicate => 'updateRef',
    documentation => q(Allows in-place change of reference sequence to match current build. Options are 1 or 0, default is 0.  If this option is used validate option is not required.),
);

#-----------------------------------------------------------------------------
#------------------------------- Methods -------------------------------------
#-----------------------------------------------------------------------------

sub gvfRelationBuild {
    my ($self, $data ) = @_;
    
    warn "{Clinomic} Valadating GVF file.\n";
    $self->gvfValadate($data);
    warn "{Clinomic} Building gene relationships.\n";
    my $stp0 = $self->gvfGeneFind($data);
    warn "{Clinomic} Checking refseq files.\n";
    my $stp1 = $self->gvfRefBuild($stp0);
    warn "{Clinomic} Checking dbSNP file.\n";
    my $stp2 = $self->snpCheck($stp1);
    warn "{Clinomic} Checking SO file.\n";
    my $stp3 = $self->variantTypeCheck($stp2);
    warn "{Clinomic} Checking ClinVar file.\n";
    my $stp4 = $self->clinicalSig($stp3);
    warn "{Clinomic} Checking allelic state.\n";
    my $stp5 = $self->allelicStateCheck($stp4);
    warn "{Clinomic} Checking for hgvs DNA matches.\n";
    my $stp6 = $self->hgvsDNACheck($stp5);
    warn "{Clinomic} Checking for region information.\n";
    my $stp7 = $self->regionFinder($stp6);
    
=cut
    warn "Checking for hgvs protein matches.\n";
    #my $stp7 = $self->hgvsProtCheck($stp6);
=cut

    return $stp7;
}

#-----------------------------------------------------------------------------

sub gvfValadate {
    my ($self, $data) = @_;
    
    # db handle and indexing fasta file.
    my $db = Bio::DB::Fasta->new( $self->get_fasta, -debug=>1 ) || die "Fasta file not found $@\n";
    
    my ( $correct, $mismatch, $total);
    my @report;
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
        
        my $dataRef = uc($i->{'attribute'}->{'Reference_seq'});
        if ( $dataRef eq '-'){ $noRef++; next; }

        # check that the strand matches.
        #ccmy $strand  = $i->{'strand'};
        my $strand  = ( defined ($i->{'strand'}) ? $i->{'strand'} : 'NULL' );
        if ( $strand eq '-' ) { tr/ACGT/TGCA/ }
        
        # call to Bio::DB. 
        my $bioSeq = $db->seq("$chr:$start..$end");
        $bioSeq = uc($bioSeq);
        
        if ( $bioSeq eq $dataRef ) {
            $correct++;
        }
        else {
            $mismatch++;
            # if ref does not match collect it and add to report 
            my $result = "$chr\t$start\t$end\tFasta_Seq: $bioSeq\tFile_Seq: $dataRef\n";
            push @report, $result;
            
            # if user wants to update ref to current fasta build this is where it happens.
            if ( $self->updateRef ) {
                $i->{'attribute'}->{'Reference_seq'} = $bioSeq;
                $correct++;
            }
        }
    }
    
    ## print out report of incorect reference seq.
    if ( scalar @report > 1 ){
        my ($file, $path) = fileparse( $self->get_file );
        $file =~ s/(\S+).gvf/$1.report/g;
        
        my $reportFH  = IO::File->new($file, 'a+') || die "canto file\n";
        
        print $reportFH "## Unmatched Reference for $file ##\n";
        foreach (@report){
            chomp $_;
            print $reportFH "$_\n";
        }
    }
    
    # check if passes default/given value.
    if ( $mismatch == $total ) { die "No matches were found, possible no Reference_seq in file\n";}
    my $value = ($correct/($total-$noRef)) * 100;
    
    if ( $value <= $self->get_percent) {
    die sprintf ("
    Reference sequence does not validate to %s%%,
    Check file or enter lower validate value.
    RESULTS: %s matches %5.2f%% to reference.\n\n", $self->get_percent, $self->get_file, $value);
    }
}

#------------------------------------------------------------------------------

sub gvfGeneFind {
    
    my ($self, $data) = @_;

    # build hgnc approved gene list.
    my $ncbi = $self->hgncGene;

    # create tabix object
    my $tab = Tabix->new(-data => $self->get_gff) || die "Cannot locate GFF Tabix file\n";
    
    # search the golden set file for a match
    my @updateGVF;
    foreach my $i (@{$data}) {

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
                        my $geneMatch = ( $ncbi->{$value} ) ? $ncbi->{$value} : 'NULL';
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

sub gvfRefBuild {
    my ($self, $data) = @_;

    my $refInfo = $self->refseq;

    # add db clin informaton to gvf file.
    foreach my $t (@{$data}) {
        
        # Collect gene name from gvf file
        my $gene;
        foreach ( @{$t->{'attribute'}->{'Variant_effect'}} ) {
            if( $_->{'feature_type'} eq 'gene') {
                $gene = $_->{'feature_id1'};
                last;
            }
            else { next }
        }
        unless ($gene) { next }
        
        # search the db for matching gene names, and add all clin data
        # to working gvf file

        if ( $refInfo->{$gene} ){
            my $clin = {
                Clin_gene              => $gene,
                Clin_genomic_reference => $refInfo->{$gene}->{genomic_acc},
            };
            $t->{'attribute'}->{'clin'} = $clin;
        }
    }
    return $data;
}

#------------------------------------------------------------------------------

sub snpCheck {
    my ($self, $data) = @_;
    
    # create tabix object
    my $tab = Tabix->new(-data => $self->get_db_tabix) || die "Cannot locate dbSNP Tabix file\n";
    
    foreach my $i (@{$data}){
    
        my $chr;
        if ( $i->{'seqid'} !~ /^chr/i ){ $chr = "chr". $i->{'seqid'}; }
        else { $chr = $i->{'seqid'}; }
        
        my $start   = $i->{'start'};
        my $end     = $i->{'end'};
        my $dataRef = $i->{'attribute'}->{'Reference_seq'};
        my $dataVar = $i->{'attribute'}->{'Variant_seq'};
        
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
            if ( $ref ne $dataRef) { next }
            
            my $refVar;
            if ( $var =~ /\,/ ){
                my @refVars = split /,/, $var;
                map {
                    if ($_ eq $dataVar){
                        $refVar = $dataVar;
                    }
                }@refVars;
            }
            else { $refVar = $var; }
            
            # add rsid file to gvf if found
            if ($start eq $start2 && $dataVar eq $var){
                $i->{'attribute'}->{'clin'}->{'Clin_variant_id'} = $rsid;
            }
        }
    }
    return $data;
}

#------------------------------------------------------------------------------

sub variantTypeCheck {
    my ($self, $data) = @_;
    
    my $so_fh = IO::File->new('../data/SO/SO_LOINC.txt', 'r')
        || die "Can't open soTermSwitch.txt file\n";

    my %soMatch;
    foreach my $name (<$so_fh>) {
        chomp $name;
        my ($so, $loinc) = split/,/, $name;
        $soMatch{$so} = $loinc;
    }
     
    foreach my $i (@{$data}){
        chomp $i;
        my $type = lc($i->{'type'});
        
        if ($soMatch{$type}){
            $i->{'attribute'}->{'clin'}->{'Clin_variant_type'} = $soMatch{$type};
            $i->{'type'} = $soMatch{$type};
        }
    }
    return $data;
}

#------------------------------------------------------------------------------

sub clinicalSig {
    my ($self, $data) = @_;
    
    # create tabix object
    my $tab = Tabix->new(-data => $self->get_clin_tabix) || die "Cannot locate Clinvar Tabix file\n";

    # search for matches in gvf file.
    foreach my $i ( @{$data} ){
        chomp $i;
        
        my $gvfChr;
        if ( $i->{'seqid'} =~ /^chr/i ){
            $gvfChr = $i->{'seqid'};
            $gvfChr =~ s/^chr(\S+)/$1/g;
        }
        else { $gvfChr = $i->{'seqid'}; }
        
        # Basic data needed from GVF file.
        my $gvfStart = $i->{'start'};
        my $gvfEnd   = $i->{'end'};
        my $gvfRef   = $i->{'attribute'}->{'Reference_seq'};
        my $gvfVar   = $i->{'attribute'}->{'Variant_seq'};
        my $gvfRSID  = $i->{'attribute'}->{'clin'}->{'Clin_variant_id'};
        
        # check the tabix file for matching regions
        my $iter = $tab->query($gvfChr, $gvfStart - 1, $gvfEnd + 1);
        
        my %clinMatch;
        while (my $read = $tab->read($iter)) {

            # split the vcf line into parts.
            my @tabReturn = split(/\;/, $read);
       
            # capture then check chr, ref, var for correct match
            my @fst8 = split/\t/, $tabReturn[0];
            
            # this section will check for matches that have multiple variant
            # known, and see if user file matches any.
            my $clinVar;
            if ( $fst8[4] =~ /\,/ ){
                my @clinVars = split /,/, $fst8[4];
                map {
                    if ($gvfVar eq $_){
                        $clinVar = $gvfVar;
                    }
                }@clinVars;
            }
            else { $clinVar = $fst8[4]; }

            # just let matches go through
            unless ( $gvfRef eq $fst8[3] && $gvfVar eq $clinVar ) { next }
            
            foreach ( @tabReturn ){
                unless ( $_ =~ /^CLN/ ) { next }
               
                $_ =~ /^(.*)=(.*)/g;
                my $tag   = $1;
                my $value = $2;
               
                if ( $tag =~ /CLNSIG/ or /CLNDSDB/ or /CLNDSDBID/ or /CLNHGVS/) {
                    push @{ $clinMatch{$fst8[2]} }, $value;
                }
                unless ( $i->{'attribute'}->{'clin'}->{'Clin_variant_id'} ) {
                    $i->{'attribute'}->{'clin'}->{'Clin_variant_id'} = $fst8[2];
                }
            }
            # add gvfVar and clin variant list to ref.
            push @{ $clinMatch{$fst8[2]} }, $fst8[4], $gvfVar;
        }
        my $clinOrder = $self->_signifOrder(\%clinMatch);
        
        foreach my $r ($clinOrder){
            $i->{'attribute'}->{'clin'}->{'Clin_disease_variant_interpret'} = $r->[0] if $r->[0];
            $i->{'attribute'}->{'clin'}->{'Clin_HGVS_DNA'} = $r->[1] if $r->[1];
        }
    }        
    return $data;
}

#------------------------------------------------------------------------------

sub allelicStateCheck {
    my ($self, $data) = @_;
    
    foreach my $i ( @{$data} ){
        chomp $i;
        
        my $zyg = $i->{'attribute'}->{'Zygosity'};
        my $varSeq = $i->{'attribute'}->{'Variant_seq'};
        
        if ($zyg){
            $i->{'attribute'}->{'clin'}->{'Clin_allelic_state'} = $zyg;
            next;
        }
        elsif ($varSeq =~ /\,/){
            my ($a, $b) = split/,/, $varSeq;

            if ($b eq '!'){
                $i->{'attribute'}->{'clin'}->{'Clin_allelic_state'} = 'hemizygous';
            }
            else {
                $i->{'attribute'}->{'clin'}->{'Clin_allelic_state'} = 'hetrozygous';   
            }
        }
        else {
            $i->{'attribute'}->{'clin'}->{'Clin_allelic_state'} = 'homozygous';
        }
    }
    return $data;
}

#------------------------------------------------------------------------------

sub regionFinder {
    my ($self, $data) = @_;
    
    # create tabix object
    my $tab = Tabix->new(-data => $self->get_gtf_tabix) || die "Cannot locate GTF Tabix file\n";

    # search for matches in gvf file.
    foreach my $i ( @{$data} ){
        chomp $i;
        
        # Basic data needed from GVF file.
        my $gvfChr   = $i->{'seqid'}; 
        my $gvfStart = $i->{'start'};
        my $gvfEnd   = $i->{'end'};
    
        # check the tabix file for matching regions
        my $iter = $tab->query($gvfChr, $gvfStart - 1, $gvfEnd + 1);
      
        my %regions;
        while (my $read = $tab->read($iter)) {
        
            my @columns = split /\t/, $read;
            my @atts    = split /;/, $columns[8];
            
            unless ($columns[2] ne 'CDS') { next; }
            
            my (undef, $feature) = ($atts[2] =~ /(\S+)\s+\"(\d+)\"/);
            my (undef, $trans)   = ($atts[5] =~ /(\S+)\s+\"(\S+)\"/);
            
            push @{$regions{ $columns[2]} }, {
                feature_number => $feature,
                id             => $gvfStart,
                transcript     => $trans,
            };
        }
        
        my $clinRegion;
        while (my ($feature, $matches) = each %regions){
            foreach my $fd ( @{$matches} ) {
                if ($fd->{id} eq $gvfStart){
                    if ( $feature eq 'start_codon'){
                        my $addLine = "$feature $fd->{transcript},";
                        $clinRegion .= $addLine;  
                    }
                    else {
                        my $addLine = "$feature $fd->{feature_number} $fd->{transcript},";
                        $clinRegion .= $addLine;
                    }
                }
            }
        }
        if ( $clinRegion ){
            $clinRegion =~ s/\,$//g;
            $i->{'attribute'}->{'clin'}->{'Clin_DNA_region'} = $clinRegion;
        }
    }
    return ($data);
}

#------------------------------------------------------------------------------

sub hgvsDNACheck {
    my ($self, $data) = @_;

    # list of accepted types. Must be SO sequence_alteration child and hgvs accepted.
    my @soTypes = qw(substitution deletion duplication insertion indel inversion translocation);

    foreach my $i ( @{$data} ){
        chomp $i;

        # check that some genomic information is present, from db. 
        my $genoRef = $i->{'attribute'}->{'clin'}->{'Clin_genomic_reference'};
        unless ($genoRef) {next}
        
        # the gvf kids are all here.
        my $start = $i->{'start'};
        my $end   = $i->{'end'};
        my $var   = $i->{'attribute'}->{'Variant_seq'};
        my $ref   = $i->{'attribute'}->{'Reference_seq'};
        my $type  = $i->{'type'};
        
        # hgvs allow longer seq to be count of seq.
        my @varCount = split//, $var;
        if (scalar(@varCount) > 8){
            $var = scalar(@varCount);
        }

        # is type allowed?
        my $match = first { $_ eq $type } @soTypes;

        # looks and adds like java switch.        
        if ($match){
            if ($match eq 'substitution') {
                my $hgvsS = "$genoRef:g.$start$ref>$var";
                $i->{'attribute'}->{'clin'}->{'Clin_HGVS_DNA'} = $hgvsS;
            }
            elsif ($match eq 'deletion'){
                my $hgvsD = "$genoRef:g.$start" . "_" . "$end" . "del$ref";
                $i->{'attribute'}->{'clin'}->{'Clin_HGVS_DNA'} = $hgvsD;
            }
            elsif ($match eq 'duplication'){
                my $hgvsDp = "$genoRef:g.$start" . "_" . "$end" . "dup";
                $i->{'attribute'}->{'clin'}->{'Clin_HGVS_DNA'} = $hgvsDp;
            }
            elsif ($match eq 'insertion'){
                my $hgvsIn = "$genoRef:g.$start" . "_" . "$end" . "ins$var";
                $i->{'attribute'}->{'clin'}->{'Clin_HGVS_DNA'} = $hgvsIn;
            }
            elsif ($match eq 'indel'){
                my $hgvsIn = "$genoRef:g.$start" . "_" . "$end" . "delins$var";
                $i->{'attribute'}->{'clin'}->{'Clin_HGVS_DNA'} = $hgvsIn;
            }
            elsif ($match eq 'inversion'){
                my $hgvsIn = "$genoRef:g.$start" . "_" . "$end" . "inv$var";
                $i->{'attribute'}->{'clin'}->{'Clin_HGVS_DNA'} = $hgvsIn;
            }
            #elsif ($match eq 'translocation'){
            #    my $hgvsIn = "$genoRef:g.$start" . "_" . "$end" . "ins$var";
            #    $i->{'attribute'}->{'clin'}->{'Clin_HGVS_DNA'} = $hgvsIn;
            #}
        }
        else { next }
    }
    return $data;
}

#------------------------------------------------------------------------------
=cut
sub hgvsProtCheck {
    my ($self, $data) = @_;
    
    my $table = Bio::Tools::CodonTable->new();
    
    foreach my $i ( @{$data} ){
        
        my $proRef = $i->{'attribute'}->{'clin'}->{'Clin_HGVS_protein'};
        #### Clin_HGVS_protein
        
        # the gvf kids again.
        my $start = $i->{'start'};
        my $end   = $i->{'end'};
        my $type  = $i->{'type'};
        my $vCode = $i->{'attribute'}->{'Variant_codon'};
        my $vAA   = $i->{'attribute'}->{'Variant_aa'};
        my $rCode = $i->{'attribute'}->{'Reference_codon'};
        my $rAA   = $i->{'attribute'}->{'Reference_aa'};
        
        # only looking for true values.
        # replace unknown values, or delete all protein info.
        unless ($vCode || $vAA && $rCode || $rAA){
            delete $i->{'attribute'}->{'clin'}->{'Clin_HGVS_protein'};
            next;
        }
        
        # ref required and built first.        
        my $refName;
        if ($rAA || $rCode){
            $refName = $self->aaSLC3Letter($rAA) || $self->aaSLC3Letter($table->translate($rCode));
        }
        else { next }

        # make one variable to deal with variant_codon or variant_aa
        my $vValue = $vAA || $vCode;

        my $line;        
        if ($vValue =~ /\,/) {
            my @each = split/\,/, $vValue;
            map {
                my $size = length $_;

                # change from different forms to 3 letter.
                my $varName;
                if ($size == 1){
                    $varName = $self->aaSLC3Letter($_);
                }
                else {
                    # call to bio::perl first.
                    $varName = $self->aaSLC3Letter( $table->translate($_) );
                }

                # if values are the same -> S.O.L data.
                my $sameSeq = ($varName eq $refName) ? 0 : 1;
                
                if ($type eq 'substitution') {
                    $line .= "$genoRef:p.($refName" . "_" . "$varName)," unless $sameSeq eq 0;
                }
                elsif ($type eq 'deletion'){
                    $line .= "$genoRef:p.$refName$start" ."del," unless $sameSeq eq 0;
                }
                elsif ($type eq 'duplication'){
                    $line .= "$genoRef:g.$refName$start" . "_" . "$varName$end" . "dup," unless $sameSeq eq 0;
                }
                elsif ($type eq 'insertion'){
                    $line .= "$genoRef:g.$refName$start" . "_" . "$varName$end" . "ins," unless $sameSeq eq 0;
                }
            }@each;
        }
        else {
            my $aa3 = $self->aaSLC3Letter($vCode);
            $line = $aa3 unless $aa3 eq '?';
        }
        # Clean up and add to file.
        $line =~ s/\,$// if $line; 
        $i->{'attribute'}->{'clin'}->{'Clin_HGVS_protein'} = $line;
    }
    return $data;
}
=cut
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
    
    # check or add only required pragma.
    if (! exists $p{'gvf_version'}) { $p{'gvf_version'} = [1.06] }
    
    $self->set_pragmas(\%p);
}

#------------------------------------------------------------------------------

sub _termUpdate {
    my ($self, $data) = @_;

    # Takes the list of values from term_switch and looks in $data hash
    # for the value, then replaces with new key and deletes the old one.
    my @returnList;
    foreach my $i ( @{$data} ){
    
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
    Function: Takes parsed GVF file and searches for protein parent based on chromosome,
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
