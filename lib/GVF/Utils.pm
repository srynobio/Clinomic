package GVF::Utils;
use Moose::Role;
use Carp;

use Bio::DB::Fasta;
use Data::Dumper;



#------------------------------------------------------------------------------
#----------------------------- Methods ----------------------------------------
#------------------------------------------------------------------------------

sub pharmgkb_word_alter {
    my ( $self, $word ) = @_;
    
    $word =~ s/^(\w+)(,)(\s)(\w+)$/$4 $1/g;
    $word =~ s/^(\w+)(,)(\s)(\w+)(\s)(\w+)$/$4 $6 $1/g;
    $word =~ s/^(\w+)(,)(\s)(\w+)(\s)(\w+)(\s)(\w+)$/$4 $6 $8 $1/g;
    $word =~ s/^(\w+)(,)(\s)(\w+-\w+)$/$4 $1/g;
    $word =~ s/^(\w+)(,)(\s)(\w+)(,)(\s)(\w+)$/$7 $4 $1/g;
    $word =~ s/^(\w+)(\s)(\w+)(,)(\s)(\w+)$/$6 $1 $3/g;
    $word =~ s/^(\w+)(\s)(\w+)(\s)(\w+)(,)(\s)(\w+)$/$8 $1 $3 $5/g;
    $word =~ s/^(\w+)(\s)(\w+)(,)(\s)(\w+)(\s)(\w+)(\s)(\w+)$/$6 $8 $10 $1 $3/g;
    $word =~ s/^(\w+)(,)(\s)(\w+)(,)(\s)(\w+)(\s)(\w+)(\s)(\w+)$/$7 $9 $11 $4 $1/g;
    $word =~ s/^(\w+)(\s)(\w+)(,)(\s)(\w+-\w+)$/$6 $1 $3/g;
    $word =~ s/^(\w+-\w+)(,)(\s)(\w+)$/$4 $1/g;
    $word =~ s/^(\w+-\w+)(,)(\s)(\w+-\w+)$/$4 $1/g;
    $word =~ s/^(\w+)(\s)(\w+)(,)(\s)(\w+)(,)(\s)(\w+)$/$6 $9 $1 $3/g;

    print $word, "\n";
}

#------------------------------------------------------------------------------

sub match_builder {

    my ($self, $a, $b , $request ) = @_;
    
    # for drug match
    if ( $request eq 'drug' ) {
        my %seen;
        foreach my $i ( @{$a} ){
            $seen{$i->{'drug_id'}} = $i;
        }
        my @keeper;
        foreach my $e ( @{$b} ) {
            my $looking = $e->{'drug_id'};
            if ( $seen{$looking} ) {
                push @keeper, [$e->{'drug_info'}, $seen{$looking}->{'drug_id'}, $seen{$looking}->{'id'}];
            }
        }
        return(@keeper);
    }
    
    # for omim match
    elsif ( $request eq 'omim' ){
        
        my %seen;
        foreach my $i ( @{$a} ){
            if ( ! $i->{'omim'} ) { next }
            $seen{$i->{'omim'}} = $i;
        }
        
        my @keeper;
        foreach my $e ( @{$b} ) {
            my $looking = $e->{'omim_num'};
            if ( $seen{$looking} ) {
                push @keeper, [$e->{'status'}, $e->{'disease'}, $e->{'cyto'}, $seen{$looking}->{'id'}];
            }
        }
        return(@keeper);
    }
    
    # for gvf match
    elsif ( $request eq 'gvf' ){
        my %seen;
        foreach my $i ( @{$a} ){
            $seen{$i} = 1;
        }
        my %gene;
        foreach my $e ( @{$b} ) {
            if ( $e->{'gene'} ) {
                $gene{$e->{'gene'}} = $e->{'id'};
            }
        }
        return(%gene);        
    }
    
    # for rsid match
    elsif ( $request eq 'rsid' ){
        my %seen;
        foreach my $i ( @{$a} ){
            $seen{$i} = 1;
        }
        #print Dumper(%s);
=cut        
        my %gene;
        foreach my $e ( @{$b} ) {
            if ( $e->{'gene'} ) {
                $gene{$e->{'gene'}} = $e->{'id'};
            }
        }
=cut        
        #return(%gene);        
    }
    
    
    # for gene match
    else {
        my %seen;
        foreach my $i ( @{$a} ){
            $seen{$i->{'gene'}} = $i;
        }
    
        my @keeper;
        foreach my $e ( @{$b} ) {
            my $looking = $e->{'gene_id'};
            if ( $seen{$looking} ) {
                push @keeper, [$e, $seen{$looking}->{'id'}];
            }
        }
        return(@keeper);
    }
}

#------------------------------------------------------------------------------

sub _file_splitter {

    my ( $self, $request ) = @_;

    my $obj_fh;
    open ( $obj_fh, "<", $self->gvf_file ) || die "File" . $self->gvf_file . "can not be opened\n";

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
    #close->$obj_fh;

    if ( $request eq 'pragma') { return \@pragma }
    if ( $request eq 'feature') { return \@feature_line }
}

#------------------------------------------------------------------------------

sub gvf_valadate {

    #my $self = shift;
    my ( $self, $data ) = @_;
    
    # file check
    if ( ! $data->[0]->{'attribute'}->{'Variant_effect'} ) {
        die "Your GVF file does not have the required Variant_effect field...\n";
    }
    
    my $dbxh = $self->get_mysql_dbxh;

    # db handle and indexing fasta file.
    my $db    = Bio::DB::Fasta->new( $self->get_fasta_file, -debug=>1 ) || croak "Fasta file not found $@\n";
    
    my ( $correct, $mismatch, $total );
    foreach my $i ( @{$data} ) {
    
        # keep track of the total number of line in file.     
        $total++;
        
        my $chr;
        if ( $i->{'seqid'} !~ /^chr/ ){
            $chr = "chr". $i->{'seqid'};
        }
        else {
            $chr = $i->{'seqid'};
        }
        
        my $start   = $i->{'start'};
        my $end     = $i->{'end'};
        
        my $ref_seq = uc($i->{'attribute'}->{'Reference_seq'});
        if ( $ref_seq eq '-'){ next }
        
        # call to Bio::DB. 
        my $seq = $db->seq("$chr:$start..$end");
        $seq = uc($seq);
        
        if ( $seq eq $ref_seq ) { $correct++; }
        else { $mismatch++; }
    }
    
    my $value = ($correct/$total) * 100;
    return ($value);
}


#------------------------------------------------------------------------------



1;