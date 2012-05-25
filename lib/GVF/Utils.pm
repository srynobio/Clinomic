package GVF::Utils;
use Moose::Role;
use Carp;

use Data::Dumper;







#------------------------------------------------------------------------------

#Methods
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














1;