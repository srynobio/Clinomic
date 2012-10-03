package GVF::Utils;
use Moose::Role;
use namespace::autoclean;
use Carp;

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
            $seen{$i->{'symbol'}} = $i->{'id'};
        }
        
        my @keeper;
        foreach my $e ( @{$a} ) {
            if (! $e->{'symbol'}) {next}
            my $looking = $e->{'symbol'};
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
    
    elsif ( $request eq 'hgnc' ){
        
        my %seen;
        foreach my $i ( @{$b} ){
            $seen{$i->{'symbol'}} = $i->{'id'};
        }
        
        my @keeper;
        foreach my $e ( @{$a} ) {
            
            my $gene;
            foreach (@{$e->{'attribute'}->{'Variant_effect'}}) {
                if ($_->{'feature_type'} eq 'gene'){
                    $gene = $_->{'feature_id1'};
                }
                else { next } 
            }
            if ( $seen{$gene} ) { push @keeper, [$e, $seen{$gene}]; }
        }
        return(\@keeper);
    }
    elsif ($request eq 'clinInterpt'){
        my %seen;
        foreach my $i ( @{$b} ){
            $seen{ $i->{'symbol'} } = $i;
        }
    
        my @keeper;
        foreach my $e ( @{$a} ) {
            if (! $e->{'clin_data'}->{'GENEINFO'} ) { next } 
            my $looking = $e->{'clin_data'}->{'GENEINFO'};
            if ( $seen{$looking} ) {
                push @keeper, [ $e, $seen{$looking} ];
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

sub xclassGrab {
    my ($self, $table, $list) = @_;
    
    my $xcl = $self->get_dbixclass;
    
    if (! ref($list)) {
        die "List passed to method xclassGrab must arrayref\n";
    }
    
    my $xObj = $xcl->resultset($table)->search (
        undef, { columns => $list }, 
    );
    return $xObj;
}

#------------------------------------------------------------------------------

sub simple_match {
    my ( $self, $data ) = @_;
    my $xcl = $self->get_dbixclass;

    # capture list of gene_id's from hgnc database
    my @hColumns = qw/ symbol id  /;
    my $genetic = $self->xclassGrab('Hgnc_gene', \@hColumns);

    my @symbols;
    while ( my $result = $genetic->next ){
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

sub _variant_builder {
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

sub _conceptList {
    my $self = shift;
    
    my $clinData = $self->clinvar;
    
    my %concept;
    foreach my $i ( @{$clinData} ){
        $concept{$i->{'umls'}} = {
            gene    => $i->{'symbol'},
            disease => $i->{'disease'},
        };
    }
    return \%concept;
}

#------------------------------------------------------------------------------

sub _conceptSplit {
    my ($self, $data, $hashref) = @_;
    
    my @cpList;
    if ($data =~ /\|/) {
        my @concept = split /\|/, $data;
        map { push @cpList, $_; }@concept;
    }
    elsif ( $data =~ /\,/) {
        my @concept = split /\,/, $data;
        map { push @cpList, $_; }@concept;
    }
    else { push @cpList, $data }

    return \@cpList;
}

#------------------------------------------------------------------------------




no Moose;
1;