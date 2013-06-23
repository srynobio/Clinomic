package Clinomic::Utils;
use Moose::Role;
use namespace::autoclean;
use File::Basename;
use File::Find;
use IO::File;
use Carp;

####
use Data::Dumper;


#------------------------------------------------------------------------------
#----------------------------- Methods ----------------------------------------
#------------------------------------------------------------------------------

sub _aliasDNACheck {
    my ( $self, $alias ) = @_;

    if ( $alias =~ /\,/ ) {
        ### ???????????????
        my @hgvs = split /\,/, $alias;
    }

    elsif ( $alias =~ /HGVS/ ) {
        my ( $tag, $value ) = split( /:/, $alias, 2 );

        if ( $value =~ /\:c/ || $value =~ /\:g/ || $value =~ /\:m/ ) {
            $value =~ s/\s+//;
            ####print $value, "\n";

        }
    }
}
#------------------------------------------------------------------------------

sub aaSLC3Letter {
    my ( $self, $code ) = @_;

    my $aaCode = {
        S => 'Ser',
        F => 'Phe',
        L => 'Leu',
        Y => 'Tyr',
        C => 'Cys',
        W => 'Trp',
        P => 'Pro',
        H => 'His',
        R => 'Arg',
        I => 'Ile',
        M => 'Met',
        T => 'Thr',
        N => 'Asn',
        K => 'Lys',
        A => 'Ala',
        Q => 'Gln',
        D => 'Asp',
        E => 'Glu',
        G => 'Gly',
        V => 'Val',
    };

    if ( $aaCode->{"$code"} ) {
        return $aaCode->{$code};
    }
    else {
        if ( length $code > 1 ) { return '?' }
        elsif ( $code eq '*' ) { return 'STOP' }
        elsif ( $code eq '-' ) { return '?' }
        else                   { return $code }
    }
}
#------------------------------------------------------------------------------

no Moose;
1;
