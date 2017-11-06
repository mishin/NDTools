package App::NDTools::NDQuery;

use strict;
use warnings FATAL => 'all';
use parent 'App::NDTools::NDTool';

use Digest::MD5 qw(md5_hex);
use JSON qw();
use Log::Log4Cli;
use App::NDTools::Slurp qw(s_dump);
use Struct::Path 0.71 qw(slist spath spath_delta);
use Struct::Path::PerlStyle qw(ps_parse ps_serialize);
use Term::ANSIColor qw(colored);

sub VERSION { '0.26' };

sub arg_opts {
    my $self = shift;

    return (
        $self->SUPER::arg_opts(),
        'colors!' => \$self->{OPTS}->{colors},
        'delete|ignore=s@' => \$self->{OPTS}->{delete},
        'depth|d=i' => \$self->{OPTS}->{depth},
        'grep=s@' => \$self->{OPTS}->{grep},
        'items' => \$self->{OPTS}->{items},
        'list|l' => \$self->{OPTS}->{list},
        'md5' => \$self->{OPTS}->{md5},
        'path|p=s' => \$self->{OPTS}->{path},
        'raw-output' => sub { $self->{OPTS}->{ofmt} = 'RAW' },
        'replace' => \$self->{OPTS}->{replace},
        'strict!' => \$self->{OPTS}->{strict},
        'values|vals' => \$self->{OPTS}->{values},
    );
}

sub check_args {
    my $self = shift;

    if ($self->{OPTS}->{replace}) {
        die_fatal "--replace opt can't be used with --items", 1
            if ($self->{OPTS}->{items});
        die_fatal "--replace opt can't be used with --list", 1
            if ($self->{OPTS}->{list});
        die_fatal "--replace opt can't be used with --md5", 1
            if ($self->{OPTS}->{md5});
    }

    return $self;
}

sub configure {
    my $self = shift;

    $self->{OPTS}->{colors} = -t STDOUT ? 1 : 0
        unless (defined $self->{OPTS}->{colors});

    for (
        @{$self->{OPTS}->{grep}},
        @{$self->{OPTS}->{delete}}
    ) {
        my $tmp = eval { ps_parse($_) };
        die_fatal "Failed to parse '$_'", 4 if ($@);
        $_ = $tmp;
    }

    return $self;
}

sub defaults {
    my $self = shift;

    return {
        %{$self->SUPER::defaults()},
        'color-common' => 'bold black',
        'strict' => 1, # exit with 8 if unexisted path specified
        'ofmt' => 'JSON',
    };
}

sub dump {
    my ($self, $uri, $data) = @_;

    $uri = \*STDOUT unless ($self->{OPTS}->{replace});
    s_dump($uri, $self->{OPTS}->{ofmt}, undef, @{$data});
}

sub exec {
    my $self = shift;

    $self->check_args(@ARGV) or die_fatal undef, 1;

    for my $uri (@ARGV ? @ARGV : \*STDIN) {
        my @data = $self->load_struct($uri);

        if (defined $self->{OPTS}->{path}) {
            my $spath = eval { ps_parse($self->{OPTS}->{path}) };
            die_fatal "Failed to parse '$self->{OPTS}->{path}'", 4 if ($@);

            unless (@data = spath($data[0], $spath, deref => 1)) {
                die_fatal "Failed to lookup path '$self->{OPTS}->{path}'", 8
                    if ($self->{OPTS}->{strict});
                next;
            }
        }

        @data = $self->grep($self->{OPTS}->{grep}, @data)
            if (@{$self->{OPTS}->{grep}});

        for my $spath (@{$self->{OPTS}->{delete}}) {
            map { spath($_, $spath, delete => 1) if (ref $_) } @data;
        }

        if ($self->{OPTS}->{items}) {
            $self->items(\@data);
        } elsif ($self->{OPTS}->{list}) {
            $self->list($uri, \@data);
        } elsif ($self->{OPTS}->{md5}) {
            $self->md5($uri, \@data);
        } else {
            $self->dump($uri, \@data);
        }
    }

    die_info "All done", 0;
}

sub items {
    my ($self, $data) = @_;

    for (@{$data}) {
        if (ref $_ eq 'HASH') {
            print join("\n", sort keys %{$_}) . "\n";
        } elsif (ref $_ eq 'ARRAY') {
            print "0 .. " . $#{$_} . "\n";
        } else {
            print(($_ // 'null') . "\n");
        }
    }
}

sub list {
    my ($self, $uri, $data) = @_;

    for (@{$data}) {
        my @list = slist($_, depth => $self->{OPTS}->{depth});
        my ($base, @delta, $line, $path, $prev, $value, @out);

        while (@list) {
            ($path, $value) = splice @list, 0, 2;

            @delta = spath_delta($prev, $path);
            $base = [ @{$path}[0 .. @{$path} - @delta - 1] ];
            $line = $self->{OPTS}->{colors}
                ? colored(ps_serialize($base), $self->{OPTS}->{'color-common'})
                : ps_serialize($base);
            $line .= ps_serialize(\@delta);

            if ($self->{OPTS}->{values}) {
                $line .= " = ";
                if ($self->{OPTS}->{ofmt} eq 'RAW' and not ref ${$value}) {
                    $line .= ${$value};
                } else {
                    $line .= JSON->new->canonical->allow_nonref->encode(${$value});
                }
            }

            push @out, $line;
            $prev = $path;
        }

        print join("\n", @out) . "\n";
    }
}

sub md5 {
    my ($self, $uri, $data) = @_;

    print md5_hex(JSON->new->canonical->allow_nonref->encode($_)) .
        (ref $uri ? "\n" : " $uri\n")
            for (@{$data});
}

1; # End of App::NDTools::NDQuery
