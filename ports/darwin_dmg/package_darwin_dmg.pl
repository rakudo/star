#!/usr/bin/perl
use strict;
use warnings;
use Carp;
use Getopt::Long;
use Data::Dumper; $Data::Dumper::Useqq = 1;

my $USAGE = <<"END_OF_USAGE";
$0 yyyy mm
    --build
        Build Rakudo (MoarVM) from the tarball.
        Defaults to only packaging what is already built.
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
    Remove the underscore from /Applications/Rakudo, changing it to a space.
        This will require upstream changes to Rakudo, but Parrot itself seems OK with an embedded space.
    Include all the dependent libs; gmp, pcre, opengl, zlib, gettext, icu, libffi,readline
        So far, we build with these libs disabled to allow Rakudo to run on systems that lack the libs.

=end comments

=cut


GetOptions(
    'build'     => \( my $opt_build_rakudo ),
    'time'      => \( my $opt_time  ),
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
my $vol_name     = 'Rakudo';
# XXX rename to install_dir?
my $src_dir      = '/Applications/Rakudo';

my $vol_dir      = "/Volumes/$vol_name";
my $tar_dir      = "rakudo-star-$yyyy.$mm";
my $tar_file     = "rakudo-star-$yyyy.$mm.tar.gz";
my $final_dmg    = "Rakudo_$yyyy-$mm";
my $license_path = "../../../LICENSE";
#my $license_path = "$src_dir/share/doc/rakudo/LICENSE";


if ( $opt_build_rakudo ) {

    run "rm -rf '$src_dir'";

    my $ocwd = qx!pwd!;
    chomp $ocwd;

    chdir "../..";

    run "perl Configure.pl --gen-moar --prefix /Applications/Rakudo";
    run "make install";

    chdir $ocwd;

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
$size += int( $size * 0.20 ); # Add 20% for file system
run "hdiutil create  '$temp_dmg' -ov -size ${size}k -fs HFS+ -volname '$vol_name' -attach";

print "Copying Rakudo files\n";
run "CpMac -r '$src_dir'    '$vol_dir'";
run "cp ../HOW_TO_INSTALL.txt  '$vol_dir'";
run "cp -pr ../../../docs  '$vol_dir'";

run "touch                        '$vol_dir/Rakudo/Icon\r'";
run "cp ../2000px-Camelia.svg.icns $vol_dir/.VolumeIcon.icns";
run "sips -i                       $vol_dir/.VolumeIcon.icns";
run "DeRez -only icns              $vol_dir/.VolumeIcon.icns > tempicns.rsrc";
run "Rez -append tempicns.rsrc -o '$vol_dir/Rakudo/bin/perl6'";
run "Rez -append tempicns.rsrc -o '$vol_dir/Rakudo/Icon\r'";
run "SetFile -c icnC              '$vol_dir/.VolumeIcon.icns'";
run "SetFile -a C                 '$vol_dir'";
run "SetFile -a C                 '$vol_dir/Rakudo'";
run "SetFile -a C                 '$vol_dir/Rakudo/bin/perl6'";
run "SetFile -a V                 '$vol_dir/Rakudo/Icon\r'";
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
#run "Rez Carbon.r '$r_path' -append -o '$final_dmg.dmg'"; # Carbon.r has type definitions.
run "hdiutil flatten                   '$final_dmg.dmg'";
unlink $r_path or die;

chdir '..' or die;


sub create_sla_file {
    croak 'Wrong number of arguments' if @_ != 3;
    my ( $license_path, $template_path, $output_r_path ) = @_;

    my $license_munged = '';
    open my $license_fh,  '<', $license_path or die "not found at $license_path";
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
