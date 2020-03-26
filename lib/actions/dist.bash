#!/usr/bin/env bash

RSTAR_DEPS_BIN+=(
	git
	gpg
	md5sum
	sha1sum
	sha224sum
	sha256sum
	sha384sum
	sha512sum
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
	for src in src/*
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

	chgdir "$(dirname "$tarball")"

	info "Generating checksums for $tarball"
	for sum in md5 sha{1,224,256,384,512}
	do
		dist_checksum "$sum" "$tarball" >> "$tarball.checksums.txt"
	done

	info "Generating a PGP signature for $tarball"
	gpg --armor --detach-sign --output "$tarball.asc" "$tarball"

	info "Distribution tarball available at $tarball"
}

dist_include() {
	mkdir -p -- "$(dirname "${WORKDIR}$1")"
	cp -r -- "${BASEDIR}$1" "${WORKDIR}$1"
}

dist_checksum() {
	printf "%-6s  %s\n" \
		"$1" \
		"$("dist_checksum_$1" "$2")"
}

dist_checksum_md5() {
	md5sum "$1" | awk '{print $1}'
}

dist_checksum_sha1() {
	sha1sum "$1" | awk '{print $1}'
}

dist_checksum_sha224() {
	sha224sum "$1" | awk '{print $1}'
}

dist_checksum_sha256() {
	sha256sum "$1" | awk '{print $1}'
}

dist_checksum_sha384() {
	sha384sum "$1" | awk '{print $1}'
}

dist_checksum_sha512() {
	sha512sum "$1" | awk '{print $1}'
}
