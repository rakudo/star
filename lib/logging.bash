#!/usr/bin/env bash

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

if [[ "$(awk '$1 == "'"$TERM"'" {print 1}' "$BASEDIR/etc/color-terminals.txt")" ]]
then
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
else
	debug() {
		[[ -z $RSTAR_DEBUG ]] && return
		log -- "[DEBUG] $*"
	}

	info() {
		log -- "[INFO]  $*"
	}

	notice() {
		log -- "[NOTIC] $*"
	}

	warn() {
		log -- "[WARN]  $*"
	}

	crit() {
		log -- "[CRIT]  $*"
	}

	alert() {
		log -- "[ALERT] $*"
	}

	emerg() {
		log -- "[EMERG] $*"
	}
fi
