#!/usr/bin/env bash

RSTAR_DEPS_BIN+=(
	git
	tar
)

action() {
	local version="${1:-$(date +%Y.%m)}"
	WORKDIR="$BASEDIR/tmp/rakudo-star-$version"

	info "Creating distribution contents at $WORKDIR"

	chgdir "$BASEDIR"

	# Include files from this project
	for file in $(git ls-files)
	do
		dist_include "/$file"
	done

	# Include the sources of all components
	for src in dist/src/*
	do
		dist_include "/$src"
	done

	# Add a MANIFEST.txt
	chgdir "$WORKDIR"
	find . > MANIFEST.txt

	# Tar it all up into a distribution tarball
	info "Creating tarball out of $WORKDIR"

	local tarball="$BASEDIR/dist/rakudo-star-$version.tar.gz"

	mkdir -p -- "$(dirname "$tarball")"
	chgdir "$BASEDIR/tmp"

	tar czf "$tarball" "rakudo-star-$version"

	# TODO: Create checksums
	# TODO: Create PGP signature

	info "Distribution tarball available at $tarball"
}

dist_include() {
	mkdir -p -- "$(dirname "${WORKDIR}$1")"
	cp -r -- "${BASEDIR}$1" "${WORKDIR}$1"
}
