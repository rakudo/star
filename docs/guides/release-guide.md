# Rakudo Star release guide

Rakudo Star releases are based on Rakudo compiler releases. Since some time is
often needed for module updates and testing after each Rakudo compiler release,
the timing of Star releases varies from one release to the next.

Also, while the Rakudo compiler issues monthly releases, Star releases are free
to choose a longer release cycle. Star releases are also free to choose older
releases of the compiler, NQP, or MoarVM. The goal is to balance end-user
stability needs with progress being made on the compiler, modules, and other
runtime components. Currently, Star is on a quarterly release cycle.

## Creating a release distribution

If this is your first time releasing, **read the whole guide before starting**.
That way you can ask questions and clear up and confusions before you're in the
thick of it.

If you have done this before, you might want to check for and read any changes
to this release guide since your last run.

### Clone this repository

    git clone git://gitlab.com/tyil/rakudo-star.git

If this is not your first time, you probably already have a copy of this
repository, in which case you should pull the latest changes.

    git pull origin master

### Branch out

Since all the information is stored in git, this is a great moment to create a
new branch. This will make it easier to roll back if things go horribly wrong,
and to create a merge request later on to get other people to review the
changes.

    git switch -c $VERSION-rc1

### Update all community modules

All community modules that are going to be bundled with this release need to be
made up-to-date. These are managed as submodules, so `git submodule` comes in
handy here.

    git submodule sync
    git submodule update --init --recursive
    git submodule foreach git pull origin master
    git commit -m "Update submodules"

At this point `git status` should report a clean repository.

### Set component versions

Inside the repository is a Makefile which indicates which versions of upstream
components should be used. This file can be found at `tools/star/Makefile`.
These version numbers are *usually* similar, but not necesarily. Specifically,
it is about the values for `RAKUDO_VER`, `NQP_VER`, `MOAR_VER`.

If unsure, ask for the specific value for `RAKUDO_VER` in `#raku-dev` on
`irc.freenode.net`. The `NQP_VER` can be found inside the Rakudo repository, in
`tools/build/NQP_REVISION`, and the `MOAR_VER` can be found in the NQP
repository in the `tools/build/MOAR_REVISION` file.

    $EDITOR tools/star/Makefile
    git commit -m "Bump component versions"

### Create a release announcement

For every release, an announcement should be made. These can be found in
`docs/announce`. They follow the same versioning scheme as Rakudo Star itself,
and as such, the name for the new one should have the current version number,
followed by `.md` since the announcements are in Markdown.

You should include the latest version number changes, community module changes
(updated ones, deleted ones, new ones), and any other information which might
be relevant to end-users or package maintainers.

    $EDITOR docs/announce/$VERSION.md
    git add !$
    git commit -m "Add release announcement for $VERSION"

### Bump Rakudo Star version number

The version number for Rakudo Star itself is referred to in another file,
`Makefile.in`, which needs updating.

    $EDITOR tools/build/Makefile.in.
    git commit -m "Bump Rakudo Star version"

### Publish changes

With all the prep-work done, it is time to build an actual release
distribution. This is done using GitLab CI, so all you need to do now is push
the changes back to the repository. Generally, this would be done through a
merge request, so the changes can be reviewed and approved. Luckily, you're
already using a seperate branch, so this is pretty straightforward as well.

    git push origin $VERSION-rc1

This should give you an URL to create a merge request directly, however, if it
does not, you'll have to use your `$BROWSER` to go to the repository web page,
and make one manually.

### Creating the release candidate

GitLab CI has been set up to create a new release on every branch or tag. As
such, the previous `git push` should have started a CI job to build a
distribution tarball. If it did not, please consult `#raku-dev` on
`irc.freenode.net`.

The CI setup also contains a testing phase, where the resulting tarball is
compiled and tested. If any of these steps fail, a solution must be found. The
best place to discuss options would be, again, the `#raku-dev` channel.

### Creating the official release

Once the release candidate has been approved to become an official release, the
branch can be merged into `master`. Afterwards, create a new tag for the new
release, and push it to the remote repository. GitLab CI will make a tarball
for you.

    git switch master
    git pull origin master
    git tag -s $VERSION
    git push origin $VERSION

