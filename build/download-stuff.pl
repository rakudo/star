#!/usr/bin/perl
use strict;
use warnings;

my @modules = qw(
    http://github.com/rakudo/rakudo
    http://github.com/jnthn/zavolaj
    http://github.com/mberends/fakedbi
    http://github.com/masak/svg
    http://github.com/moritz/svg-plot
    http://github.com/moritz/Math-RungeKutta
    http://github.com/moritz/Math-Model
);

chdir 'dist' or die "Can't chdir to build dir: $!";

for my $m (@modules) {
    my $git_url = $m;
    $git_url =~ s/^http/git/;
    $git_url .= '.git';
    my $return = system 'git', 'clone', $git_url;
    if ($return) {
        if ($? == -1) {
            warn "Error while running 'git clone $git_url': $?\n";
        } else {
            warn "Git returned unsuccessfully with return code "
                    . ($? >> 8) . "\n";
        }
        next;
    }
}

# for projects of which we want to ship specific tags or branches
# the right-hand side can be anything that 'git checkout' accepts,
# so a branch name, tag name, sha1 sum, HEAD~3 ( not quite sane, 
# but possible )
#
#  XXX we want rakudo 2010.07 of course, but that will give an error now
my %tags = ( rakudo => '2010.06' );

while (my ($project, $version) = each %tags) {
    chdir $project or die "Can't chdir to '$project': $!";
    system('git', 'checkout', $version) == 0
        or die "Can't git checkout $version: $?";
    chdir '..' or die "Can't chdir back to dist/ folder: $!";
}

# TODO: copy docs, build scripts, whatever
