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
      '--/build-depends', '--/test-depends', '--/depends', 
      '--/p6c', '--/metacpan', '--/cpan',
      '--force', 'install', "./modules$path_sep$module";
}

exit $exit;
