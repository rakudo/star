# Rakudo-Star

A *user-friendly* distribution of the [Raku programming language](https://raku.org/).

## Docker Image

* Please refer to [Rakudo-Star on Docker Hub](https://hub.docker.com/_/rakudo-star) for an image.
* Find the related Docker files on the ["Raku Docker" GitHub repository](https://github.com/Raku/docker) 

## What's in this GIT repo

There are currently two different tools within this repo:
1. The so called [`RSTAR tool`](https://github.com/rakudo/star/blob/master/bin/rstar), which manages the **Linux build** and local installation.
2. The [chocolatey based Powershell build script](https://github.com/rakudo/star/blob/master/tools/build/binary-release/Windows/build-with-choco.ps1), which creates a **Windows MSI** package.

Both tools compile Rakudo and then add some selected modules!

### 1. _RSTAR_ tool

* `bash` based tool, should work on any **Linux OS** (_should also build Rakudo-Star on macOS_!?).
  - The `rstar` (bash) tool downloads all requirements, like MoarVM, NQP, Rakudo and some Rakudo modules.
  - It then compiles everything into a local Rakudo installation and add's the modules via `zef`.
* More information can be found in the [related Wiki page](https://github.com/rakudo/star/wiki/01_Rakudo-Star---Linux-package)

As the `rstar` utility is written in `bash`, all additional features should also be
based on `bash`. Using other utilities is accepted, but efforts should be made to
avoid introducing new utilities.

Furthermore, all code should be linted against [`shellcheck`](https://www.shellcheck.net/) and not produce any warnings.

### 2. _BUILD-WITH-CHOCO.PS1_ tool

* A [Powershell script](https://github.com/rakudo/star/blob/master/tools/build/binary-release/Windows/build-with-choco.ps1), which internally uses `chocolatey` to create a **Windows MSI** package.
    - The created MSI package can be used to install Rakudo-Star (Rakudo with some additional modules) on any Windows device.
* *More information to be added* in the [wiki](https://github.com/rakudo/star/wiki) 

### 3. Community Modules

Rakudo-Star's only main features is to support it's users with a number of
popular community modules.

*You should always prefer to use a pinned version of a module, wherever versions are available!*
Therefore all Rakudo modules, which are included into Star, need i.e. to have `git tags`.

#### [modules.txt](https://github.com/rakudo/star/blob/master/etc/modules.txt)

This modules file contains references to all community modules to be bundled with Rakudo-Star.
It is a space-separated format. The first column is the name of
the module, the second the protocol to use, with the third column being the
URL to fetch it from. Columns following the third have different meaning
depending on the protocol.

*Currently all modules are expected to be available via `git` (GitHub) and having `git tags`, similar to the `version` given in the modules `META6.json`* 

## Bugs, Feedback and Patches

### Bugs

* Please open an [GitHub Issue](https://github.com/rakudo/star/issues) for any found bug!
  * If you're reporting a RSTAR bug, please include the full logs of `rstar` with
    `RSTAR_DEBUG=1`, and the output of `rstar sysinfo` in your message.

### Feedback

#### Mail and IRC

* If you have a question about Rakudo-Star, you probably want to write to the “perl6-users@perl.org” mailing list or ask the [irc.libera.chat/#raku-star](https://web.libera.chat/#raku-star) IRC channel.

#### GitHub Platform

* Knowledge and documentation related to Rakudo-Star can be published in the related [wiki](https://github.com/rakudo/star/wiki).
* There is also [Star discussions](https://github.com/rakudo/star/discussions) for any kind of ongoing discussions, alignements, FAQ's, ...
  * Once things are discussed, agreed, finalized, they should be documented in the Wiki, see above!

### Patches And Code Contributions

* Please send your pull requests to the [RAKUDO-Star](https://github.com/rakudo/star) repository!
* Also, try to be generous with comments. Especially when introducing new utility
  functions, a little description of what it does and what problem it is intended
  to solve go a long way.

### Various GIT Repositories

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
