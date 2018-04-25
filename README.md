# Rakudo Star

This git repository contains _only_ the tools needed to create a Rakudo Star distribution.

The `tar` files available from `github.com`
are NOT suitable for building Rakudo Star; do not use them.

## Get Rakudo Star
To get the latest release of Rakudo Star, please download the corresponding file depending on your platform.

* Linux: https://rakudo.org/latest/star/source
* Windows: https://rakudo.org/latest/star/win64
* macOS: https://rakudo.org/latest/star/macos

## Build Rakudo Star
If you're a Rakudo Star release manager, or someone who wants to create a new Perl 6
distribution based on the tools here, then run `make -f tools/star/Makefile` to
populate a distribution image.

See [the release guide](tools/star/release-guide.pod) for the steps needed to build a candidate release.
