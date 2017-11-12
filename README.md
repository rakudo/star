This git repository _only_ contains the tools needed to create a Rakudo Star distribution.

To get the latest release of Rakudo Star, please download a .tar.gz or .msi file from
https://rakudo.perl6.org/downloads/star/. Note: the tar files available from github.com
are NOT suitable for building Rakudo Star; do not use them.

If you're a Rakudo Star release manager, or someone who wants to create a new Perl 6
distributions based on the tools here, then run "make -f tools/star/Makefile" to 
populate a distribution image.

See tools/star/release-guide.pod for the steps needed to build
a candidate release.
