package GVF::DB::MySQL;
use Moose::Role;
use Carp;
use GVF::DB::Connect;


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
    is         => 'rw',
    isa        => 'Int',
    trigger => \&_build_database,
);


#------------------------------------------------------------------------------
#----------------------------- Methods ----------------------------------------
#------------------------------------------------------------------------------

sub _mysql_dbx_builder {
    my $self = shift;
    
    my $user = $self->get_mysql_user;
    
    my $dbixclass = GVF::DB::Connect->connect( 'dbi:mysql:GVFClin', "$user->{'user'}", "$user->{passwd}" );
    $self->set_mysql_dbxh($dbixclass);
}

#------------------------------------------------------------------------------

sub _build_database {
    my $self = shift;

    my $dbxh = $self->get_mysql_dbxh;
    
    my $id     = $dbxh->resultset('PharmGkbGene')->search;
    my $check   = $id->get_column('id');
    my $max_id = $check->max;

    if ( ! $max_id ){

        $self->pharmGKB_gene('populate');
        $self->pharmGKB_disease('populate');
        $self->pharmGKB_drug_info('populate');
        $self->omim('populate');
        $self->rsidgene('populate');

    }
}

#------------------------------------------------------------------------------

sub _populate_pharmgkb_gene {
    my ( $self, $data ) = @_;

    my $dbxh = $self->get_mysql_dbxh;
    
    my %omim = $self->omim('gene');

    my @omim_list;
    while ( my ( $key, $value ) = each %omim ) {
        foreach my $i ( @{$value} ){
            my $omim_table = {
                gene => $i,
                omim => $key,
            };
            push @omim_list, $omim_table;
        }
    }
 
    foreach my $i ( @{$data} ){
        my $omim_num;
        foreach my $e (@omim_list) {
            if ( $i->{'gene_name'} eq $e->{'gene'} ){
                $omim_num = $e->{'omim'};
            }
        }
        
        $dbxh->resultset('PharmGkbGene')->create({
            gene_id   => $i->{'pharm_id'},
            symbol    => $i->{'gene_name'},
            gene_info => $i->{'gene_info'},
            omim      => $omim_num,
        });
    }
}

#------------------------------------------------------------------------------

sub _populate_pharmgkb_disease {
    my ( $self, $data ) = @_;

    my $dbxh = $self->get_mysql_dbxh;

    # capture list of gene_id's
    my $gene_id = $dbxh->resultset('PharmGkbGene')->search (
        undef, { columns => [qw/ gene_id id /], }
    );
    
    my @gene_id_list;
    while ( my $result = $gene_id->next ){
        my $list = {
            gene => $result->gene_id,
            id   => $result->id,
        };
        push @gene_id_list, $list; 
    }

    # match the two above arrays.
    my @match = $self->match_builder(\@gene_id_list, $data );
    
    # matches are added to db.
    foreach my $i ( @match ) {
        $dbxh->resultset('PharmGkbDisease')->create({
            disease_name          => $i->[0]->{'disease_name'},
            disease_id            => $i->[0]->{'disease_id'},
            disease_gene_evidence => $i->[0]->{'gene_disease_evid'},
            PharmGKB_gene_id      => $i->[1],
        });
    }
}

#------------------------------------------------------------------------------

sub _populate_pharmgkb_drug {
    my ( $self, $data ) = @_;
    
    my $dbxh = $self->get_mysql_dbxh;

    # capture list of gene_id's
    my $gene_id = $dbxh->resultset('PharmGkbGene')->search(
        undef, { columns => [qw/ gene_id id /], }
    );
    
    my @gene_id_list;
    while ( my $result = $gene_id->next ){
        my $list = {
            gene => $result->gene_id,
            id   => $result->id,
        };
        push @gene_id_list, $list; 
    }

    # match the two above arrays.
    my @match = $self->match_builder(\@gene_id_list, $data );

    # matches are added to db.
    foreach my $i ( @match ) {
        $dbxh->resultset('PharmGkbDrug')->create({
            drug_id            => $i->[0]->{'drug_id'},
            drug_name          => $i->[0]->{'drug_name'},
            drug_gene_evidence => $i->[0]->{'gene_drug_evid'},
            PharmGKB_gene_id   => $i->[1],
        });
    }
}    

#------------------------------------------------------------------------------

sub _populate_drug_info {

    my ( $self, $drug_file ) = @_;

    my $dbxh = $self->get_mysql_dbxh;
    
    # get drug_id from the database
    my $drug_id = $dbxh->resultset('PharmGkbDrug')->search(
        undef, { columns => [qw/ drug_id id /], }
    );
    
    my @drug_id_list;
    while ( my $result = $drug_id->next ){
        my $list = {
            drug_id => $result->drug_id,
            id      => $result->id,
        };
        push @drug_id_list, $list; 
    }
    
    # match the two above arrays.
    my @match = $self->match_builder( \@drug_id_list, $drug_file, 'drug' );  

    foreach my $i ( @match ) {
       $dbxh->resultset('DrugInformation')->create({
            drug_id            => $i->[1],
            drug_info          => $i->[0],
            PharmGKB_drug_id   => $i->[2],
        });
    }
}

