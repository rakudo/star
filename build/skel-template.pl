use strict;
use warnings;

my $destination = shift(@ARGV) || die "Usage: $0 <destination>";
unless (-d $destination) {
    die "Destination '$destination' should be a directory, but is not";
}

my %look_for = (PARROT_VER => 1,  RAKUDO_VER => 1,  NQP_VER => 1);
my %vars;

open my $fh, '<', 'Makefile'
    or die "Cannot open Makefile for reading: $!";

while (<$fh>) {
    chomp;
    if (/^(\w+)\s*=\s*(\S*)/ && $look_for{$1}) {
        delete $look_for{$1};
        $vars{$1} = $2;
        last unless %look_for;
    }
}
close $fh;
if (%look_for) {
    die "Couldn't find a definition for the following variable(s) in Makfile\n"
        . join(', ', keys %look_for) . "\n";
}

my $subst_re = join '|', map quotemeta, keys %vars;
$subst_re = qr{\<($subst_re)\>};

# XXX recursive traversal + templating NYI, one level is enough for a start

for my $file (glob 'template-skel/*') {
    my $dest = $file;
    $dest =~ s{^template-skel/}{$destination/};
    process_file($file, $dest);
}

sub process_file {
    my ($source, $dest) = @_;
    print "Processing '$source' into '$dest'\n";
    open my $in, '<', $source
        or die "Cannot open '$source' for reading: $!";
    open my $out, '>', $dest
        or die "Cannot open '$dest' for writing: $!";
    while (<$in>) {
        s/$subst_re/$vars{$1}/g;
        print { $out } $_  or die "Cannot write to '$dest': $!";
    }
    close $in;
    close $out or die "Cannot close '$dest': $!";
}
