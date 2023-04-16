#!/usr/bin/env bash

RSTAR_DEPS_BIN+=(
	git
	gpg
	gpg2
	md5sum
	sha1sum
	sha224sum
	sha256sum
	sha384sum
	sha512sum
	tar
	curl
)

action() {
	local LC_ALL
	local SOURCE_DATE_EPOCH
	local RKD_LATEST
	local basename
	local tarball
	local VERSION

	# Prepare environment for a reproducible tarball
	LC_ALL=C.UTF-8
	SOURCE_DATE_EPOCH="$(git log -1 --pretty=format:%at)"

	# Set a VERSION if none was specified explicitly
	## defaults to the latest GitHub RAKUDO release, as long as "latest" matches something like 2020.08 or 2020.08.1
	## takes YEAR.month else, so something like 2020.08
	if [[ "$(curl -v --stderr - https://github.com/rakudo/rakudo/releases/latest | egrep -i 'location: ')" =~ /tag/([0-9]+.[0-9]+)(.[0-9]+) ]]
	then
		RKD_LATEST="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
	else
		# RKD_LATEST="$(datetime %Y.%m)"
        RKD_LATEST="$(config_etc_kv "fetch_core.txt" "rakudo_version")"
	fi
	VERSION="${1:-$RKD_LATEST}"
	WORKDIR="$BASEDIR/tmp/rakudo-star-$VERSION"

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

	# Set the SOURCE_DATE_EPOCH for the installation phase
	printf "%d\n" "$SOURCE_DATE_EPOCH" > "$WORKDIR/etc/epoch.txt"

	# Add a MANIFEST.txt
	chgdir "$WORKDIR"
	touch MANIFEST.txt
	find . -type f | sed 's|^./||' | sort > MANIFEST.txt

	# Tar it all up into a distribution tarball
	info "Creating tarball out of $WORKDIR"

	basename="rakudo-star-$VERSION"
	tarball_name="$basename.tar.gz"
	tarball="$BASEDIR/dist/$tarball_name"

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

	info "Generating checksums for $tarball_name"
	md5sum --tag $tarball_name >> $tarball_name.checksums.txt.unsigned
	sha1sum --tag $tarball_name >> $tarball_name.checksums.txt.unsigned
	sha224sum --tag $tarball_name >> $tarball_name.checksums.txt.unsigned
	sha256sum --tag $tarball_name >> $tarball_name.checksums.txt.unsigned
	sha384sum --tag $tarball_name >> $tarball_name.checksums.txt.unsigned
	sha512sum --tag $tarball_name >> $tarball_name.checksums.txt.unsigned
	gpg2 --batch --clearsign -u $GPG_FINGERPRINT --output $tarball_name.checksums.txt -- $tarball_name.checksums.txt.unsigned
	rm $tarball_name.checksums.txt.unsigned
	
	info "Generating a PGP signature for $tarball_name"
	gpg2 --batch --detach-sign --armor -u $GPG_FINGERPRINT --output "$tarball_name.asc" -- $tarball_name

	info "Distribution tarball available at $tarball"
}

dist_include() {
	if [[ ! -e "${BASEDIR}$1" ]]
	then
		crit "\"${BASEDIR}$1\" expected but not found, you may need to run \"rstar fetch\" first"
		exit 7
	fi
	
	mkdir -p -- "$(dirname "${WORKDIR}$1")"
	cp -r -- "${BASEDIR}$1" "${WORKDIR}$1"
}

