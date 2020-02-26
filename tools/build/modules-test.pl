#! perl

use warnings;
use strict;

use Cwd;
use Getopt::Long;

GetOptions('verbose' => \my $verbose);

my $base = shift @ARGV;
my $perl6 = shift @ARGV;
my @failures;

while (<>) {
	# Skip comments
	next if /^\s*(#|$)/;

	# Extract only the module name from the current line
	my ($moduledir) = /(\S+)/;

	if (! -d "$base/modules/$moduledir/t") {
		print "[" . getcwd . "] ...no t/ directory found.\n";
		next;
	}

	# Run the tests through prove
	chdir("$base/modules/$moduledir");

	my @cmd = (
		'prove',
		$verbose ? '-v' : (),
		'-e', $perl6,
		'-r',
		't',
	);

	# Show the command that's going to be ran, for debugging purposes
	print "[" . getcwd . "] @cmd\n";

	# Actually run the command
	my $exit = system "@cmd";

	# Exit early if any errors occurred
	if ($exit) {
		push @failures, $_;
	}

	print "\n";
}

# If we reach this, no errors have been found
if (@failures) {
	print "The following modules failed their tests:\n";

	foreach (@failures) {
		print "- $_\n";
	}

	exit 1;
}
