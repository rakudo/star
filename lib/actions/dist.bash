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
	local LC_ALL
	local SOURCE_DATE_EPOCH
	local basename
	local tarball
	local version

	# Prepare environment for a reproducible tarball
	LC_ALL=C.UTF-8
	SOURCE_DATE_EPOCH="$(git log -1 --pretty=format:%at)"

	# Set a version if none was specified explicitly
	version="${1:-$(datetime %Y.%m)}"
	WORKDIR="$BASEDIR/tmp/rakudo-star-$version"

	debug "SOURCE_DATE_EPOCH set to $SOURCE_DATE_EPOCH"

	export LC_ALL
	export SOURCE_DATE_EPOCH

	info "Creating distribution contents at $WORKDIR"

	chgdir "$BASEDIR"

	# Include files from this project
	for file in $(git ls-files)
	do
		dist_include "/$file"
	done

	# Include the component sources
	dist_include "/src"

	# Add a MANIFEST.txt
	chgdir "$WORKDIR"
	touch MANIFEST.txt
	find . -type f | sed 's|^./||' | sort > MANIFEST.txt

	# Tar it all up into a distribution tarball
	info "Creating tarball out of $WORKDIR"

	basename="rakudo-star-$version"
	tarball="$BASEDIR/dist/$basename.tar.gz"

	mkdir -p -- "$(dirname "$tarball")"
	chgdir "$BASEDIR/tmp"

	awk '{ print "'"$basename"'/"$0 }' "$WORKDIR/MANIFEST.txt" \
		| tar -c -T - \
			--mtime @"$SOURCE_DATE_EPOCH" \
			--mode=go=rX,u+rw,a-s \
			--format=gnu \
			--numeric-owner --owner=0 --group=0 \
		| gzip -9cn \
		> "$tarball"
	touch -d"$(datetime)" "$tarball"

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
