Rakudo Star -- a useful and usable production distribution of Perl 6

This git repository isn't the distribution itself; the repository
contains the tools and scripts used to create a distribution.

If you're looking to simply download and run the latest release
of Rakudo Star, please download a .tar.gz or .msi file from
http://rakudo.org/downloads/star/. Note: the tar files available
from github.com are NOT suitable for building Rakudo Star; do not use them.

If you're still reading this, we assume you're a Rakudo Star
release manager, or someone that is looking to create new
Perl 6 distributions based on the tools here.  Run 
"make -f tools/star/Makefile" to populate a distribution image.

See tools/star/release-guide.pod for the steps needed to build
a candidate release.
