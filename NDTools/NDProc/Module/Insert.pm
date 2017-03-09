package NDTools::NDProc::Module::Insert;

use strict;
use warnings FATAL => 'all';
use parent "NDTools::NDProc::Module";

use NDTools::INC;
use Log::Log4Cli;
use Struct::Path qw(spath);
use Struct::Path::PerlStyle qw(ps_parse);

sub MODINFO { "Insert substructure/value into structure" }
sub VERSION { "0.04" }

sub arg_opts {
    my $self = shift;
    return (
        $self->SUPER::arg_opts(),
        'boolean=s'   => sub {
            require JSON;
            if ($_[1] =~ /^true$/i) {
                $self->{OPTS}->{value} = JSON::true;
            } elsif ($_[1] =~ /^false$/i) {
                $self->{OPTS}->{value} = JSON::false;
            } elsif ($_[1]) {
                $self->{OPTS}->{value} = JSON::true;
            } else {
                $self->{OPTS}->{value} = JSON::false;
            }
        },
        'file|f=s' => \$self->{OPTS}->{file},
        'null|undef' => sub { $self->{OPTS}->{value} = undef },
        'number=f' => sub { $self->{OPTS}->{value} = 0 + $_[1] },
        'string|value=s' => \$self->{OPTS}->{value},
    )
}

sub configure {
    my $self = shift;
    $self->{OPTS}->{value} = $self->load_uri($self->{OPTS}->{file})
        if (defined $self->{OPTS}->{file});
}

sub process {
    my ($self, $data, $opts) = @_;
    for my $path (@{$opts->{path}}) {
        log_info { 'Updating path "' . $path . '"' };

        my $spath = eval { ps_parse($path) };
        die_fatal "Failed to parse path ($@)", 4 if ($@);

        my @places = eval { spath($data, $spath, expand => 1) };
        die_fatal "Failed to resolve path ($@)", 4 if ($@);

        for my $place (@places) {
            $$place = $opts->{value};
        }
    }
}


1; # End of NDTools::NDProc::Module::Insert

__END__

=head1 NAME

Insert - substructure/value into structure

=head1 OPTIONS

=over 4

=item B<--boolean> E<lt>true|false|1|0E<gt>

Boolean value to insert.

=item B<--file|-f> E<lt>fileE<gt>

Load substructure from file.

=item B<--null|--undef>

Insert null value.

=item B<--number> E<lt>numberE<gt>

Number to insert.

=item B<--path> E<lt>pathE<gt>

Path in the structure to deal with. May be used several times.

=item B<--string> E<lt>stringE<gt>

String to insert.

=back

=head1 SEE ALSO

L<ndproc(1)>, L<ndproc-modules>

L<nddiff(1)>, L<ndquery(1)>, L<Struct::Path::PerlStyle>

