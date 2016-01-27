#! perl

use warnings;
use strict;
my $perl6bin   = shift @ARGV;
my $pandabin   = shift @ARGV;

my $exit = 0;

while (<>) {
    next if /^\s*(#|$)/;
    my ($module) = /(\S+)/;
    $exit ||= system $perl6bin, $pandabin, '--force', "install", "modules/$module";
}

exit $exit;
