#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use File::Copy;
use autodie qw(mkdir chdir open close copy);

my @modules = qw(
    http://github.com/rakudo/rakudo
    http://github.com/jnthn/zavolaj
    http://github.com/jnthn/blizkost
    http://github.com/mberends/MiniDBI
    http://github.com/masak/svg
    http://github.com/moritz/svg-plot
    http://github.com/moritz/Math-RungeKutta
    http://github.com/moritz/Math-Model
    http://github.com/mattw/form
    http://github.com/tadzik/perl6-Config-INI
    http://github.com/tadzik/perl6-File-Find
    http://github.com/tadzik/perl6-Term-ANSIColor
    http://github.com/arnsholt/Algorithm-Viterbi
    http://gitorious.org/http-daemon/mainline
);

mkdir 'dist' unless -e 'dist';

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
my %tags = ( rakudo => '2010.07' );

while (my ($project, $version) = each %tags) {
    chdir $project;
    system('git', 'checkout', $version) == 0
        or die "Can't git checkout $version: $?";
    chdir '..';
}

chdir('..');

copy('build/buildall.pl', 'dist/');
# TODO: copy docs, build scripts, whatever
#
