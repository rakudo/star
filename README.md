# Rakudo Star

Rakudo Star is a user-oriented distribution of the Raku programming language,
and a number of common community modules.

This git repository contains _only_ the tools needed to create a Rakudo Star
distribution, not the sources of individual components of the distribution.
These are fetched when you build the distribution tarball.

The `tar` files available from `github.com` for MoarVM, NQP and Rakudo are NOT
suitable for building Rakudo Star; do not use them. Instead, use the tarballs
found on the individual projects' sites, which correctly contain all the
utilities and dependencies used by them.

## Get Rakudo Star

To get the latest release of Rakudo Star, please download the corresponding
file depending on your platform.

- [Linux](https://rakudo.org/latest/star/source)
- [Windows](https://rakudo.org/latest/star/win64)
- [macOS](https://rakudo.org/latest/star/macos)

## Build Rakudo Star

If you're a Rakudo Star release manager, or someone who wants to create a
user-friendly Raku distribution based on the tools here, check the `guides`
directory. This contains documentation on how to make a Rakudo Star tarball, as
well as information on how to create Windows `.msi` and MacOS `.dmg` packages.

### Quickstart

    export VERSION=quickstart # Update to whatever version number you want to use
    ./bin/mkrelease.sh "$VERSION"
    mkdir -p work/build
    tar xzf "work/release/rakudo-star-$VERSION.tar.gz" -C work/build
    cd "work/build/rakudo-star-$VERSION"
    perl Configure.pl --prefix="../../install" --backend=moar --gen-moar --make-install

If you're satisfied, you probably want to generate checksums and a detached PGP
signature for the release.

    ./bin/mkchecksum "work/release/rakudo-star-$VERSION.tar.gz"
    gpg --armor --detach-sign "work/release/rakudo-star-$VERSION.tar.gz"