The `-s` option for `git tag` makes you sign this particular tag with your PGP
key. All tags must be signed, so if you lack a PGP key, you should [strongly
consider to get yourself one](https://fedoraproject.org/wiki/Creating_GPG_Keys).

### Publishing the official release

Once GitLab CI has built and tested the final image, you can download it as an
artifact from the job. The job is of stage "Package, and name "Tarball".
Downloading the artifacts will get you a zip file with the tarball inside of
it. Extract the zipfile to some temporary location. Next, create a PGP
signature and checksums for it, to allow other people to verify they got the
right thing.

For checksumming, a small utility can be found in the `bin` directory,
`mkchecksum`, which will generate a number or checksum formats for a given
file.

    cd -- "$(mktemp -d)"
    wget "$ARTIFACTS_URL"
    unzip download
    cd work/release
    gpg --armor --detach-sig *.tar.gz
    mkchecksum *.tar.gz > rakudo-star-$VERSION.tar.gz.checksum.txt

Lastly, the three files you have right now should be uploaded to the remote
server hosting official releases.

TODO: I currently don't have any information on this step yet!

    If you don't have permission to do this step, please ask one of the core
    devs (pmichaud, jnthn, masak, PerlJam/perlpilot, tadzik, or moritz) on
    C<#perl6> to do it for you.

### Announce the new release

Now that a new release has been made, you're *technically* done. However, it
would be much appreciated if you also announce to the rest of the world that a
new release has been published. The most important place would be `rakudo.org`.

#### rakudo.org
The sources of this site can be found in the
[`perl6/rakudo.org`](https://github.com/perl6/rakudo.org repository on GitHub).
It contains a small script to make this easier, called
`push-latest-rakudo-star-announcement.p6`. You will need to have a working
`perl6` in your `$PATH`, and have the `WWW` module installed.

    cd -- "$(mktemp -d)"
    git clone git@github.com:perl6/rakudo.org .
    ./push-latest-rakudo-star-announcement.p6 $VERSION

You will also have to bump versions manually in C<templates/files.html.ep> in
the rakudo.org repo.

#### Other places of importance

There are more places around the 'net that should be informed of the new
release. These are not all documented, so you may have to ask around to get
access.

- http://perl6.org/
- perl6-users@perl.org
- perl6-language@perl.org
- perl6-compiler@perl.org
- http://en.wikipedia.org/wiki/Rakudo_Perl_6 (latest release date is mentioned in the main text)
- http://en.wikipedia.org/wiki/Perl_6

You should actively ask others to advertise the release as well. This includes
their social media accounts and blogs. Notable places include:

- http://blogs.perl.org/
- [Perl 6 Facebook Page](https://www.facebook.com/groups/1595443877388632/)
- Reddit: [r/perl](https://www.reddit.com/r/perl/),
  [r/rakulang](https://www.reddit.com/r/rakulang/),
  [r/programming](https://www.reddit.com/r/programming/)
- [Hacker News](https://news.ycombinator.com/news)
- Twitter: [@rakudoperl](https://twitter.com/rakudoperl)

### Give yourself some credit

Add this release and your name to the list of releases at the end of this
document, to eternalize your fame. This may also help other people interested
in making releases to find people to help them when any issues arrive.

    $EDITOR docs/guides/release-guide.md

You may want to commit and push this file as well, of course.

**You're done!** Celebrate with the appropriate amount of fun.

## Rakudo Star release list

- `2019.03`: hankache, clarkema
- `2018.10`: stmuk
- `2018.06`: stmuk
- `2018.04`: stmuk
- `2018.01`: stmuk
- `2017.10`: stmuk
- `2017.07`: stmuk
- `2017.04`: stmuk
- `2017.01`: stmuk
- `2016.11`: stmuk
- `2016.10`: stmuk
- `2016.07`: stmuk
- `2016.04`: stmuk
- `2016.01`: FROGGS
- `2015.11`: moritz
- `2015.09`: moritz
- `2015.07`: moritz
- `2015.06`: FROGGS
- `2015.03`: moritz
- `2015.02`: moritz
- `2015.01`: moritz
- `2014.12`: moritz
- `2014.09`: FROGGS
- `2014.08`: FROGGS
- `2014.04`: jnthn
- `2014.03`: FROGGS
- `2014.01`: tadzik
- `2013.12`: lue
- `2013.11`: moritz
- `2013.10`: lue
- `2013.09`: moritz
- `2013.08`: moritz
- `2013.05`: pmichaud
- `2013.02`: moritz
- `2013.01`: moritz
- `2012.12`: moritz
- `2012.11`: moritz
- `2012.10`: jnthn
- `2012.09`: pmichaud
- `2012.08`: pmichaud
- `2012.07`: pmichaud
- `2012.06`: moritz
- `2012.05`: moritz
- `2012.04`: moritz
- `2012.02`: jnthn
- `2012.01`: jnthn
- `2011.07`: pmichaud
- `2011.04`: pmichaud
- `2011.01`: pmichaud
- `2010.12`: pmichaud
- `2010.11`: pmichaud
- `2010.10`: pmichaud
- `2010.09`: pmichaud
- `2010.08`: pmichaud
- `2010.07`: pmichaud
