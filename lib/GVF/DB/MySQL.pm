package GVF::DB::MySQL;
use Moose::Role;
use Carp;

use Data::Dumper;
#-----------------------------------------------------------------------------
#------------------------------- Attributes ----------------------------------
#-----------------------------------------------------------------------------

has 'mysql_user' => (
    is       => 'rw',
    isa      => 'HashRef',
    reader   => 'get_mysql_user',
    required => 1,
    trigger  =>\&_mysql_dbx_builder,
);

has 'mysql_dbx_handle' => (
    is     => 'rw',
    isa    => 'Object',
    writer => 'set_mysql_dbxh',
    reader => 'get_mysql_dbxh',
);

has 'build_database' => (
    is  => 'rw',
    isa => 'Int',
    trigger => \&_build_database,
);

#------------------------------------------------------------------------------
#----------------------------- Methods ----------------------------------------
#------------------------------------------------------------------------------

sub _mysql_dbx_builder {
    my $self = shift;
    
    my $user = $self->get_mysql_user;
    
    my $dbixclass = GVF::DB::File->connect( 'dbi:mysql:GVF_DB_Variant', "$user->{'user'}", "$user->{passwd}" );
    $self->set_mysql_dbxh($dbixclass);
}

#------------------------------------------------------------------------------

sub _build_database {
    my $self = shift;

#=cut    
    my $dbxh = $self->get_mysql_dbxh;
    
    # may have to add more detail
    my $check = $dbxh->resultset('PharmGKB_gene');
    
    if ( $check ){ carp "Database already build"; }
    else {
        $self->pharmGKB_gene('populate');
        $self->pharmGKB_disease('populate');
        $self->pharmGKB_drugs('populate');
    }
    $dbxh->close;
#=cut    

}

#------------------------------------------------------------------------------
sub _populate_pharmgkb_gene {
    my ( $self, $data ) = @_;

=cut    
    my $dbxh = $self->get_mysql_dbxh;
    
    foreach my $i ( @{$data} ){
        chomp $i;
        
        $dbxh->resultset('PharmGKB_gene')->create({
            gene_id   => $i->{'pharm_id'},
            symbol    => $i->{'gene_name'},
            gene_info => $i->{'gene_info'},
        });
    }
    $dbxh->close;
=cut    

}

#------------------------------------------------------------------------------

sub _populate_pharmgkb_disease {
    my ( $self, $data ) = @_;

=cut    
    my $dbxh = $self->get_mysql_dbxh;

    # capture list of gene_id's
    my @gene_id = $dbxh->resultset('PharmGKB_gene')->search( undef, {
        columns => [qw/gene_id/],
    });
 
    foreach my $gene ( @gene_id ){
        if ( $gene eq $data->[0]->{'gene_id'} ) {
            
            # matches are added to db.
            $dbxh->resultset('PharmGKB_disease')->create({
                disease_name      => $data->[0]->{'disease_name'},
                disease_id        => $data->[0]->{'disease_id'},
                gene_disease_evid => $data->[0]->{'gene_disease_evid '},
            });
        }
    }
    $dbxh->close;
=cut    
}

#------------------------------------------------------------------------------

sub _populate_pharmgkb_drug {
    my ( $self, $data ) = @_;
    
=cut    
    my $dbxh = $self->get_mysql_dbxh;

    # capture list of gene_id's
    my @gene_id = $dbxh->resultset('PharmGKB_gene')->search( undef, {
        columns => [qw/gene_id/],
    });
    
    my @drug_id;        
    foreach my $gene ( @gene_id ){
        if ( $gene eq $data->[0]->{'gene_id'} ) {
        
            # matches are added to db.
            $dbxh->resultset('PharmGKB_drug')->create({
                drug_id        => $data->[0]->{'drug_id'},
                drug_name      => $data->[0]->{'drug_name'},
                gene_drug_evid => $data->[0]->{'gene_drug_evid'},
            });
            push @drug_id, $data->[0]->{'drug_id'};
        }
    }
    $self->populate_drug_info(\@drug_id);
    $dbxh->close;
=cut
}    

#------------------------------------------------------------------------------

sub _populate_drug_info {
    my ( $self, $drug_id ) = @_;

=cut    
    my $dbxh = $self->get_mysql_dbxh;

    # populate with drug gene info with additional request.
    my $drug_list  = $self->pharmGKB_drugs('parse');
    
    foreach my $i ( @{$drug_id} ){
        if ( $i eq $drug_list->{'drug_id'} ) {
            
            #### the database will have to be changed to reflect
            #### the change to reference info.
            $dbxh->resultset('Drug_information')->create({
                reference_info => $drug_list->{'drug_info'},
                });
    }
    $dbxh->close;
=cut
}

#------------------------------------------------------------------------------

sub _populate_omim {
    my ( $self, ) = @_;
    
    my $dbxh = $self->get_mysql_dbxh;

    $dbxh->close;
}

#------------------------------------------------------------------------------

1;


