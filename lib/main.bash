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

	# Declare some global variables
	declare -a RSTAR_TOOLS
	declare RSTAR_BACKEND=moar
	declare RSTAR_PREFIX="$BASEDIR"
	declare -A RSTAR_PLATFORM

	# Figure out system details
	debug "Discovering system information"
	discover_system

	# Source the file defining the action.
	debug "Sourcing $action_path"
	source "$action_path"

	# Ensure all required tools are available
	depcheck_bin || exit 3
	depcheck_perl || exit 3

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
Usage:
	rstar -h
	rstar clean
	rstar dist [version]
	rstar fetch
	rstar install [-b backend] [-p prefix]
	rstar sysinfo
	rstar test

rstar is the entry point for all utilities to deal with Rakudo Star.

Actions:
	clean    Clean up the repository.
	dist     Create a distributable tarball of this repository. If no
	         version identifier is specified, it will use the current year
	         and month in "yyyy.mm" notation.
	fetch    Fetch all required sources.
	install  Install Raku on this system. By default, MoarVM will be used
	         as the only backend. The Rakudo Star directory will be used as
	         prefix.
	sysinfo  Show information about your system. Useful for debugging.
	test     Run tests on Raku and the bundled ecosystem modules.
EOF
}

# This function checks for the availability of (binary) utilities in the user's
# $PATH environment variable.
depcheck_bin() {
	local missing=()

	for tool in "${RSTAR_DEPS_BIN[@]}"
	do
		debug "Checking for availability of $tool"
		command -v "$tool" > /dev/null && continue

		missing+=("$tool")
	done

	if [[ ${missing[*]} ]]
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
		debug "Checking for availability of $module"
		perl -M"$module" -e 0 2> /dev/null && continue

		missing+=("$module")
	done

	if [[ ${missing[*]} ]]
	then
		alert "Some required Perl modules are missing:"

		for module in "${missing[@]}"
		do
			alert "  $module"
		done

		return 1
	fi
}

# Discover information about the system. If any bugs are reported and you want
# more information about the system the user is running on, additional checks
# can be added here, and the user will simply have to include the output of the
# sysinfo command in their message to you.
discover_system() {
	RSTAR_PLATFORM["os"]="$(discover_system_os)"

	if [[ ${RSTAR_PLATFORM[os]} == "gnu_linux" ]]
	then
		RSTAR_PLATFORM["distro"]="$(discover_system_distro)"
		RSTAR_PLATFORM["kernel"]="$(discover_system_kernel)"
		RSTAR_PLATFORM["kernel_version"]="$(discover_system_kernel_version)"
	fi
}

discover_system_distro() {
	awk -F= '$1 == "NAME" {print tolower($2);q}' /etc/*release
}

discover_system_kernel() {
	printf "%s" "$(uname -s | awk '{print tolower($0)}')"
}

discover_system_kernel_version() {
	printf "%s" "$(uname -r | awk '{print tolower($0)}')"
}

discover_system_os() {
	if command -v uname > /dev/null
	then
		printf "%s" "$(uname -o | awk '{print tolower($0)}' | sed 's_[/+]_\__g')"
		return
	fi
}

main "$@"
