package GVF::Clin;
use Moose;
use Moose::Util::TypeConstraints;
use Carp;

with 'GVF::Roles';

our $version = 'VERSION 0.01';

use Data::Dumper;

#-----------------------------------------------------------------------------
#------------------------------- Attributes ----------------------------------
#-----------------------------------------------------------------------------

has 'data_directory' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    reader   => 'get_directory',
);

has 'gvf_file' => (
    is       => 'rw',
    isa      => 'Str', 
    reader   => 'gvf_file',
    writer   => 'set_gvf_file',
    trigger  => \&_build_feature_lines,
);

has 'gene_names' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef',
    writer  => 'set_gene_name',
    handles => {
        get_gene_names => 'uniq',
    },
);

has 'fasta_file' => (
    is     => 'rw',
    isa    => 'Str',
    writer => 'set_fasta_file',
    reader => 'get_fasta_file',
);



sub gvf_data {
    my ( $self, $data, $request ) = @_;
    
    if ( ! $data->{'file'} && $data->{'fasta'} ) { die "Please correct file information $@\n"; }
    if ( -z  $data->{'file'} ) { die "Your file appears to be empty\n"; }
    
    $self->set_fasta_file( $data->{'fasta'} );
    $self->set_gvf_file( $data->{'file'} );
}


1;













__END__
=head1 NAME

GVF::Clin - The great new GVF::Clin!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use GVF::Clin;

    my $foo = GVF::Clin->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

shawn rynearson, C<< <shawn.rynearson at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-gvf-clin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=GVF-Clin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc GVF::Clin


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=GVF-Clin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/GVF-Clin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/GVF-Clin>

=item * Search CPAN

L<http://search.cpan.org/dist/GVF-Clin/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 shawn rynearson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of GVF::Clin
