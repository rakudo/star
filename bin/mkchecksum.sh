#! /usr/bin/env sh

main()
{
	# Handle opts
	opts "$@"
	shift "$OPTS"
	unset OPTS

	# Show help
	[ "$OPT_HELP_ONLY" ] && usage && exit 0
	[ -z "$1" ] && usage && exit 1

	printf "md5    %s\n" "$(md5sum "$1" | cut -f1 -d" ")"
	printf "sha1   %s\n" "$(sha1sum "$1" | cut -f1 -d" ")"
	printf "sha224 %s\n" "$(sha224sum "$1" | cut -f1 -d" ")"
	printf "sha256 %s\n" "$(sha256sum "$1" | cut -f1 -d" ")"
	printf "sha384 %s\n" "$(sha384sum "$1" | cut -f1 -d" ")"
	printf "sha512 %s\n" "$(sha512sum "$1" | cut -f1 -d" ")"
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
	$(basename "$0") <file>

Make a number of checksums of a given file.
EOF
}

main "$@"
