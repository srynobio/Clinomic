#!/usr/bin/perl
use warnings;
use strict;
use IO::File;
use Getopt::Long;


use Data::Dumper;

my $usage = "\n

DESCRIPTION:

USAGE: 

OPTIONS(required):

\n";

my ($pharm, $snomed, $hgmd, $rxnorm, $rsid, $snomed_match, $rxnorm_match );

my $opt_results = GetOptions(

        'pharm=s'       => \$pharm,
        'snomed=s'      => \$snomed,
        'hgmd=s'        => \$hgmd,
        'rxnorm=s'      => \$rxnorm,
        'rsid=s'        => \$rsid,
        'snomed_match'  => \$snomed_match,
        'rxnorm_match'  => \$rxnorm_match,

) || die "$usage";


#------------------------------------------------------------------------------

my @pharm_list;
if ( $pharm ){
    
    my $pharm_fh  = IO::File->new( $pharm, 'r') || die "Please enter PharmGKB diesese file\n";

    while ( defined ( my $line = ( <$pharm_fh> ))) {
        chomp $line;
        
        $line = lc($line);
        my $pharm = term_cleaner($line);
        
        push @pharm_list, $pharm;
    }
}

my @u_pharm_list = duplicates(@pharm_list);

#------------------------------------------------------------------------------

my @snomed_list;
if ( $snomed ){
    
    my $snomed_fh = IO::File->new( $snomed, 'r') || die "Please enter SNOMED file\n";

    while ( defined ( my $line = ( <$snomed_fh> ))) {
        chomp $line;
        
        $line = lc($line);
        $line =~ s/\^/ /g;
        $line =~ s/^\s+//g;
        my $snomed = term_cleaner($line);
    
        push @snomed_list, $snomed;
    }
}

my @u_snomed_list = duplicates(@snomed_list);

#------------------------------------------------------------------------------

my @hgmd;
if ( $hgmd ) {
    
    my $hgmd_fh = IO::File->new( $hgmd, 'r') || die "Please enter hgmd_snv file\n";
  
    while ( defined ( my $line = ( <$hgmd_fh> ))) {
        chomp $line;
        
        $line = lc($line);
        $line =~ s/(.*)\?/$1/g;
        my $snv = term_cleaner($line);
    
        push @hgmd, $snv;
    }
}  

my @u_hgmd = duplicates(@hgmd);

#------------------------------------------------------------------------------

my @rxnorm;
if ( $rxnorm ){
    
    my $rxnorm_fh = IO::File->new( $rxnorm, 'r') || die "Please enter hgmd_snv file\n";
  
    while ( defined ( my $line = ( <$rxnorm_fh> ))) {
        chomp $line;
        
        
        $line = lc($line);
        $line =~ /(\S+)\s+(.*)$/g;

        #my $ordered = term_cleaner($line);
        #push @rxnorm, $1;
        push @rxnorm, $line;
        
    }
}  

my @u_rxnorm = duplicates(@rxnorm);

#------------------------------------------------------------------------------

if ( $snomed_match ) {

    my @check_one;
    @check_one = @u_pharm_list if $pharm;
    @check_one = @u_hgmd if $hgmd;
    @check_one = @u_rxnorm if $rxnorm;
    
    if ( $snomed ){
        foreach my $p ( @u_snomed_list ){
            foreach my $s ( @check_one ){
                if( $p eq $s ){
                    print "$p\n";
                }
            }
        }
    }
}

if ($rxnorm_match){
    
    foreach my $p ( @u_rxnorm ){
        foreach my $s ( @u_pharm_list ){
            if( $p eq $s ){
                print "$p\n";
            }
        }
    }
}

#------------------------------------------------------------------------------

