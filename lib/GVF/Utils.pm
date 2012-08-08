package GVF::Utils;
use Moose::Role;
use Carp;

use Bio::DB::Fasta;
use Data::Dumper;

#------------------------------------------------------------------------------
#----------------------------- Methods ----------------------------------------
#------------------------------------------------------------------------------

sub match_builder {
    my ($self, $a, $b , $request ) = @_;
    
    if ( $request eq 'simple' ){
        
        my %seen;
        foreach my $i ( @{$b} ){
            $seen{ $i->{'symbol'} } = $i->{'id'};
        }
    
        my @keeper;
        foreach my $e ( @{$a} ) {
            my $looking = $e->{'symbol'};
            if ( $seen{$looking} ) {
                push @keeper, [ $e, $seen{$looking} ];
            }
        }
        return(\@keeper);
    }

    elsif ( $request eq 'refseq' ){
        
        my %seen;
        foreach my $i ( @{$b} ){
            $seen{$i->{'trans'}} = $i->{'id'};
        }
        
        my @keeper;
        foreach my $e ( @{$a} ) {
            if (! $e->{'rna_acc'}) {next}
            my $looking = $e->{'rna_acc'};
            if ( $seen{$looking} ) {
                push @keeper, [ $e, $seen{$looking} ];
            }
        }
        return(\@keeper);
    }
    
    # thats what Deaner was talking about.
    elsif ( $request eq 'gene' ){
        
        my %seen;
        foreach my $i ( @{$a} ){
            $seen{ $i->{'symbol'} } = $i;
        }

        my @keeper;
        foreach my $e ( @{$b} ) {
            my $looking = $e->{'symbol'};
            if ( $seen{$looking} ) {
                
                push @keeper, [ $e, $seen{$looking}->{'refseq'}, $seen{$looking}->{'name'},
                               $seen{$looking}->{'omim_id'}, $seen{$looking}->{'chromo'}];                
            }
        }
        return(\@keeper);
    }
}

#------------------------------------------------------------------------------

sub _file_splitter {
    my ( $self, $request ) = @_;

    my $obj_fh;
    open ( $obj_fh, "<", $self->get_file ) || die "File " . $self->get_file . " can not be opened\n";

    my ( @pragma, @feature_line );
    foreach my $line ( <$obj_fh> ){
        chomp $line;
    
        $line =~ s/^\s+$//g;

        # captures pragma lines.
        if ($line =~ /^#{1,}/) {
            push @pragma, $line;
        }
        # or feature_line
        else { push @feature_line, $line; }
    }

    if ( $request eq 'pragma') { return \@pragma }
    if ( $request eq 'feature') { return \@feature_line }
}

#------------------------------------------------------------------------------

sub simple_match {
    my ( $self, $data ) = @_;
    
    my $xcl = $self->get_dbixclass;

    # capture list of gene_id's
    my $gene_id = $xcl->resultset('Hgnc_gene')->search (
        undef, { columns => [qw/symbol id /] }, 
    );

    my @symbols;
    while ( my $result = $gene_id->next ){
        my $list = {
            symbol => $result->symbol,
            id     => $result->id,
        };
        push @symbols, $list; 
    }    
    my $match = $self->match_builder($data, \@symbols, 'simple');
    return $match;
}

#------------------------------------------------------------------------------

## start of the ClinBuilder methods ## 

sub gvfValadate {
    my $self  = shift;
    
    # capture info.
    my $data = $self->get_gvf_data;
    
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

sub geneCheck {
    my $self = shift;

    my ($count, $gene);
    foreach my $i (@{$self->get_gvf_data}){
        $count++;
        
        foreach (@{$i->{'attribute'}->{'Variant_effect'}}) {
            if ($_->{'feature_type'} eq 'gene'){
                $gene++;
            }
            else { next }
        }
    }
    #### DO SOMETHING !!!!!!!!!!!!!!!!!

    #print $count, "\t", $gene, "\n";

}

#------------------------------------------------------------------------------

sub geneFinder {
    
    my $self = shift;
    
    #my $dbxh = $self->dbh;
    #my $xcl = $self->get_dbixclass;
    my $xcl = GVF::DB::Connect->connect("dbi:SQLite:../data/GeneDatabase.db");
    #my $data = $self->get_gvf_data;

    #print Dumper($xcl);
    
#=cut
    # capture list of gene_id's
    my $gene_id = $xcl->resultset('Hgnc_gene')->search(
        undef, { columns => [qw/ id symbol /], }
    );
    
    my %ncbi;
    while ( my $result = $gene_id->next ){
        $ncbi{$result->id} = $result->symbol;
    }


    print Dumper(%ncbi);

#=cut    






=cut
    my $tab = Tabix->new(-data => $self->get_tabix_file) || die "Please input Tabix file\n";

    # search the golden set file for a match
    my @updateGVF;
    foreach my $i (@{$data}) {

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
            
            # Collect just gene_id from the matches and DBIx resultset data.
            map {
                if ( $_ =~ /^Dbxref/) {
                    $_ =~ /(.*)=(.*)/g;
                    my ($gene, undef) = split /,/, $2;
                    my ($tag, $value) = split /:/, $gene;
                    my $geneMatch = ( $ncbi{$value} ) ? $ncbi{$value} : 'NULL';
                    my $effect        = "gene_variant 0 gene " . $geneMatch, if $geneMatch ne 'NULL';
                    $atts{'GeneID'}   = $effect;
                }
            }@attsList;
        }
        $i->{'attribute'}->{'Variant_effect'} = $atts{'GeneID'} if $atts{'GeneID'};
        push @updateGVF, $i;        
    }
    
    # Little reference witchcraft to try to keep speed.
    my $updateGVF = \@updateGVF;
    my @kept      = grep { $_->{'attribute'}->{'Variant_effect'} } @{$updateGVF};
    my $kept      = \@kept;

    $self->set_gvf_data($kept);
    $self->populate_gvf_data;
    
    
=cut    
}

#------------------------------------------------------------------------------

sub _atts_builder {
    my ($self, $atts) = @_;
    
    my %vEffect;
    while (my ( $keys, $value) = each %{$atts}){
        
        if ( $keys eq 'Variant_effect'){
            my @effect = split /,/, $value;
    
            my @effectList;
            foreach (@effect) {
                my ($sv, $index, $ft, $fID1, $fID2) = split /\s/, $_;    
        
                my $effect = {
                    sequence_variant => $sv,
                    index            => $index,
                    feature_type     => $ft,
                    feature_id1      => $fID1,
                    feature_id2      => $fID2,
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

1;