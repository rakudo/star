#!/usr/bin/perl
use strict;
use warnings;
use Carp;
use Getopt::Long;
use Data::Dumper; $Data::Dumper::Useqq = 1;

my $USAGE = <<"END_OF_USAGE";
$0 [-q|--quiet] yyyy mm
    --build
        Build Parrot and Rakudo from the tarball.
        Defaults to only packaging what is already built.
    -q, --quiet
        Suppress pausing for "OK" input.
        (Not yet implemented)
    -v
    --verbose
        Report each command that is run.
    --time
        Report timings for each step.
    YYYY
        4 digit year
    MM
        2 digit month, 01..12
END_OF_USAGE

=begin comments

(Note: The build process below (except downloading the tarball) is automated in this script) 
Note: For this .dmg packaging procedure work, Rakudo Star must be built like this:
XXX Can we use .app to automatically have them look in the right place, even when uninstalled in .dmg?
Here are the key parts of the build process, the parts that you might not expect from your normal build experience with Parrot and Rakudo:
    Rather than having Rakudo automatically build Parrot, we must build Parrot ourselves, to configure it specially.
    Configure Parrot with --optimize, --prefix with the installation dir, and --without any libs that any user might not have on their system.
    Configure Rakudo pointing --parrot-config to the parrot_config in the installation dir.
    Rename the build dir (to anything else) after building.
    Run `install_name_tool` on all the exes in the installation dir, updating the location in which they will look for libparrot.dylib.
        (This part will get merged into pbc_to_exe soon)
    
Failure to follow this packaging procedure will result in a `perl6` executable that runs fine, *until* the original build directory is removed.
Therefore, the `perl6` executable would test fine on your system, but fail on every system that installed it from the .dmg!

Run this to make sure that all is well so far.
    $src_dir/bin/perl6 -e 'say "OK so far"'

At this point, you can run this script.
    perl package_star.pl

Does the .dmg packaging procedure really need to be this complex?
Yes! The single-line process that we *wish* we could use does not allow:
    * symlink to /Applications (so they have to know to drag-and-drop outside the window)
    * background images
    * click-through licenses
    * auto-open the Finder window after .dmg is opened.

TODO:
    Add background images
        Camelia
        Arrow to show drag-and-drop to Applications (like in DMGs from Processing.org)
    Add a .dmg-specific HOW_TO_INSTALL.txt
    Demo code (as opposed to Example code that we already have)
    Click on .app for REPL
    Remove the underscore from /Applications/Rakudo_Star, changing it to a space.
        This will require upstream changes to Rakudo, but Parrot itself seems OK with an embedded space.
    Include all the dependent libs; gmp, pcre, opengl, zlib, gettext, icu, libffi,readline
        So far, we build with these libs disabled to allow Rakudo to run on systems that lack the libs.

=end comments

=cut


GetOptions(
    'build'     => \( my $opt_build_parrot_and_rakudo ),
    'time'      => \( my $opt_time  ),
    'quiet'     => \( my $opt_quiet ),
    'verbose|v' => \( my $opt_verbose ),
    'help|h'    => \( my $opt_help ),
) or die $USAGE;

print $USAGE and exit(0) if $opt_help;

my ( $yyyy, $mm ) = @ARGV; # Version

die $USAGE if @ARGV != 2
           or $yyyy !~ m{ \A \d{4} \z }msx
           or $mm   !~ m{ \A \d{2} \z }msx
           or $mm < 1 or $mm > 12;

sub run {
    croak if not @_;
    my (@command) = @_;

    print "> @command\n" if $opt_verbose;

    my $start = time;
    my $rc = system(@command);
    die if $rc != 0;
    my $stop = time;

    printf ">! %4d\t%s\n", $stop-$start, "@command" if $opt_time;
    return;
}


my $temp_dir     = 'Temp_build';
my $temp_dmg     = 'temp';
my $vol_name     = 'Rakudo_Star';
# XXX rename to install_dir?
my $src_dir      = '/Applications/Rakudo_Star';

my $vol_dir      = "/Volumes/$vol_name";
my $tar_dir      = "rakudo-star-$yyyy.$mm";
my $tar_file     = "rakudo-star-$yyyy.$mm.tar.gz";
my $final_dmg    = "Rakudo_Star_$yyyy-$mm";
my $license_path = "$src_dir/share/doc/rakudo/LICENSE";


