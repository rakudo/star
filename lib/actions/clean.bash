#!/usr/bin/env bash

action() {
	local OPTIND
	local clean_source

	while getopts ":s" opt
	do
		case "$opt" in
			s) clean_src=1 ;;
			*) emerg "Invalid option specified: $opt" ;;
		esac
	done

	shift $(( OPTIND - 1 ))

	shopt -s extglob

	rm -fr -- "!($BASEDIR/bin/rstar)"
	rm -fr -- "$BASEDIR/dist"
	rm -fr -- "$BASEDIR/include"
	rm -fr -- "$BASEDIR/lib/libmoar.so"
	rm -fr -- "$BASEDIR/share"

	# Cleaning the sources is not desired for end-users, but convenient for
	# maintainers. As such, this one is put behind an opt.
	if [[ $clean_src ]]
	then
		rm -fr -- "$BASEDIR/src"
		rm -f -- "$BASEDIR/etc/epoch.txt"
	fi
}
