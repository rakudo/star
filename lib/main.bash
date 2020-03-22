#!/usr/bin/env bash

source "$(dirname "$BASH_SOURCE")/util.bash"
source "$(dirname "$BASH_SOURCE")/logging.bash"

main() {
	[[ -z $1 ]] && usage && exit 2

	local action="$1"
	shift

	debug "Handling action '$action'"

	local action_path="$BASEDIR/lib/actions/$action.bash"

	debug "Checking $action_path"

	if [[ ! -f $action_path ]]
	then
		debug "No script found to handle action, showing usage"
		usage
		exit 2
	fi

	# Set some global defaults
	RSTAR_TOOLS=()
	RSTAR_BACKEND=moar
	RSTAR_PREFIX="$BASEDIR"

	# Source the file defining the action.
	debug "Sourcing $action_path"
	source "$action_path"

	# Ensure all required tools are available
	depcheck_bin || exit 3
	depcheck_perl || exit 3

	# TODO: Figure out which OS/distro we're on, to allow for working
	# around edge-cases. Probably expose this info as RSTAR_PLATFORM, in an
	# associative array.

	# Maintain our own tempdir
	export TMPDIR="$BASEDIR/tmp"
	mkdir -p -- "$TMPDIR"
	debug "\$TMPDIR set to $TMPDIR"

	# Actually perform the action
	debug "Running action"
	action "$@"
	local action_exit=$?

	# Clean up if necessary
	if [[ -z $RSTAR_MESSY ]]
	then
		debug "Cleaning up tempfiles at $TMPDIR"
		rm -rf -- "$TMPDIR"
	fi

	# Use the action's exit code
	exit $action_exit
}

usage() {
	cat <<EOF
Usage: rstar <action> [options] [arguments]

rstar is the entry point for all utilities to deal with Rakudo Star.

Actions:
	clean    Clean up the repository.
	dist     Create a distributable tarball of this repository.
	fetch    Fetch all required sources.
	install  Install Raku on this system.
	test     Run tests on Raku and the bundled ecosystem modules.
EOF
}

# This function checks for the availability of (binary) utilities in the user's
# $PATH environment variable.
depcheck_bin() {
	local missing=()

	for tool in "${RSTAR_DEPS_BIN[@]}"
	do
		command -v "$tool" > /dev/null && continue

		missing+=("$tool")
	done

	if [[ $missing ]]
	then
		alert "Some required tools are missing:"

		for tool in "${missing[@]}"
		do
			# TODO: Include current distro's package name
			# containing the tool
			alert "  $tool"
		done

		return 1
	fi
}

# This function checks for the availability of all Perl modules required.
depcheck_perl() {
	local missing=()

	for module in "${RSTAR_DEPS_PERL[@]}"
	do
		perl -M"$module" -e 0 2> /dev/null && continue

		missing+=("$tool")
	done

	if [[ $missing ]]
	then
		alert "Some required Perl modules are missing:"

		for modules in "${missing[@]}"
		do
			alert "  $module"
		done

		return 1
	fi
}

main "$@"
