#!/usr/bin/env bash

RSTAR_DEPS_BIN=(
	awk
	curl
	git
	tar
)

action() {
	# Ensure the directory to download to exists
	mkdir -p "$BASEDIR/dist/src/core"

	# Download all core components
	for component in moarvm nqp rakudo
	do
		download_core "$component"
	done

	mkdir -p "$BASEDIR/dist/src/modules"

	# Download all modules available over http
	list_modules "http" | while read -r name proto url prefix
	do
		download_module_http "$name" "$url" "$prefix"
	done

	# Download all modules available over git
	list_modules "git" | while read -r name proto url ref
	do
		download_module_git "$name" "$url" "$ref"
	done
}

download_core() {
	local version="$(config_etc_kv "dist_$1.txt" "version")"
	local source="$(echo "$(config_etc_kv "dist_$1.txt" "url")" | sed "s/%s/$version/g")"
	local destination="$BASEDIR/dist/src/core/$1-$version"

	if [[ -d $destination ]]
	then
		warn "Skipping sources for $1, destination already exists: $destination"
		return 0
	fi

	mkdir -p -- "$destination"

	tarball="$(fetch "$source")"
	tar xzf "$tarball" -C "$destination" --strip-components=1 && return

	crit "Failed to download $destination"
	rm -f -- "$destination"
}

download_module_git() {
	local name=$1
	local url=$2
	local ref=$3
	local destination="$BASEDIR/dist/src/modules/$name"

	if [[ -d "$destination" ]]
	then
		warn "Skipping sources for $name, destination already exists: $destination"
		return 0
	fi

	notice "Cloning $url@$ref to $destination"
	git clone -b "$ref" "$url" --depth=1 --single-branch "$destination" \
		> /dev/null 2>&1

	rm -fr -- "$destination/.git"
}

download_module_http() {
	local name=$1
	local url=$2
	local prefix=$3
	local destination="$BASEDIR/dist/src/modules/$name"

	if [[ -d "$destination" ]]
	then
		warn "Skipping sources for $name, destination already exists: $destination"
		return 0
	fi

	local tarball="$(fetch "$url")"
	local extracted="$(tempdir)"

	notice "Extracting $tarball into $extracted"
	tar xzf "$tarball" -C "$extracted"

	notice "Moving $extracted/$prefix to $destination"
	mv -- "$extracted/$prefix" "$destination"
}

list_modules() {
	awk '/^[^#]/ && $2 == "'"$1"'" { print }' "$BASEDIR/etc/modules.txt"
}
