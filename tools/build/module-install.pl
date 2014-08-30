#! perl

use warnings;
use strict;
use File::Find;
use File::Copy;
use File::Path;
use File::Basename;

my $perl6bin = shift @ARGV;
my $perl6lib = shift @ARGV;
my $compext = shift @ARGV;
my $comptarget = shift @ARGV;

my @pmfiles;
my @mod_pms;
while (<>) {
    next if /^\s*(#|$)/;
    my ($module) = /(\S+)/;
    print "== Installing modules/$module\n";
    our $mlib  = "modules/$module/lib";
    
    @mod_pms = ();
    find({ no_chdir=>1, wanted => \&libcopy }, $mlib);

    sub libcopy {
        return unless /\.pm6?$|\.pod$/;
        my $source = $File::Find::name;
        my $target = $source;
        $target =~ s/\Q$mlib\E/$perl6lib/;
        print "$source => $target\n";
        mkpath dirname($target);
        copy($source, $target) or die "copy failed: $!\n";
        push @mod_pms, $target if $target =~ /\.pm6?$/;
    }
    
    my %usages_of;
    my @modules;
    my %module_to_path;
    for my $module_file (@mod_pms) {
        open(my $fh, '<', $module_file) or die $!;
        my $module = path_to_module_name($module_file);
        push @modules, $module;
        $module_to_path{$module} = $module_file;
        $usages_of{$module} = [];
        while (<$fh>) {
            if (/^\s* (?:use|need|require) \s+ (\w+ (?: :: \w+)*)/x and my $used = $1) {
                next if $used eq 'v6';
                next if $used eq 'MONKEY_TYPING';

                push @{$usages_of{$module}}, $used;
            }
        }
    }
    
    my @order = topo_sort(\@modules, \%usages_of);
    my @sources = map { $module_to_path{$_} } @order;
    push @pmfiles, @sources;
}

# Internally, we treat the module names as module names, '::' and all.
# But since they're really files externally, they have to be converted
# from paths to module names, and back again.

sub path_to_module_name {
    $_ = shift;
    s/^.+\blib\///;
    s/^.+\blib6\///;
    s/\.pm6?$//;
    s/\//::/g;
    $_;
}

do {
    local $ENV{'PERL6LIB'} = $perl6lib;

    print "== Precompiling modules\n";
    chdir 'rakudo';
    foreach my $pm (@pmfiles) {
        my @cmd = ($perl6bin, "--target=$comptarget", "--output=$pm.$compext", $pm);
        print join(' ', @cmd), "\n";
        system(@cmd);
    }
};


# According to "Introduction to Algorithms" by Cormen et al., topological
# sort is just a depth-first search of a graph where you pay attention to
# the order in which you get done with a dfs-visit() for each node.

sub topo_sort {
    my ($modules, $dependencies) = @_;
    my @modules = @$modules;
    my @order;
    my %color_of = map { $_ => 'not yet visited' } @modules;

    for my $module (@modules) {
        if ($color_of{$module} eq 'not yet visited') {
            dfs_visit($module, \%color_of, $dependencies, \@order);
        }
    }
    return @order;
}

sub dfs_visit {
    my $module = shift;
    my $color_of = shift;
    my $dependencies = shift;
    my $order = shift;
    $color_of->{$module} = 'visited';
    for my $used (@{$dependencies->{$module}}) {
        $color_of->{$used} ||= '';
        if ($color_of->{$used} eq 'not yet visited') {
            dfs_visit($used, $color_of, $dependencies, $order);
        }
    }
    push @$order, $module;
}
