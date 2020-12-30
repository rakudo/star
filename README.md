# Rakudo Star

A user-friendly distribution of the Raku programming language.

## Quickstart

*If you cloned the git repository, you will need to run `./bin/rstar fetch`
first.*

After downloading and extracting the tarball, run `./bin/rstar install`. Follow
any on-screen instructions as they appear. That is all!

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

- `  1` - `die()` was encountered. This is always a bug;
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

##### `http`

The http protocol is the most straightforward, it downloads a tarball
(`.tar.gz`) and unpacks it. If a value is specified in the 4th column of the
entry, this will be used as prefix, and will be stripped away when the
extracted sources are moved into the `dist` directory.

### Quickstart to Releasing Rakudo Star

Your first step will be to prepare a new tarball.

    rstar clean -s              # Clean up old sources
    $EDITOR etc/fetch_core.txt  # Update values as necessary
    $EDITOR etc/modules.txt     # Update values as necessary
    git commit                  # Create a commit for this particular release
    rstar fetch                 # Download new sources
    rstar install               # Compile and install Rakudo Star
    rstar test                  # Run tests
    rstar dist                  # Create a new distribution tarball

Additionally, you *should* make a tag that represents the current release name.

Once you have a tarball, you should upload it to be available to others. Common
places include:

- [rakudo.org](https://rakudo.org/) (ask around in `#raku-dev` for someone to
  help you if needed);
- Your personal website.

Next up, you will have to tell people of the new distribution tarball existing.
There are several places to announce this at. The most "official" one would be
the `perl6-compiler@perl.org` mailing list. The `perl6-users@perl.org` mailing
list is also a good choice, as are public places such as Reddit.

## Bugs, Feedback and Patches

Patches for this project can be sent through email to
`p.spek+rakudo-star@tyil.work`.

To report bugs or provide other feedback, email is an option, but IRC and
[Matrix](https://matrix.org/) are also available. For IRC, reach out to `tyil`
on [Freenode](https://freenode.net/) or [DareNET](https://www.darenet.org/).
For Matrix, send a message to `tyil:matrix.org`.

### Bugs

If you're reporting a bug, please include the full logs of `rstar` with
`RSTAR_DEBUG=1`, and the output of `rstar sysinfo` in your message.

### Code Contributions

Code patches can be sent through email. For help getting started with
contributing in this fashion, check out https://git-send-email.io/.

The `rstar` utility is written in `bash`. All additional features should be
based on this. Using other utilities is accepted, but effort should be made to
avoid introducing new utilities. Furthermore, all code should be linted against
[`shellcheck`](https://www.shellcheck.net/) and not produce any warnings.

Also, try to be generous with comments. Especially when introducing new utility
functions, a little description of what it does and what problem it is intended
to solve go a long way.

### Repositories

The main git repository lives at https://git.tyil.nl/rakudo-star. This should
be used as the reference to clone from.

Additionally, there are mirrors of this repository at other places. You _can_
make use of these mirrors and the services they offer (such as issue tracking
or web-based "merge requests"), but they are in no way guaranteed to be taken
into account.

- https://git.sr.ht/~tyil/rakudo-star
- https://gitlab.com/tyil/rakudo-star
- https://github.com/rakudo/star

## License

The software in this repository is distributed under the terms of the Artistic
License 2.0, unless specified otherwise.
