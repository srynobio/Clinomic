package GVF::Export;
use Moose::Role;
#use XML::Generator;
#use XML::Writer::Simple dtd => "GVFClin.dtd";
#use XML::Writer::Simple xml => "GVFClin.xml";
#use XML::Simple qw(:strict);

use XML::Writer;

use IO::File;

use lib '../lib';
use Data::Dumper;


#-----------------------------------------------------------------------------
#------------------------------- Methods -------------------------------------
#-----------------------------------------------------------------------------

sub exporter {
    my ($self, $gvf) = @_;
    
    my $type = $self->get_export;
    
    if ($type eq 'gvf'){
        $self->toGVF($gvf);
    }
    elsif ( $type eq 'xml'){
        $self->toXML($gvf);
    }
    elsif( $type eq 'both'){
        self->toGVF($gvf);
        self->toXML($gvf);
    }
}

#-----------------------------------------------------------------------------

sub toGVF {
    my ($self, $gvf) = @_;
    
    # check for pragama values.
    my $pragma;
    if ($self->has_pragmas){
        $pragma = $self->get_pragmas;
    }

    # print out pragma values.    
    while (my ($k, $v ) = each %{$pragma}){
        print "##$k=" . $v->[0], "\n";
    }
    
    # print out in gvf format.    
    foreach my $i ( @{$gvf} ){
        my $first8 =
        "$i->{'seqid'}\t$i->{'source'}\t$i->{'type'}\t" .
        "$i->{'start'}\t$i->{'end'}\t$i->{'score'}\t$i->{'strand'}\t.\t";
        
        print "$first8\t";
        
        while ( my ($k2, $v2) = each %{$i->{'attribute'}} ){
            
            if ( $k2 eq 'clin'){
                while ( my ($k, $v) = each %{$v2} ){
                    print "$k=$v;" if $v;
                }
            }
            elsif ( $k2 eq 'Variant_effect'){
                print "Variant_effect=";
                
                my $line;
                foreach (@{$v2}){
                    my $fields = join(' ', $_->{'sequence_variant'}, $_->{'index'}, $_->{'feature_type'}, $_->{'feature_id1'});
                    
                    # add this if it's around
                    $fields .= $_->{'feature_id2'} if $_->{'feature_id2'};
                    
                    # create one line seperated by comma.
                    $line .= $fields;
                    $line .= ',';
                }
                # remove last comma, and print line
                $line =~ s/(.*)\,$/$1;/;
                print $line;
            }
            else {
                print "$k2=$v2;" if $v2;
            }   
        }
        print "\n"; 
    }
}

#-----------------------------------------------------------------------------

sub toXML {
    my ($self, $gvf) = @_;
    
    my $output = IO::File->new(">>test.xml");
    
    my $writer = XML::Writer->new(
        OUTPUT => $output,
        #NEWLINES => 1,
        DATA_MODE => 1,
    );
    
    #my $writer = XML::Writer->new(OUTPUT => $output );
    
    
    my $pragma = $self->get_pragmas if $self->has_pragmas;
    
    
    $writer->startTag("greeting",
                      "class" => "simple");

    $writer->characters("Hello, world!");
    $writer->endTag("greeting");

    $writer->end();
    $output->close()


    
}

#-----------------------------------------------------------------------------


























1;
