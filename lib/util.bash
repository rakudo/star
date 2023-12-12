#!/usr/bin/env bash

# Change the working directory. In usage, this is the same as using cd,
# however,  it will make additional checks to ensure everything is going fine.
chgdir() {
	debug "Changing workdir to $1"
	cd -- "$1" || die "Failed to change directory to $1"
}

# Read a particular value from a key/value configuration file. Using this
# function introduces a dependency on awk.
config_etc_kv() {
	local value

	local file="$BASEDIR/etc/$1"
	shift

	if [[ ! -f $file ]]
	then
		crit "Tried to read value for $1 from $file, but $file does not exist"
		return
	fi

	debug "Reading value for $1 from $file"

	value="$(awk -F= '$1 == "'"$1"'" { print $NF }' "$file")"

	if [[ -z $value ]]
	then
		crit "Empty value for $1 from $file?"
	fi

	printf "%s" "$value"
}

# Create a datetime stamp. This is a wrapper around the date utility, ensuring
# that the date being formatted is always in UTC and respect SOURCE_DATE_EPOCH,
# if it is set.
datetime() {
	local date_opts

	# Apply SOURCE_DATE_EPOCH as the date to base off of.
	if [[ $SOURCE_DATE_EPOCH ]]
	then
		date_opts+=("-d@$SOURCE_DATE_EPOCH")
		date_opts+=("-u")
	fi

	date "${date_opts[@]}" +"${1:-%FT%T}"
}

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
			*) alert "Unused argument specified: $opt" ;;
		esac
	done

	shift $(( OPTIND -1 ))

	alert "$@"
	exit "${code:-1}"
}

# Fetch a file from an URL. Using this function introduces a dependency on curl.
fetch_http() {
	local OPTIND
	local buffer

	while getopts ":o:" opt
	do
		case "$opt" in
			o) buffer=$OPTARG ;;
			*) alert "Unused argument specified: $opt" ;;
		esac
	done

	shift $(( OPTIND -1 ))

	[[ -z $buffer ]] && buffer="$(tmpfile)"

	notice "Downloading $1 to $buffer"

	for util in curl wget
	do
		command -v "$util" > /dev/null || continue
		"fetch_http_$util" "$1" "$buffer" || continue
		local exit_code=$?

		printf "%s" "$buffer"
		return $exit_code
	done

	die "Unable to download file over HTTP!"
}

fetch_http_curl() {
	curl -Ls "$1" > "$2"
}

fetch_http_wget() {
	wget --quiet --output-document "$2" "$1"
}

# Check if the first argument given appears in the list of all following
# arguments.
in_args() {
	local needle="$1"
	shift

	for arg in "$@"
	do
		[[ $needle == "$arg" ]] && return 0
	done

	return 1
}

# Join a list of arguments into a single string. By default, this will join
# using a ",", but you can set a different character using -c. Note that this
# only joins with a single character, not a string of characters.
join_args() {
	local OPTIND
	local IFS=","

	while getopts ":c:" opt
	do
		case "$opt" in
			c) IFS="$OPTARG" ;;
			*) warn "Unused opt specified: $opt" ;;
		esac
	done

	shift $(( OPTIND - 1))

	printf "%s" "$*"
}

# Pretty print a duration between a starting point (in seconds) and an end
# point (in seconds). If no end point is given, the current time will be used.
# A good way to get a current timestamp in seconds is through date's "%s"
# format.
pp_duration() {
	local start=$1
	local end=$2
	local diff

	if [[ -z "$end" ]]
	then
		end="$(date +%s)"
	fi

	diff=$((end - start))

	printf "%dh %02dm %02ds\n" \
		"$((diff / 60 / 60))" \
		"$((diff / 60 % 60))" \
		"$((diff % 60))"
}

# Create a temporary directory. Similar to tempfile, but you'll get a directory
# instead.
tmpdir() {
	local dir

	dir="$(mktemp -d)"

	# Ensure the file was created successfully
	if [[ ! -d "$dir" ]]
	then
		die "Failed to create a temporary directory at $dir"
	fi

	debug "Temporary file created at $dir"

	printf "%s" "$dir"
}

# Create a temporary file. In usage, this is no different from mktemp itself,
# however, it will apply additional checks to ensure everything is going
# correctly, and the files will be cleaned up automatically at the end.
tmpfile() {
	local file

	file="$(mktemp)"

	# Ensure the file was created successfully
	if [[ ! -f "$file" ]]
	then
		die "Failed to create a temporary file at $file"
	fi

	debug "Temporary file created at $file"

	printf "%s" "$file"
}
