#! perl

use warnings;
use strict;
my $perl6bin = shift @ARGV;
my $zefbin   = shift @ARGV;

my $exit = 0;

my $path_sep = "/";
$path_sep = "\\" if ( $^O eq 'MSWin32' );

while (<>) {
    next if /^\s*(#|$)/;
    my ($module) = /(\S+)/;
    $exit ||= system $perl6bin, $zefbin,
      '--force', '--/test', 'install', "./modules$path_sep$module";
}

exit $exit;
