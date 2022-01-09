# Rakudo Star

A *user-friendly* distribution of the [Raku programming language](https://raku.org/).

## What's in this GIT repo

There are currently two different tools within this repo. The so called [`RSTAR utility`](https://github.com/rakudo/star/blob/master/bin/rstar),
which manages the Linux build, and the [chocolatey bases build script](https://github.com/rakudo/star/blob/master/tools/build/binary-release/Windows/build-with-choco.ps1), which manages the Windows MSI build.

### RSTAR utility

* BASH based tool, should work on any Linux OS (_and maybe also macOS_?)
* More information can be found in the [related Wiki page](https://github.com/rakudo/star/wiki/Rakudo-Star---Linux-package)

### build-with-choco.ps1 script
* [Powershell script](https://github.com/rakudo/star/blob/master/tools/build/binary-release/Windows/build-with-choco.ps1)
* chocolatey based, creates a Windows MSI package
* *More information to come soon*

### Community Modules

One of Rakudo Star's main features is in supplying users with a number of
popular community modules.

*You should always prefer to use a pinned version of a module, whereever versions are available!*

#### [modules.txt](https://github.com/rakudo/star/blob/master/etc/modules.txt)

This modules file contains references to all community modules to be bundled with Rakudo Star.
It is a space-separated format. The first column is the name of
the module, the second the protocol to use, with the third column being the
URL to fetch it from. Columns following the third have different meaning
depending on the protocol.

## Bugs, Feedback and Patches

### Bugs

* Please open an [GitHub Issue](https://github.com/rakudo/star/issues) for any found bug!
  * If you're reporting a RSTAR bug, please include the full logs of `rstar` with
    `RSTAR_DEBUG=1`, and the output of `rstar sysinfo` in your message.

### Code Contributions

* Please send your pull requests to the [RAKUDO Star](https://github.com/rakudo/star) repository!!
* Also, try to be generous with comments. Especially when introducing new utility
  functions, a little description of what it does and what problem it is intended
  to solve go a long way.
  
#### RSTAR utility
The `rstar` utility is written in `bash`. All additional features should be
based on this. Using other utilities is accepted, but effort should be made to
avoid introducing new utilities. Furthermore, all code should be linted against
[`shellcheck`](https://www.shellcheck.net/) and not produce any warnings.


### Repositories

The main git repository lives at [https://github.com/rakudo/star](https://github.com/rakudo/star). This should
be used as the reference to clone from.

Additionally, there are old mirrors of this repository at other places and from previous maintainers. You _may_ find additional helpful information there, which can help to get a better understanding and some history of the Star package:

- https://git.sr.ht/~tyil/rakudo-star
- https://gitlab.com/tyil/rakudo-star
- https://git.tyil.nl/rakudo-star
- https://github.com/Raku/rakudo-star

## License

The software in this repository is distributed under the terms of the Artistic
License 2.0, unless specified otherwise.
