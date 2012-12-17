package Clinomic::Utils;
use Moose::Role;
use namespace::autoclean;
use Carp;

#------------------------------------------------------------------------------
#----------------------------- Methods ----------------------------------------
#------------------------------------------------------------------------------

sub _variant_builder {
    my ($self, $atts) = @_;
    
    my %vEffect;
    while (my ( $keys, $value) = each %{$atts}){
        
        if ( $keys eq 'Variant_effect'){
            my @effect = split /,/, $value;
    
            my @effectList;
            foreach (@effect) {
                #my ($sv, $index, $ft, $fID1, $fID2) = split /\s/, $_;    
                my ($sv, $index, $ft, $id) = split /\s/, $_;    
        
                my $effect = {
                    sequence_variant => $sv,
                    index            => $index,
                    feature_type     => $ft,
                    #feature_id1      => $fID1,
                    #feature_id2      => $fID2,
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
        @{$aryRef}[1] =~ s/(\d+)/$sigLookup->{$1}/g;
         
        my @hgvs      = split /\,/, @{$aryRef}[0];
        my @LoincName = split /\,/, @{$aryRef}[1]; 
        my @clinVars  = split /\,/, @{$aryRef}[4]; 
        my @db        = split /\,/, @{$aryRef}[3]; 
        my @ids       = split /\,/, @{$aryRef}[3]; 
        my $gvfVar    = @{$aryRef}[4];
        
        # if Vars match make a new array with the data.
        while ( @clinVars ){
            my $clinHgvs = shift @hgvs;
            my $clinVar  = shift @clinVars;
            my $name     = shift @LoincName;
            my $db       = shift @db;
            my $id       = shift @ids;
            if ( $gvfVar eq $clinVar){
                # swith the push comment to add the disease information. 
                #push @clinMatches, join(',', $name, $db, $id);
                push @clinMatches, $name, $clinHgvs;
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
