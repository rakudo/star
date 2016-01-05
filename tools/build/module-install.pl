#! perl

use warnings;
use strict;
my $perl6bin   = shift @ARGV;
my $pandabin   = shift @ARGV;
my $bindir     = shift @ARGV;

my $exit = 0;

while (<>) {
    next if /^\s*(#|$)/;
    my ($module) = /(\S+)/;
    $exit ||= system $perl6bin, $pandabin, '--force', "--bin-prefix=$bindir", "install", "modules/$module";
}

exit $exit;