if ( $opt_build_parrot_and_rakudo ) {
    my $full_parrot_path;

    run "rm -rf '$src_dir'";
    run "rm -rf  $tar_dir";
    run "tar zxf $tar_file";

    chdir $tar_dir or die;

    my ($parrot_dir) = glob 'parrot-*';
    chdir $parrot_dir or die;
    chomp( $full_parrot_path = `pwd` );
    run "perl Configure.pl --prefix=/Applications/Rakudo_Star --optimize"
      . " --without-gettext --without-gmp --without-libffi --without-opengl"
      . " --without-readline --without-pcre --without-zlib --without-icu"
      . "             > conf.1 2>conf.2";
    run "make         > make.1 2>make.2";
    run "make install > inst.1 2>inst.2";
    chdir '..';

    run "perl Configure.pl --parrot-config=/Applications/Rakudo_Star/bin/parrot_config"
      . "             > conf.1 2>conf.2";
    run "make         > make.1 2>make.2";
    run "make install > inst.1 2>inst.2";

#    run "make blizkost-install > bliz.1 2>bliz.2";
# XXX Not running for now, because OS X 10.5 comes with Perl 5.8.8, and blizkost requires 5.10.

    run "cp -r docs                             /Applications/Rakudo_Star/";
    run "mv    /Applications/Rakudo_Star/parrot /Applications/Rakudo_Star/docs/";
    run "mv    /Applications/Rakudo_Star/rakudo /Applications/Rakudo_Star/docs/";

    chdir '..';
    
    run "rm -rf          $tar_dir-renamed_for_testing";
    run "mv -i  $tar_dir $tar_dir-renamed_for_testing";

    my @exe_paths = map {"$src_dir/bin/$_"} qw(
        ops2c
        parrot
        parrot-nqp
        parrot-prove
        parrot_config
        parrot_debugger
        parrot_nci_thunk_gen
        pbc_disassemble
        pbc_dump
        pbc_merge
        pbc_to_exe
        perl6
    );
    die if grep { not -e $_ } @exe_paths;

    for my $exe_path (@exe_paths) {
        run "install_name_tool -change $full_parrot_path/blib/lib/libparrot.dylib $src_dir/lib/libparrot.dylib $exe_path";
    }
}


if ( `$src_dir/bin/perl6 -e 42.say` ne "42\n" ) {
    die "The perl6 exe will not run, so we cannot make a .dmg for it! ($src_dir/bin/perl6)\n";
}

if ( -e $vol_dir ) {
    run "diskutil eject $vol_dir";
}
if ( -e $temp_dir ) {
    run "rm -rf '$temp_dir'";
}
mkdir $temp_dir or die;
chdir $temp_dir or die;

my $size = `du -ks '$src_dir'`;
$size =~ s{ \A \s* (\d+) \t \S.* \z }{$1}msx or die;
$size += int( $size * 0.05 ); # Add 5% for file system
run "hdiutil create  '$temp_dmg' -ov -size ${size}k -fs HFS+ -volname '$vol_name' -attach";


print "Copying Rakudo files\n";
run "CpMac -r '$src_dir'    '$vol_dir'";
run "cp ../HOW_TO_INSTALL.txt  '$vol_dir'";

run "touch                        '$vol_dir/Rakudo_Star/Icon\r'";
run "cp ../2000px-Camelia.svg.icns $vol_dir/.VolumeIcon.icns";
run "sips -i                       $vol_dir/.VolumeIcon.icns";
run "DeRez -only icns              $vol_dir/.VolumeIcon.icns > tempicns.rsrc";
run "Rez -append tempicns.rsrc -o '$vol_dir/Rakudo_Star/bin/perl6'";
run "Rez -append tempicns.rsrc -o '$vol_dir/Rakudo_Star/Icon\r'";
run "SetFile -c icnC              '$vol_dir/.VolumeIcon.icns'";
run "SetFile -a C                 '$vol_dir'";
run "SetFile -a C                 '$vol_dir/Rakudo_Star'";
run "SetFile -a C                 '$vol_dir/Rakudo_Star/bin/perl6'";
run "SetFile -a V                 '$vol_dir/Rakudo_Star/Icon\r'";
run "rm tempicns.rsrc";


print ">>> Adjusting sizes and positions in installation window\n";
run "osascript ../adjust_installation_window.scpt";


print ">>> Waiting on .DS_STORE to be written\n";
sleep 1 while not -s "$vol_dir/.DS_STORE";

print ">>> Compressing\n";
run "diskutil eject $vol_dir";
run "hdiutil convert '$temp_dmg.dmg' -format UDBZ -o '$final_dmg'";
unlink "$temp_dmg.dmg" or die;


print ">>> Adding click-thru license and auto-open\n";
my $r_path        =  './SLA_rakudo_star.r';
my $template_path = '../SLA_rakudo_star.template.r';
create_sla_file( $license_path, $template_path, $r_path );

run "hdiutil unflatten                 '$final_dmg.dmg'";
run "Rez Carbon.r '$r_path' -append -o '$final_dmg.dmg'"; # Carbon.r has type definitions.
run "hdiutil flatten                   '$final_dmg.dmg'";
unlink $r_path or die;

chdir '..' or die;


sub create_sla_file {
    croak 'Wrong number of arguments' if @_ != 3;
    my ( $license_path, $template_path, $output_r_path ) = @_;

    my $license_munged = '';
    open my $license_fh,  '<', $license_path or die;
    while (<$license_fh>) {
        s{"}{\\"}g;
        s{\n}{\\n};
        $license_munged .= qq{    "$_"\n};
    }
    close $license_fh or warn;

    open my $template_fh, '<', $template_path or die;
    open my $r_fh, '>', $output_r_path or die;
    {
        local $/ = undef; # Slurp mode
        local $_ = <$template_fh>;
        s{\[% ENGLISH_LICENSE %\]}{$license_munged} or die;
        print {$r_fh} $_;
    }
    close $template_fh or warn;
    close $r_fh        or warn;
}
