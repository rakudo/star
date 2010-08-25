#! perl

## Star patches to be applied to the 2010.08 release

my $DISTDIR = $ENV{'DISTDIR'};

system("cp build/patch/2010.08-3a339e.patch $DISTDIR/build");
system("cd $DISTDIR/rakudo; patch -p1 <../build/2010.08-3a339e.patch");

