#! perl

use warnings;
use strict;
use File::Find;
use File::Copy;
use File::Path;
use File::Basename;

my $perl6 = shift @ARGV;
my $perl6lib = shift @ARGV;

my @pmfiles;
while (@ARGV) {
    my $module = shift @ARGV;
    our $mlib   = "$module/lib";

    find({ no_chdir=>1, wanted => \&libcopy }, $mlib);

    sub libcopy {
        return unless /\.pm6?/;
        my $source = $File::Find::name;
        my $target = $source;
        $target =~ s/$mlib/$perl6lib/;
        print "$source => $target\n";
        mkpath dirname($target);
        copy($source, $target) or die "copy failed: $!\n";
        push @pmfiles, $target;
    }
}

foreach my $pm (@pmfiles) {
    my $out = $pm;  $out =~ s/\.pm6?$/.pir/;
    my @cmd = ('./perl6', '--target=pir', "--output=$out", $pm);
    print join(' ', @cmd), "\n";
    system(@cmd);
}
