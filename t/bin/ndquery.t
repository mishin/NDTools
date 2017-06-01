use strict;
use warnings FATAL => 'all';

use Capture::Tiny qw(capture);
use Test::File::Contents;
use Test::More tests => 9;

use lib "t";
use NDToolsTest;

chdir t_dir or die "Failed to change test dir";

my (@cmd, $out, $err, $exit);

### essential tests

@cmd = qw/ndquery <\/dev\/null/;
($out, $err, $exit) = capture { system("@cmd") };
is($out, '', "Check STDOUT for '@cmd'");
like($err, qr/FATAL] Failed to decode/, "Check STDERR for '@cmd'");
is($exit >> 8, 4, "Check exit code for '@cmd'");

@cmd = qw/ndquery -vv -v4 --verbose --verbose 4 -V/;
($out, $err, $exit) = capture { system(@cmd) };
like($out, qr/^\d+\.\d+/, "Check STDOUT for '@cmd'");
like($err, qr//, "Check STDERR for '@cmd'"); # FIXME
is($exit >> 8, 0, "Check exit code for '@cmd'");

@cmd = qw/ndquery -h --help/;
($out, $err, $exit) = capture { system(@cmd) };
is($out, '', "Check STDOUT for '@cmd'");
file_contents_eq_or_diff('help.exp', $err, "Check STDERR for '@cmd'");
is($exit >> 8, 0, "Check exit code for '@cmd'");

### bin specific tests

