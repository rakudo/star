# Rakudo Star

This git repository contains _only_ the tools needed to create a Rakudo Star distribution.

The `tar` files available from `github.com`
are NOT suitable for building Rakudo Star; do not use them.

## Get Rakudo Star
To get the latest release of Rakudo Star, please download the corresponding file depending on your platform.

* [Linux](https://rakudo.org/files/star/source)
* [Windows](https://rakudo.org/files/star/windows)
* [macOS](https://rakudo.org/files/star/macos)

## Build Rakudo Star
If you're a Rakudo Star release manager, or someone who wants to create a new Perl 6
distribution based on the tools here, then run `make -f tools/star/Makefile` to
populate a distribution image.

## Guides
* [Release guide](tools/star/release-guide.pod)

* [Guide to build MSI packages](tools/star/windows-msi.pod)

* [Guide to build DMG packages](tools/star/mac-dmg.pod)
