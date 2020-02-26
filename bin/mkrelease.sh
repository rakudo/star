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

	# Make the release
	cd -- "$BASEDIR"
	make -f tools/star/Makefile all VERSION="$1" \
		&& make -f tools/star/Makefile release VERSION="$1"
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

Make a releasable tarball of Rakudo Star. You must specify a version number,
which will be used to name the tarball. The tarball will be put in
$BASEDIR/work/release. You will still have to manually create checksums and a
PGP signature.

Options:
	-h  Show this help text and exit.
EOF
}

main "$@"
