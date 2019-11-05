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

	# Build Rakudo Star from the release tarball
	mkdir -p -- "$BASEDIR/work/build"
	cd -- "$BASEDIR/work/build"
	tar xzf "$BASEDIR/work/release/rakudo-star-$1.tar.gz"
	cd "rakudo-star-$1"
	perl Configure.pl --prefix="$BASEDIR/work/install" --backend=moar --gen-moar
}

opts()
{
	OPTS=0

	while getopts ":h" opt
	do
		case "$opt" in
			h) OPT_HELP_ONLY=1 ;;
			*)
				printf "Invalid option passed: %s\n" "$OPTARG" >&2
				;;
		esac
	done
}

usage()
{
	cat <<EOF
Usage:
	$(basename "$0") -h
	$(basename "$0") <version>

Build Rakudo Star from a release tarball in $BASEDIR/work/release. This tarball
can be easily made using mkrelease.sh in this repository. This will not install
Raku in $BASEDIR/work/install, only build all the required components needed
for testing.

Options:
	-h  Show this help text and exit.
EOF
}

main "$@"
