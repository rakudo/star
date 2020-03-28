#!/usr/bin/env bash

action() {
	local OPTIND
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

	# Run each test target
	for target in "$@"
	do
		if [[ $(type -t "action_test_$target") != "function" ]]
		then
			crit "Test target '$target' is invalid"
			continue
		fi

		"action_test_$target"
	done
}

action_test_modules() {
	local modules
	local prove

	modules="$(tmpfile)"
	prove="$RSTAR_PREFIX/share/perl6/vendor/bin/prove6"

	awk '/^[^#]/ {print $1}' "$BASEDIR/etc/modules.txt" > "$modules"

	while read -r module
	do
		chgdir "$BASEDIR/src/rakudo-star-modules/$module"
		"$prove" -v .
	done < "$modules"
}

action_test_spectest() {
	local destination
	local source

	destination="$(tmpdir)"
	source="$BASEDIR/src/rakudo-$(config_etc_kv "dist_rakudo.txt" "version")"

	notice "Using $destination as working directory"

	# Grab the source files
	cp -R -- "$source/." "$destination"
	chgdir "$destination"

	# Run the spectest
	perl Configure.pl --prefix="$RSTAR_PREFIX"
	make spectest
}
