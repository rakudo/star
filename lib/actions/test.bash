#!/usr/bin/env bash

action() {
	local OPTIND
	local failures=0
	local init
	local raku

	while getopts ":p:" opt
	do
		case "$opt" in
			p) RSTAR_PREFIX=$OPTARG ;;
			*) emerg "Invalid option specified: $opt" ;;
		esac
	done

	shift $(( OPTIND - 1 ))

	raku="$RSTAR_PREFIX/bin/raku"

	# Ensure raku is available
	if [[ ! -f $raku ]]
	then
		emerg "No Raku executable available at $raku."
		emerg "Make sure you ran the install command."
		emerg "Also, if you installed with -p, you must specify it for test as well"
	fi

	# If no specific targets are specified, set all targets
	if (( $# < 1 ))
	then
		set -- spectest modules
	fi

	# Take note of the current time, so we can show how long it took later
	# on
	init="$(date +%s)"

	# Run each test target
	for target in "$@"
	do
		if [[ $(type -t "action_test_$target") != "function" ]]
		then
			crit "Test target '$target' is invalid"
			continue
		fi

		"action_test_$target" && continue

		failures=$(( failures + 1 ))
	done

	info "Testing took $(pp_duration "$init")"

	if (( failures > 0 ))
	then
		return 4
	fi
}

action_test_modules() {
	local modules
	local failures

	modules="$(tmpfile)"

	# Manually set a minimal PATH
	PATH="/bin:/usr/bin:/usr/local/bin"

	# Add the Rakudo bin directories from RSTAR_PREFIX
	PATH+=":$(readlink -f "$RSTAR_PREFIX/bin")"
	PATH+=":$(readlink -f "$RSTAR_PREFIX/share/perl6/site/bin")"
	PATH+=":$(readlink -f "$RSTAR_PREFIX/share/perl6/vendor/bin")"
	PATH+=":$(readlink -f "$RSTAR_PREFIX/share/perl6/core/bin")"

	# And export this version to the tests
	export PATH

	debug "PATH set to $PATH"

	awk '/^[^#]/ {print $1}' "$BASEDIR/etc/modules.txt" > "$modules"

	# Go through each module and run the tests
	while read -r module
	do
		chgdir "$BASEDIR/src/rakudo-star-modules/$module"
		prove6 -v . && continue

		failures+=("$module")
	done < "$modules"

	# Return cleanly if no failures occurred
	if [[ -z ${failures[*]} ]]
	then
		return 0
	fi

	# Or inform the user of the failing modules
	emerg "One or more modules failed their tests:"

	for module in "${failures[@]}"
	do
		emerg "  $module"
	done

	return 1
}

action_test_spectest() {
	local destination
	local source

	destination="$(tmpdir)"
	source="$BASEDIR/src/rakudo-$(config_etc_kv "fetch_core.txt" "rakudo_version")"

	notice "Using $destination as working directory"

	# Grab the source files
	cp -R -- "$source/." "$destination"
	chgdir "$destination"

	# Run the spectest
	perl Configure.pl --prefix="$RSTAR_PREFIX"
	make spectest
}