if ( $rsid ) {
    
    my $rsid_fh = IO::File->new( $rsid, 'r')|| die "rsid file can not be opened\n";
    
    while ( defined ( my $line = ( <$rsid_fh> ))) {
        chomp $line;
            
        my ( $entity1_id, $entity1_name, $entity2_id, $entity2_name, $evidence, $evidence_sources,
            $pharmacodynamic, $pharmacokinetic) = split /\t/, $line;
        
        my $lc_term = lc($entity2_name);
        
        if ( $entity2_id !~ /Disease/ ) { next }
        if ( $evidence !~ /RSID/ ) { next }
    
        my $clean_term = term_cleaner($lc_term);
        
        
        print "$clean_term\n"; #\t$evidence\n";
        #print "$lc_term\n"; #\t$evidence\n";
        
    }
}    







#------------------------------------------------------------------------------

# for R
#venn.diagram(x=list("PharmGKB"= test1, "SNOMED"= test2), filename="testone", height = 4000, width = 5000, resolution = 800, main="SNOMED vs PharmGKB disease terms", scaled = FALSE)


#------------------------------------------------------------------------------
#--------------------------------SUBS------------------------------------------
#------------------------------------------------------------------------------

sub duplicates {

    my @list = @_;
    
    my ( %seen, @uniq );
    foreach my $item ( @list ){
        push (@uniq, $item) unless $seen{$item}++;
    }
    return @uniq;
}

#------------------------------------------------------------------------------

sub term_cleaner {
    
    my $line = shift;
    
    # List of matches to capture all possable word patterns.
    $line =~ s/^(\w+)(,)(\s)(\w+)$/$4 $1/g;
    $line =~ s/^(\w+)(,)(\s)(\w+)(\s)(\w+)$/$4 $6 $1/g;
    $line =~ s/^(\w+)(,)(\s)(\w+)(\s)(\w+)(\s)(\w+)$/$4 $6 $8 $1/g;
    $line =~ s/^(\w+)(,)(\s)(\w+-\w+)$/$4 $1/g;
    $line =~ s/^(\w+)(,)(\s)(\w+)(,)(\s)(\w+)$/$7 $4 $1/g;
    $line =~ s/^(\w+)(\s)(\w+)(,)(\s)(\w+)$/$6 $1 $3/g;
    $line =~ s/^(\w+)(\s)(\w+)(\s)(\w+)(,)(\s)(\w+)$/$8 $1 $3 $5/g;
    $line =~ s/^(\w+)(\s)(\w+)(,)(\s)(\w+)(\s)(\w+)(\s)(\w+)$/$6 $8 $10 $1 $3/g;
    $line =~ s/^(\w+)(,)(\s)(\w+)(,)(\s)(\w+)(\s)(\w+)(\s)(\w+)$/$7 $9 $11 $4 $1/g;
    $line =~ s/^(\w+)(\s)(\w+)(,)(\s)(\w+-\w+)$/$6 $1 $3/g;
    $line =~ s/^(\w+-\w+)(,)(\s)(\w+)$/$4 $1/g;
    $line =~ s/^(\w+-\w+)(,)(\s)(\w+-\w+)$/$4 $1/g;
    $line =~ s/^(\w+)(\s)(\w+)(,)(\s)(\w+)(,)(\s)(\w+)$/$6 $9 $1 $3/g;
    
    
    #$line =~ s/(\w+)(,)\s+(\w+)\s+(\w+)/$4 $3 $1/g;
    #$line =~ s/(\w+)\s+(\w+)(,)\s+(\w+)\s+(\d+)/$4 $5 $1 $2/g;
    #$line =~ s/(\w+)(,)\s+(\w+)(,)\s+(\w+)(,)\s+(.*)\s+(\w+)/$8 $7 $5 $3 $1/g;
    #$line =~ s/(\w+)\s+(\w+)(,)(\w+)\s+(\w+)/$4 $5 $1$ 2/g;
    #$line =~ s/(\w+)(,)\s+(\S+)\s+(\w+)/$4 $3 $1/g;
    
    
    #carcinoma, non-small-cell lung

    #leukemia, lymphocytic, chronic, b-cell
    #lymphoma, large-cell, diffuse

    #pulmonary disease, chronic obstructive
    
    
    
    
        

    return $line;
}

#------------------------------------------------------------------------------











