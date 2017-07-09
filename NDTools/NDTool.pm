package NDTools::NDTool;

use strict;
use warnings FATAL => 'all';

use Encode::Locale qw(decode_argv);
use NDTools::INC;
use NDTools::Slurp qw(s_dump s_load);
use Getopt::Long qw(:config bundling);
use Log::Log4Cli;
use Pod::Usage;
use Struct::Path 0.71 qw(spath);

sub VERSION { "n/a" }

sub arg_opts {
    my $self = shift;
    return (
        'dump-opts' => \$self->{OPTS}->{'dump-opts'},
        'help|h' => sub { $self->usage; exit 0 },
        'pretty!' => \$self->{OPTS}->{pretty},
        'verbose|v:+' => \$Log::Log4Cli::LEVEL,
        'version|V' => sub { print $self->VERSION . "\n"; exit 0 },
    );
}

sub configure {
    my $self = shift;
}

sub defaults {
    return {
        'pretty' => 1,
        'verbose' => $Log::Log4Cli::LEVEL,
    };
}

sub dump_opts {
    my $self = shift;

    delete $self->{OPTS}->{'dump-opts'};
    s_dump(\*STDOUT, undef, undef, $self->{OPTS});
}

sub grep {
    my ($self, $data, $spath) = @_; # $data is a list if data entries

    my @out;
    for my $i (@{$data}) {
        my @found = eval { spath($i, $spath, deref => 1, paths => 1) };

        my $tmp;
        while (@found) {
            my ($p, $r) = splice @found, 0, 2;
            spath(\$tmp, $p, assign => $r, expand => 'append');
        }

        push @out, $tmp if (defined $tmp);
    }

    return @out;
}

sub load_uri {
    my ($self, $uri) = @_;
    log_trace { ref $uri ? "Reading from STDIN" : "Loading '$uri'" };
    s_load($uri, undef) or return undef;
}

sub new {
    my $self = bless {}, shift;
    $self->{OPTS} = $self->defaults();

    decode_argv(Encode::FB_CROAK);
    unless (GetOptions ($self->arg_opts)) {
        $self->usage;
        die_fatal "Unsupported opts used", 1;
    }

    $self->configure();

    if ($self->{OPTS}->{'dump-opts'}) {
        $self->dump_opts();
        die_info, 0;
    }

    return $self;
}

sub usage {
    pod2usage(
        -exitval => 'NOEXIT',
        -output => \*STDERR,
        -sections => 'SYNOPSIS|OPTIONS|EXAMPLES',
        -verbose => 99
    );
}

1; # End of NDTools::NDTool
