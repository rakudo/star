#! /usr/bin/env sh

readonly BASEDIR=$(CDPATH="" cd -- "$(dirname -- "$0")/.." && pwd -P)

main()
{
	# Handle opts
	opts "$@"
	shift "$OPTS"
	unset OPTS

	# Show help
	[ "$OPT_HELP_ONLY" ] && usage && exit 0
	[ -z "$1" ] && usage && exit 1

	prefix="${OPT_PREFIX:-$BASEDIR/work/install}"

	# Exit after every failure from here on out
	set -e

	# Build Rakudo Star from the release tarball
	mkdir -p -- "$BASEDIR/work/build"
	cd -- "$BASEDIR/work/build"
	tar xzf "$BASEDIR/work/release/rakudo-star-$1.tar.gz"
	cd "rakudo-star-$1"
	perl Configure.pl --prefix="$prefix" --backend=moar --gen-moar

	if [ "$OPT_INSTALL" ]
	then
		make install
	fi
}

opts()
{
	OPTS=0

	while getopts ":hip:" opt
	do
		case "$opt" in
			h) OPT_HELP_ONLY=1 ;;
			i) OPT_INSTALL=1 ; OPTS=$(( OPTS + 1 )) ;;
			p) OPT_PREFIX=$OPTARG ; OPTS=$(( OPTS + 2 )) ;;
			*)
				printf "Invalid option passed: %s\n" "$OPTARG" >&2
				;;
		esac
	done

	unset opt
}

usage()
{
	cat <<EOF
Usage:
	$(basename "$0") -h
	$(basename "$0") [-i [-p <path>]] <version>

Build Rakudo Star from a release tarball in $BASEDIR/work/release. This tarball
can be easily made using mkrelease.sh in this repository. If you don't specify
-i, this will not install Raku in $BASEDIR/work/install. This can be convenient
if you just want to run some simple tests.

Options:
	-h  Show this help text and exit.
	-i  Also install the freshly built Rakudo Star.
	-p  Set a prefix to install Rakudo Star into. Defaults to ./work/install,
	    relative to the repository root.
EOF
}

main "$@"
