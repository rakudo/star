#! perl
# Copyright (C) 2009-2014 The Perl Foundation

use 5.008;
use strict;
use warnings;
use Text::ParseWords;
use Getopt::Long;
use File::Spec;
use Cwd;
use lib 'tools/lib';
use NQP::Configure qw(sorry slurp cmp_rev gen_nqp read_config 
                      fill_template_text fill_template_file
                      system_or_die verify_install);

my $lang = 'Rakudo';
my $lclang = lc $lang;
my $uclang = uc $lang;
my $slash  = $^O eq 'MSWin32' ? '\\' : '/';


MAIN: {
    if (-r 'config.default') {
        unshift @ARGV, shellwords(slurp('config.default'));
    }

    my %config = (perl => $^X);
    my $config_status = "${lclang}_config_status";
    $config{$config_status} = join ' ', map { qq("$_") } @ARGV;

    my $exe = $NQP::Configure::exe;

    my %options;
    GetOptions(\%options, 'help!', 'prefix=s',
               'backends=s', 'no-clean!',
               'gen-nqp:s', 'gen-moar:s',
               'gen-parrot:s', 'parrot-option=s@',
               'parrot-make-option=s@',
               'make-install!', 'makefile-timing!',
               'force!',
    ) or do {
        print_help();
        exit(1);
    };

    # Print help if it's requested
    if ($options{'help'}) {
        print_help();
        exit(0);
    }

    if (-d '.git') {
        worry( $options{'force'},
               "I see a .git directory here -- you appear to be trying",
              "to run Configure.pl from a clone of the Rakudo Star git",
              "repository.",
              $options{'force'}
                ? '--force specified, continuing'
                : download_text()
        );
    }


    $options{prefix} ||= 'install';
    $options{prefix} = File::Spec->rel2abs($options{prefix});
    my $prefix         = $options{'prefix'};
    my %known_backends = (parrot => 1, jvm => 1, moar => 1);
    my %letter_to_backend;
    my $default_backend;
    for (keys %known_backends) {
        $letter_to_backend{ substr($_, 0, 1) } = $_;
    }
    my %backends;
    if (defined $options{backends}) {
        for my $b (split /,\s*/, $options{backends}) {
            $b = lc $b;
            unless ($known_backends{$b}) {
                die "Unknown backend '$b'; Supported backends are: " .
                    join(", ", sort keys %known_backends) .
                    "\n";
            }
            $backends{$b} = 1;
            $default_backend ||= $b;
        }
        unless (%backends) {
            die "--prefix given, but no valid backend?!\n";
        }
    }
    else {
        for my $l (sort keys %letter_to_backend) {
            if (-x "$prefix/bin/nqp-$l" || -x "$prefix/bin/nqp-$l.bat" || -x "$prefix/bin/nqp-$l.exe") {
                my $b = $letter_to_backend{$l};
                print "Found $prefix/bin/nqp-$l (backend $b)\n";
                $backends{$b} = 1;
                $default_backend ||= $b;
            }
        }
        unless (%backends) {
            if (defined $options{'gen-moar'}) {
                $backends{moar} = 1;
            }
            else {
                $backends{parrot} = 1;
            }
        }
    }

    unless ($backends{parrot}) {
        warn "JVM/Moar-only builds are currently not supported, and might go wrong.\n";
    }

    # Save options in config.status
    unlink('config.status');
    if (open(my $CONFIG_STATUS, '>', 'config.status')) {
        print $CONFIG_STATUS
            "$^X Configure.pl $config{$config_status} \$*\n";
        close($CONFIG_STATUS);
    }

    $config{prefix} = $prefix;
    $config{slash}  = $slash;
    $config{'makefile-timing'} = $options{'makefile-timing'};
    $config{'stagestats'} = '--stagestats' if $options{'makefile-timing'};
    $config{'cpsep'} = $^O eq 'MSWin32' ? ';' : ':';
    $config{'shell'} = $^O eq 'MSWin32' ? 'cmd' : 'sh';
    my $make = $config{'make'} = $^O eq 'MSWin32' ? 'nmake' : 'make';

    my @prefixes = sort map substr($_, 0, 1), keys %backends;

    # determine the version of NQP we want
    my ($nqp_want) = split(' ', slurp('rakudo/tools/build/NQP_REVISION'));

    my %binaries;
    my %impls = gen_nqp($nqp_want, prefix => $prefix, backends => join(',', sort keys %backends), %options);

    my @errors;
    if ($backends{parrot}) {
        my %nqp_config;
        if ($impls{parrot}{config}) {
            %nqp_config = %{ $impls{parrot}{config} };
        }
        else {
            push @errors, "Cannot obtain configuration from NQP on parrot";
        }

        my $nqp_have = $nqp_config{'nqp::version'} || '';
        if ($nqp_have && cmp_rev($nqp_have, $nqp_want) < 0) {
            push @errors, "NQP revision $nqp_want required (currently $nqp_have).";
        }

        if (!@errors) {
            push @errors, verify_install([ @NQP::Configure::required_parrot_files,
                                        @NQP::Configure::required_nqp_files ],
                                        %config, %nqp_config);
            push @errors,
            "(Perhaps you need to 'make install', 'make install-dev',",
            "or install the 'devel' package for NQP or Parrot?)"
            if @errors;
        }

        if (@errors && !defined $options{'gen-nqp'}) {
            push @errors,
            "\nTo automatically clone (git) and build a copy of NQP $nqp_want,",
            "try re-running Configure.pl with the '--gen-nqp' or '--gen-parrot'",
            "options.  Or, use '--prefix=' to explicitly",
            "specify the path where the NQP and Parrot executable can be found that are use to build $lang.";
        }

        sorry(@errors) if @errors;

        %config = (%nqp_config, %config);
        print "Using $impls{parrot}{bin} (version $nqp_config{'nqp::version'}).\n";
    }
    if ($backends{jvm}) {
        $config{j_nqp} = $impls{jvm}{bin};
        $config{j_nqp} =~ s{/}{\\}g if $^O eq 'MSWin32';
        my %nqp_config;
        if ( $impls{jvm}{config} ) {
            %nqp_config = %{ $impls{jvm}{config} };
        }
        else {
            push @errors, "Unable to read configuration from NQP on the JVM";
        }
        my $bin = $impls{jvm}{bin};

        if (!@errors && !defined $nqp_config{'jvm::runtime.jars'}) {
            push @errors, "jvm::runtime.jars value not available from $bin --show-config.";
        }

        sorry(@errors) if @errors;

        print "Using $bin.\n";

    }

    fill_template_file('tools/build/Makefile.in', 'Makefile', %config);

    unless ($options{'no-clean'}) {
        no warnings;
        print "Cleaning up ...\n";
        if (open my $CLEAN, '-|', "$make configclean") {
            my @slurp = <$CLEAN>;
            close($CLEAN);
        }
    }

    if ($options{'make-install'}) {
        system_or_die($make);
        system_or_die($make, 'install');
        print "\n$lang has been built and installed.\n";
    }
    else {
        print "\nYou can now use '$make' to build $lang.\n";
        print "After that, '$make test' will run some tests and\n";
        print "'$make install' will install $lang.\n";
    }

    exit 0;
}


#  Print some help text.
sub print_help {
    print <<"END";
Configure.pl - $lang Configure

General Options:
    --help             Show this text
    --prefix=dir       Install files in dir; also look for executables there
    --backends=parrot,jvm,moar
                       Which backend(s) to use
    --gen-moar[=branch]
                       Download and build a copy of MoarVM
    --gen-nqp[=branch]
                       Download and build a copy of NQP
    --gen-parrot[=branch]
                       Download and build a copy of Parrot
    --parrot-option='--option'
                       Options to pass to Parrot's Configure.pl
    --parrot-make-option='--option'
                       Options to pass to Parrot's make, for example:
                       --parrot-make-option='--jobs=4'
    --makefile-timing  Enable timing of individual makefile commands

Configure.pl also reads options from 'config.default' in the current directory.
END

    return;
}

sub download_text {
    ("The git repository contains the tools needed to build a Rakudo Star",
     "release, but does not contain a complete Rakudo Star release.",
     "To download and build the latest release of Rakudo Star, please",
     "download a .tar.gz file from https://github.com/rakudo/star/downloads .")
}

sub worry {
    my ($force, @text) = @_;
    sorry(@text) unless $force;
    print join "\n", @text, '';
}


# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
