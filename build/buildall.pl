#!/usr/bin/env perl
use strict;
use warnings;

use File::Spec;
use File::Copy;

my $inst_path = File::Spec->rel2abs(shift(@ARGV) || 'build');
print "Installing to '$inst_path'\n";
if ($inst_path =~ /\s/) {
    warn "Path names with whitspace are known to cause trouble\n"
        . "You would be on the safer side without them - set with $^X $0 'inst_path'\n";
}

chdir('rakudo') or die "Can't chdir to rakudo: $!";
print "Building parrot and Rakudo...\n";
system($^X, 'Configure.pl', '--gen-parrot', "--gen-parrot-refix=$inst_path") == 0
    or die "Can't run $^x Configure.pl ($?): $!";

my %config = read_parrot_config();
my $make = $config{make};

system($make, 'install') == 0
    or die "Can't run 'make install' for Rakudo: ($?): $!";

chdir('..') or die "Can't chdir back to .., something's seriously wrong!\n";

print "Rakudo build was successful. \\o/\n";

my $path_var_sep = $^O =~ /mswin32/i ? ';' : ':';
$ENV{PATH} = join '', "$inst_path/bin", $path_var_sep, $ENV{PATH};

my $res = qx/perl6 -e 'say "sanity";'/;
chomp $res;
if ($res ne 'sanity') {
    die "Sanity check for running Rakudo Perl 6 failed. Got '$res', Expected: 'sanity'\n"
        . "Aborting.\n";
}

print "Things look good so far, executing a very simple Perl 6 program worked!\n";

copy('ufo/ufo', "$inst_path/bin/") or die "Can't copy ufo/ufo to $inst_path/bin: $!";
print "We now have alien technology that lets us install more modules...\n";

$ENV{PLS_NO_FETCH} = 1;

chdir 'proto' or die "Can't chdir to 'proto': $!";
# TODO: find a better way to determine which modules to install in this step.
# Likely derive from @modules or so.
for (qw(xml-writer svg svg-plot)) {
    system('perl6', 'proof-of-concept', $_);
}


sub read_parrot_config {
    my %config = ();
    if (open my $CFG, "parrot/config_lib.pir") {
        while (<$CFG>) {
            if (/P0\["(.*?)"], "(.*?)"/) { $config{$1} = $2 }
        }
        close $CFG;
    }
    %config;
}


