# Rakudo Star

A user-friendly distribution of the Raku programming language.

## Quickstart

After downloading and extracting the tarball (or cloning the git repository),
run `./bin/rstar install`. Follow any on-screen instructions as they appear.
That is all!

If you happen to find any bugs, please refer to the **Bugs, Feedback and
Patches** section later on in this document to find out how you can get help.

## Advanced usage

This section is intended for maintainers of the Rakudo Star distribution.

### The `rstar` utility

To help maintainers build the distribution tarball, and end-users to make
effective use of the tarball, a utility has been created, called `rstar`. This
utility depends on the `bash` shell being available. Run it with `-h` to see
what it can do.

Depending on what action you're trying to run, additional dependencies may be
required. If any of these are missing, `rstar` will throw an error about it.

#### Exit codes

- `  1` - die() was encountered. This is always a bug;
- `  2` - The program was invoked incorrectly;
- `  3` - Some required dependencies are missing.

#### Environment Variables

The `rstar` utility can be affected by environment variables. These may help
out when debugging issues.

- `RSTAR_DEBUG` - If set to a non-null value, additional debugging output will
  magically appear;
- `RSTAR_MESSY` - If set to a non-null value, the `tmp` directory will not be
  cleaned when `rstar` exits.

### Community Modules

One of Rakudo Star's main features is in supplying users with a number of
popular community modules. This section details the mechanics of how these are
included.

*You should always prefer to use a pinned version of a module!*

#### modules.txt

This file contains references to all community modules to be bundled with
Rakudo Star. It is a space-separated format. The first column is the name of
the module, the second the protocol to use, with the third column being the
URL to fetch it from. Columns following the third have different meaning
depending on the protocol.

##### `git`

The git protocol clones a single ref, with a depth of 1. Which ref is going to
be cloned is specified in the 4th column of its `modules.txt` entry. After
cloning, the `.git` directory is removed.

##### `http 

The http protocol is the most straightforward, it downloads a tarball
(`.tar.gz`) and unpacks it. If a value is specified in the 4th column of the
entry, this will be used as prefix, and will be stripped away when the
extracted sources are moved into the `dist` directory.

### Quickstart to Releasing Rakudo Star

Your first step will be to prepare a new tarball.

    rstar clean                 # Clean up old sources
    $EDITOR etc/dist_moarvm.txt # Update values as necessary
    $EDITOR etc/dist_nqp.txt    # Update values as necessary
    $EDITOR etc/dist_rakudo.txt # Update values as necessary
    $EDITOR etc/modules.txt     # Update values as necessary
    rstar fetch                 # Download new sources
    rstar install               # Compile and install Rakudo Star
    rstar test                  # Run tests
    rstar dist                  # Create a new distribution tarball

Once you have a tarball, you should upload it to be available to others. Common
places include:

- rakudo.org (ask around in #raku-dev for someone to help you if needed);
- Your personal website.

Next up, you will have to tell people of the new distribution tarball existing.
There are several places to announce this at. The most "official" one would be
the `perl6-compiler@perl.org` mailing list. The `perl6-users@perl.org` mailing
list is also a good choice, as are public places such as Reddit.

## Bugs, Feedback and Patches

Bugs, feedback or patches for this project can be sent to
`p.spek+rakudo-star@tyil.work`. Alternatively, you can reach out to `tyil` on
Freenode, DareNET or Matrix.

## License

The software in this repository is distributed under the terms of the Artistic
License 2.0, unless specified otherwise.
