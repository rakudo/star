#! perl

use Cwd;

my $base = shift @ARGV;
my $perl6 = shift @ARGV;

while (<>) {
    next if /^\s*(#|$)/;
    my ($moduledir) = /(\S+)/;
    print "Testing modules/$moduledir with $perl6...\n";
    if (-d "$base/modules/$moduledir/t") {
        chdir("$base/modules/$moduledir");
        system('prove', '-e', $perl6, '-r', 't');
    }
    else {
        print "...no t/ directory found.\n";
    }
    print "\n";
}

0;
