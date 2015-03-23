#! perl

use strict;
use warnings;
use File::Spec;

my ($p6bin, $dest, $post, @files) = @ARGV;
die "Usage: $0 <perl6_binary> <destination_path> <source_files>"
    unless $p6bin && $dest;

for my $filename (@files) {
    my $basename = (File::Spec->splitpath($filename))[2];
    copy_file($filename, $basename);

    if ($^O eq 'MSWin32') {
        create_windows_bat("$basename.bat");
        copy_file($filename, "$basename-$post");
        create_windows_bat("$basename-$post.bat");
    }
    else {
        create_shell_wrapper($basename);
    }
}

sub copy_file {
    my ($infile, $outfile) = @_;
    open my $IN, '<', $infile
        or die "Cannot read file '$infile' for installing it: $!";
    open my $OUT, '>', "$dest/$outfile"
        or die "Cannot write file '$dest/$outfile' for installing it: $!";
    while (<$IN>) {
        if ($. == 1 && /^#!/) {
            # https://github.com/rakudo/star/issues/42
            # on Mac OS X, the interpreter must be a binary, so perl6-m
            # isn't a good choice; go with /usr/bin/env instead
            print { $OUT } "#!/usr/bin/env $p6bin\n";
        }
        else {
            print { $OUT } $_;
        }
    }
    close $OUT or die "Error while closing file '$dest/$outfile': $!";
    close $IN;
    chmod 0755, "$dest/$outfile";
}

sub create_shell_wrapper {
    my ($basename) = @_;
    open my $ALIAS, '>', "$dest/$basename-$post"
        or die "Cannot write file '$dest/$basename-$post' for installing it: $!";
    printf { $ALIAS } <<'EOA', $p6bin, $dest, $basename;
#!/bin/sh
exec %s %s/%s "$@"
EOA
    close $ALIAS or die "Error while closing file '$dest/$basename-$post': $!";
    chmod 0755, "$dest/$basename-$post";
}

sub create_windows_bat {
    my ($basename) = @_;
    open my $ALIAS, '>', "$dest/$basename"
        or die "Cannot write file '$dest/$basename' for installing it: $!";
    printf { $ALIAS } <<'EOA', $p6bin, $p6bin;
@rem = '--*-Perl-*--
@echo off
if "%%OS%%" == "Windows_NT" goto WinNT
%s "%%~dpn0" %%1 %%2 %%3 %%4 %%5 %%6 %%7 %%8 %%9
goto endofperl
:WinNT
%s "%%~dpn0" %%*
if NOT "%%COMSPEC%%" == "%%SystemRoot%%\system32\cmd.exe" goto endofperl
if %%errorlevel%% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
@rem ';
__END__
:endofperl
EOA
    close $ALIAS or die "Error while closing file '$dest/$basename': $!";
}
