#!/usr/bin/env bash

# TODO: Only use colors on terminals that are known to work well with them.

# The base function to output logging information. This should *not* be used
# directly, but the helper functions can be used safely.
log() {
	local OPTIND
	local color

	while getopts ":c:" opt
	do
		case "$opt" in
			c) color=$OPTARG ;;
			*) alert "Unused argument specified: $opt" ;;
		esac
	done

	shift $(( OPTIND - 1 ))

	printf "${color}[%s] %s\e[0m\n" "$(date +%FT%T)" "$*" >&2
}

debug() {
	[[ -z $RSTAR_DEBUG ]] && return
	log -c "\e[1;30m" -- "$*"
}

info() {
	log -- "$*"
}

notice() {
	log -c "\e[0;34m" -- "$*"
}

warn() {
	log -c "\e[0;33m" -- "$*"
}

crit() {
	log -c "\e[0;31m" -- "$*"
}

alert() {
	log -c "\e[1;31m" -- "$*"
}

emerg() {
	log -c "\e[1;4;31m" -- "$*"
}
