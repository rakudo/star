#! perl

use strict;
use warnings;
use File::Spec;

my ($p6bin, $dest, $post, @files) = @ARGV;
die "Usage: $0 <perl6_binary> <destination_path> <source_files>"
    unless $p6bin && $dest;

for my $filename (@files) {
    open my $IN, '<', $filename
        or die "Cannot read file '$filename' for installing it: $!";
    my $basename = (File::Spec->splitpath($filename))[2];
    open my $OUT, '>', "$dest/$basename"
        or die "Cannot write file '$dest/$basename' for installing it: $!";
    while (<$IN>) {
        if ($. == 1 && /^#!/) {
            print { $OUT } "#!$p6bin\n";
        }
        else {
            print { $OUT } $_;
        }
    }
    close $OUT or die "Error while closing file '$dest/$basename': $!";
    close $IN;
    chmod 0755, "$dest/$basename";
    open my $ALIAS, '>', "$dest/$basename-$post"
        or die "Cannot write file '$dest/$basename-$post' for installing it: $!";
    printf { $ALIAS } <<'EOA', $p6bin, $dest, $basename;
#!/bin/sh
exec %s %s/%s "$@"
EOA
    close $ALIAS or die "Error while closing file '$dest/$basename-$post': $!";
    chmod 0755, "$dest/$basename-$post";
}
