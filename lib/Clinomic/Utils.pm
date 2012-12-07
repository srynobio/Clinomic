package Clinomic::Utils;
use Moose::Role;
use namespace::autoclean;
use Carp;

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

sub _signifOrder {
    my ($self, $clinData) = @_;
    
    my @clinMatches;
    while ( my ($rsid, $aryRef) = each %{$clinData} ) {
    
        # making lookup tables.
        my $lookup = { OMIM => 1, 'SNOMED CT' => 1, '.' => 1 };
        my $sigLookup = {
            0   => 'unknown',
            1   => 'unknown',
            2   => 'benign',
            3   => 'presumed_benign',
            4   => 'presumed_pathogenic',
            5   => 'pathogenic',
            6   => 'unknown',
            7   => 'unknown',
            255 => 'unknown',
        };
        
        # quick change the numbers into loinc value
        @{$aryRef}[0] =~ s/(\d+)/$sigLookup->{$1}/g;
         
        my @LoincName = split /\,/, @{$aryRef}[0];
        my @clinVars  = split /\,/, @{$aryRef}[3];
        my @db        = split /\,/, @{$aryRef}[1];
        my @ids       = split /\,/, @{$aryRef}[2];
        my $gvfVar    = @{$aryRef}[4];
        
        # if Vars match make a new array with the data.
        while ( @clinVars ){
            my $clinVar = shift @clinVars;
            my $name    = shift @LoincName;
            my $db      = shift @db;
            my $id      = shift @ids;
            if ( $gvfVar eq $clinVar){
                # swith the push comment to add the disease information. 
                #push @clinMatches, join(',', $name, $db, $id);
                push @clinMatches, $name;
            }
        }
    }
    return \@clinMatches;
}

#------------------------------------------------------------------------------

sub _aliasDNACheck {
    my ($self, $alias) = @_;

    if ( $alias =~ /\,/){
        ### ???????????????
        my @hgvs = split /\,/, $alias;
    }
    
    elsif ($alias =~ /HGVS/){
        my ($tag, $value) = split( /:/, $alias, 2 );
    
        if ($value =~ /\:c/ || $value =~ /\:g/ || $value =~ /\:m/){
            $value =~ s/\s+//;
            ####print $value, "\n";
            
        }
    }
}

#------------------------------------------------------------------------------

sub aaSLC3Letter {
    my ($self, $code) = @_;
    
    my $aaCode = {
        S => 'Ser', F => 'Phe',
        L => 'Leu', Y => 'Tyr', 
        C => 'Cys', W => 'Trp', 
        P => 'Pro', H => 'His',
        R => 'Arg', I => 'Ile', 
        M => 'Met', T => 'Thr', 
        N => 'Asn', K => 'Lys', 
        A => 'Ala', Q => 'Gln', 
        D => 'Asp', E => 'Glu', 
        G => 'Gly', V => 'Val',
    };
    
    if ($aaCode->{"$code"}){
        return $aaCode->{$code};
    }
    else {
        if (length $code > 1) { return '?' }
        elsif ( $code eq '*') { return 'STOP'}
        elsif ( $code eq '-') { return '?'}
        else {return $code}
    }
}

#------------------------------------------------------------------------------

no Moose;
1;