#------------------------------------------------------------------------------
sub _populate_omim_info {

    my ( $self, $omim ) = @_;
    
    my $dbxh = $self->get_mysql_dbxh;
    
    # capture list of gene_id's
    my $gene_id = $dbxh->resultset('PharmGkbGene')->search(
        undef, { columns => [qw/ id omim /], }
    );
    
    my @omim_id_list;
    while ( my $result = $gene_id->next ){
        my $list = {
            omim => $result->omim,
            id   => $result->id,
        };
        push @omim_id_list, $list; 
    }

    my @match = $self->match_builder( \@omim_id_list, $omim, 'omim' );  
    
    foreach my $i ( @match ) {
       $dbxh->resultset('OmimInformation')->create({
            cytogenetic_location => $i->[2],
            omim_disease         => $i->[1],
            status_code          => $i->[0],
            PharmGKB_gene_id     => $i->[3],
        });
    }
}

#------------------------------------------------------------------------------

sub _populate_rsid {
    my ( $self, $rsid ) = @_;
    
    my $dbxh = $self->get_mysql_dbxh;

    # capture list of gene names and id's from db
    my $gene_id = $dbxh->resultset('PharmGkbGene')->search(
        undef, { columns => [qw/ id symbol /], }
    );
    
    my @gene_list;
    while ( my $result = $gene_id->next ){
        my $list = {
            gene => $result->symbol,
            id   => $result->id,
        };
        push @gene_list, $list; 
    }

    foreach my $i ( @gene_list ){
        
        if ( ${ $rsid }{$i->{'gene'}} ) {
            $dbxh->resultset('RsidGene')->create({
                rsid             => ${ $rsid }{$i->{'gene'}},
                gene_symbol      => $i->{'gene'},
                PharmGKB_gene_id => $i->{'id'},
            });
        }
    }
}

#------------------------------------------------------------------------------

sub _populate_gvf_data {

    my ( $self, $data ) = @_;

    my $dbxh = $self->get_mysql_dbxh;
    
    # make a list of gene names
    my @gene_names = map {
        my $gene = $_->{'attribute'}->{'Variant_effect'};
        $gene =~ m/(\w+)\s+(\d+)\s+(gene)\s+(\w+)/gi;
        $4;
    } @$data;
    
    # capture list of gene names and id's from db
    my $gene_id = $dbxh->resultset('PharmGkbGene')->search(
        undef, { columns => [qw/ id symbol /], }
    );
    
    my @gene_list;
    while ( my $result = $gene_id->next ){
        my $list = {
            gene => $result->symbol,
            id   => $result->id,
        };
        push @gene_list, $list; 
    }    
    
    # genetate a match of gene list and db
    my %gene = $self->match_builder( \@gene_names, \@gene_list, 'gvf' );  
    
    # build db
    foreach my $i ( @{$data} ) {
        chomp $i;
        
        my $variant_effect = $i->{'attribute'}->{'Variant_effect'};
        if ( ! $variant_effect ) { next }
        if ( $variant_effect !~ /(\bgene\b)/ ) { next }
    
        $variant_effect =~ m/(\w+)\s+(\d+)\s+(gene)\s+(\w+)/gi;
    
        
        if ( $gene{$4} ) {
            $dbxh->resultset('Gvf')->create({
                seqid             => $i->{'seqid'},
                source            => $i->{'source'},
                type              => $i->{'type'},
                start             => $i->{'start'},
                end               => $i->{'end'},
                score             => $i->{'score'},
                strand            => $i->{'strand'},                
                attributes_id     => $i->{'attribute'}->{'ID'},
                alias             => $i->{'attribute'}->{'Alias'},
                dbxref            => $i->{'attribute'}->{'Dbxref'},
                variant_seq       => $i->{'attribute'}->{'Variant_seq'},
                reference_seq     => $i->{'attribute'}->{'Reference_seq'},
                variant_reads     => $i->{'attribute'}->{'Variant_reads'},
                total_reads       => $i->{'attribute'}->{'Total_reads'},
                zygosity          => $i->{'attribute'}->{'Zygosity'},
                variant_freq      => $i->{'attribute'}->{'Variant_freq'},
                variant_effect    => $i->{'attribute'}->{'Variant_effect'},
                start_range       => $i->{'attribute'}->{'Start_range'},
                end_range         => $i->{'attribute'}->{'End_range'},
                phased            => $i->{'attribute'}->{'Phased'},
                genotype          => $i->{'attribute'}->{'Genotype'},
                individual        => $i->{'attribute'}->{'Individual'},
                variant_codon     => $i->{'attribute'}->{'Variant_codon'},
                reference_codon   => $i->{'attribute'}->{'Reference_codon'},
                variant_aa        => $i->{'attribute'}->{'Variant_aa'},
                breakpoint_detail => $i->{'attribute'}->{'Breakpoint_detail'},
                sequence_context  => $i->{'attribute'}->{'Sequence_context'},
                PharmGKB_gene_id  => $gene{$4},
            });
        }
    }
}

#------------------------------------------------------------------------------









1;


