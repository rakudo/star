#! perl

# Add a prefix string (specified by $ARGV[0]) to all 
# of the lines of the remaining files.  Skips blank lines
# and lines beginning with a comment character.

my $prefix = shift @ARGV;
while (<>) { 
    next if /^\s*(#|$)/;
    print "$prefix$_"; 
}

