package Clinomic::Utils;
use Moose::Role;
use namespace::autoclean;
use File::Basename;
use File::Find;
use IO::File;
use Carp;
use Data::Dumper;

#------------------------------------------------------------------------------
#----------------------------- Methods ----------------------------------------
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

sub gvfValadate {
    my ( $self, $data ) = @_;
    warn "{Clinomic} Valadating GVF file.\n";

    require Bio::DB::Fasta;

    #db handle and indexing fasta file .
    my $db = Bio::DB::Fasta->new( $self->get_fasta, -debug => 1 )
      || die "Fasta file not found $@\n";

    my @report;
    my $noRef = 0;
    my ( $correct, $mismatch, $total );
    foreach my $i ( @{$data} ) {

        # keep track of the total number of lines in file.
        $total++;

        my $chr   = $i->{'seqid'};
        my $start = $i->{'start'};
        my $end   = $i->{'end'};

        my $dataRef = uc( $i->{'attribute'}->{'Reference_seq'} );
        if ( $dataRef eq '-' ) { $noRef++; next; }

        # check that the strand matches.
        #ccmy $strand  = $i->{'strand'};
        my $strand = ( defined( $i->{'strand'} ) ? $i->{'strand'} : 'NULL' );
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
            my $result = "$chr\t$start\t$end\tFasta_Ref_Seq: $bioSeq\tFile_Ref_Seq: $dataRef\n";
            push @report, $result;
        }
    }

    ## print out report of incorect reference seq.
    if ( scalar @report > 1 ) {

        my $file = $self->get_file;
        $file =~ s/(\S+).gvf/$1.report/g;

        my $reportFH = IO::File->new( $file, 'a+' ) || die "cant open file\n";

        print $reportFH "## Unmatched Reference for $file ##\n";
        foreach (@report) {
            chomp $_;
            print $reportFH "$_\n";
        }
    }

    # check if passes default/given value.
    if ( $mismatch == $total ) {
        die "No matches were found, possible no Reference_seq in file\n";
    }
    my $value = ( $correct / ( $total - $noRef ) ) * 100;
    die sprintf( "
RESULTS: %s matches %5.2f%% to reference.\n\n", $self->get_file, $value );
}
#------------------------------------------------------------------------------

no Moose;
1;

