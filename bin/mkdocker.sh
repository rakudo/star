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

	# Make the Docker image
	cd -- "$BASEDIR"
	docker build --build-arg "VERSION=$1" -t "rakudo-star:$1" .
	docker tag "rakudo-star:$1" rakudo-star:latest
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

Make a Docker image for Rakudo Star. This requires a release tarball to exist.
You must specify the same version argument as you supplied to mkrelease.sh.

Options:
	-h  Show this help text and exit.
EOF
}

main "$@"
