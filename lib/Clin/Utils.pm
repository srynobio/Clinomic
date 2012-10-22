package Clin::Utils;
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

sub _conceptList {
    my $self = shift;    
    my $clinData = $self->clinvar('return');
    
    my %concept;
    foreach my $i ( @{$clinData} ){
        $concept{$i->{'umls'}} = {
            snomed_id => $i->{'source_id'},
            disease   => $i->{'disease'},
            gene      => $i->{'symbol'},
        };
    }
    return \%concept;
}

#------------------------------------------------------------------------------

sub _conceptSplit {
    my ($self, $clin, $concept) = @_;
    my %concept = %$concept;

    my $cuiLine;
    if ($clin =~ /\|/) {
        my @concept = split /\|/, $clin;
        map {
            if ( $concept{$_} ){
                $cuiLine .= "$concept{$_}->{'snomed_id'},";
            }
            else { $cuiLine .= '.,'}
        }@concept;
    }
    elsif ( $concept{$clin} ){
        $cuiLine .= "$concept{$_}->{'snomed_id'}";
    }
    else {
        $cuiLine .= ".";
    }
    # clean up end of the line and return ref.
    $cuiLine =~ s/\,$// if $cuiLine;
    return \$cuiLine; 
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