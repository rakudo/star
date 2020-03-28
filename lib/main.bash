#!/usr/bin/env bash

# shellcheck source=lib/util.bash
source "$(dirname "${BASH_SOURCE[0]}")/util.bash"

# shellcheck source=lib/logging.bash
source "$(dirname "${BASH_SOURCE[0]}")/logging.bash"

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

	# Export RSTAR_ variables
	export RSTAR_TOOLS
	export RSTAR_BACKEND
	export RSTAR_PREFIX
	export RSTAR_PLATFORM

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
	local bindep_db

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
			alert "  $tool"
		done

		# Resolve the basename for the bindep file
		bindep_db="bindeps.d/${RSTAR_PLATFORM[key]}.txt"

		debug "bindep_db resolved to $bindep_db"

		# If there's a bindep file, use it to resolve the missing utils
		# into a list of package names.
		if [[ -f "etc/$bindep_db" ]]
		then
			local packages
			local pacman_cmd
			local package

			debug "bindep_db found"

			# Create a list of packages that needs to be installed
			for tool in "${missing[@]}"
			do
				package="$(config_etc_kv "$bindep_db" "$tool")"

				# Don't add duplicates
				in_args "$package" "${packages[@]}" && continue

				packages+=("$package")

				unset package
			done

			# Figure out which package manager command install on
			# the current platform.
			pacman_cmd="$(config_etc_kv pacmans.txt "${RSTAR_PLATFORM[key]}") "

			# Tell the user of the command to install missing
			# dependencies
			info "The missing tools can be installed using your system package manager:"
			info "$pacman_cmd$(join_args -c " " "${packages[@]}")"
		fi

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

		info "The missing Perl modules can be installed using this command:"
		info "$(config_etc_kv perlmans.txt "${RSTAR_PLATFORM[key]}") $(join_args -c " " "${missing[@]}")"

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

	RSTAR_PLATFORM[key]="$(discover_system_key)"
}

discover_system_distro() {
	if [[ -f /etc/os-release ]]
	then
		printf "%s" "$(source /etc/os-release && printf "%s" "$NAME" | awk '{print tolower($0)}')"
		return
	fi

	awk -F= '$1 == "NAME" {print tolower($2);q}' /etc/*release
}

discover_system_kernel() {
	printf "%s" "$(uname -s | awk '{print tolower($0)}')"
}

discover_system_kernel_version() {
	printf "%s" "$(uname -r | awk '{print tolower($0)}')"
}

discover_system_key() {
	key+="${RSTAR_PLATFORM[os]}"

	if [[ ${RSTAR_PLATFORM[distro]} ]]
	then
		key+="-${RSTAR_PLATFORM[distro]}"
	fi

	printf "%s" "$key"
}

discover_system_os() {
	if command -v uname > /dev/null
	then
		printf "%s" "$(uname -o | awk '{print tolower($0)}' | sed 's_[/+]_\__g')"
		return
	fi
}

main "$@"
