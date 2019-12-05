#! perl

use warnings;
use strict;

use Cwd;
use Getopt::Long;

GetOptions('verbose' => \my $verbose);

my $base = shift @ARGV;
my $perl6 = shift @ARGV;

while (<>) {
	# Skip comments
	next if /^\s*(#|$)/;

	# Extract only the module name from the current line
	my ($moduledir) = /(\S+)/;

	# Run the tests through prove
	if (-d "$base/modules/$moduledir/t") {
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
		exit 1 if $exit;
	}
	else {
		print "...no t/ directory found.\n";
	}

	print "\n";
}

# If we reach this, no errors have been found
exit 0;
