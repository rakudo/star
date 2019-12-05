#! perl

use warnings;
use strict;

my $perl6bin = shift @ARGV;
my $zefbin   = shift @ARGV;
my $exit     = 0;
my $path_sep = $^O eq 'MSWin32' ? '\\' : '/';

while (<>) {
	# Skip comments
	next if /^\s*(#|$)/;

	# Extract only the module name from the current line
	my ($module) = /(\S+)/;

	# Create the command list
	my @cmd = (
		$perl6bin,
		$zefbin,
		'--/build-depends',
		'--/depends',
		'--/test',
		'--/test-depends',
		'--force',
		'install',
		"./modules$path_sep$module"
	);

	# Show the command that's going to be ran, for debugging purposes
	printf "@cmd\n";

	# Actually run the command
	$exit ||= system "@cmd";
}

exit $exit;
