package GVF::Utils;
use Moose::Role;
use Carp;

#use Bio::DB::Fasta;
use Data::Dumper;



#------------------------------------------------------------------------------
#----------------------------- Methods ----------------------------------------
#------------------------------------------------------------------------------

sub match_builder {

    my ($self, $a, $b , $request ) = @_;
    
    # most used section
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

    elsif ( $request eq 'relation' ){
        
        my %seen;
        foreach my $i ( @{$b} ){
            $seen{ $i->{'gene_id'} } = $i->{'id'};
        }

        my @keeper;
        foreach my $e ( @{$a} ) {
            my $looking = $e->{'gene_id'};
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
                               $seen{$looking}->{'hgnc_id'}, $seen{$looking}->{'pubmed_id'}, $seen{$looking}->{'omim'} ];
            }
        }
        return(\@keeper);
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

sub simple_match {
    my ( $self, $data ) = @_;
    
        my $dbxh = $self->dbxh;    

    # capture list of gene_id's
    my $gene_id = $dbxh->resultset('Genes')->search (
        undef, { columns => [qw/ id symbol /], }
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













#
#sub gvf_valadate {
#
#    #my $self = shift;
#    my ( $self, $data ) = @_;
#    
#    # file check
#    if ( ! $data->[0]->{'attribute'}->{'Variant_effect'} ) {
#        die "Your GVF file does not have the required Variant_effect field...\n";
#    }
#    
#    my $dbxh = $self->get_mysql_dbxh;
#
#    # db handle and indexing fasta file.
#    my $db    = Bio::DB::Fasta->new( $self->get_fasta_file, -debug=>1 ) || croak "Fasta file not found $@\n";
#    
#    my ( $correct, $mismatch, $total );
#    foreach my $i ( @{$data} ) {
#    
#        # keep track of the total number of line in file.     
#        $total++;
#        
#        my $chr;
#        if ( $i->{'seqid'} !~ /^chr/ ){
#            $chr = "chr". $i->{'seqid'};
#        }
#        else {
#            $chr = $i->{'seqid'};
#        }
#        
#        my $start   = $i->{'start'};
#        my $end     = $i->{'end'};
#        
#        my $ref_seq = uc($i->{'attribute'}->{'Reference_seq'});
#        if ( $ref_seq eq '-'){ next }
#        
#        # call to Bio::DB. 
#        my $seq = $db->seq("$chr:$start..$end");
#        $seq = uc($seq);
#        
#        if ( $seq eq $ref_seq ) { $correct++; }
#        else { $mismatch++; }
#    }
#    
#    my $value = ($correct/$total) * 100;
#    return ($value);
#}


#------------------------------------------------------------------------------



1;