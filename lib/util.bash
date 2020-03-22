#!/usr/bin/env bash

# Log a message as error, and exit the program. This is intended for serious
# issues that prevent the script from running correctly. The exit code can be
# specified with -i, or will default to 1.
die() {
	local OPTIND
	local code

	while getopts ":i:" opt
	do
		case "$opt" in
			i) code=$OPTARG ;;
		esac
	done

	shift $(( OPTIND -1 ))

	alert "$@"
	exit ${code:-1}
}

# Fetch a file from an URL. Using this function introduces a dependency on curl.
fetch() {
	local OPTIND
	local buffer

	while getopts ":o:" opt
	do
		case "$opt" in
			o) buffer=$OPTARG ;;
		esac
	done

	shift $(( OPTIND -1 ))

	[[ -z $buffer ]] && buffer="$(tempfile)"

	notice "Downloading $1 to $buffer"

	# TODO: Switch to the most appropriate downloading tool, depending on
	# what is available.

	curl -Ls "$1" > "$buffer"
	local exit_code=$?

	printf "%s" "$buffer"

	return $exit_code
}

# Read a particular value from a key/value configuration file. Using this
# function introduces a dependency on awk.
config_etc_kv() {
	local file="$BASEDIR/etc/$1"
	shift

	if [[ ! -f $file ]]
	then
		crit "Tried to read value for $1 from $file, but $file does not exist"
		return
	fi

	debug "Reading value for $1 from $file"

	awk -F= '$1 == "'"$1"'" { print $NF }' "$file"
}

# Create a temporary directory. Similar to tempfile, but you'll get a directory
# instead.
tempdir() {
	local dir="$(mktemp -d)"

	# Ensure the file was created succesfully
	if [[ ! -d "$dir" ]]
	then
		die "Failed to create a temporary directory at $dir"
	fi

	debug "Temporary file created at $dir"

	printf "$dir"
}

# Create a temporary file. In usage, this is no different from mktemp itself,
# however, it will apply additional checks to ensure everything is going
# correctly, and the files will be cleaned up automatically at the end.
tempfile() {
	local OPTIND
	local extension="tmp"

	while getopts ":x:" opt
	do
		case "$opt" in
			x) extension=$OPTARG ;;
		esac
	done

	shift $(( OPTIND -1 ))

	local file="$(mktemp --suffix ".$extension")"

	# Ensure the file was created succesfully
	if [[ ! -f "$file" ]]
	then
		die "Failed to create a temporary file at $file"
	fi

	debug "Temporary file created at $file"

	printf "$file"
}

export -f config_etc_kv
export -f die
export -f fetch
export -f tempdir
export -f tempfile
