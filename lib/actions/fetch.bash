#!/usr/bin/env bash

RSTAR_DEPS_BIN+=(
	awk
	curl
	git
	tar
)

action() {
 
	local RKD_VERSION_GH_LATEST
	
	# If -l is set, get the "GitHub latest" releases of every $component below
	while getopts ":l" opt
	do
		case "$opt" in
			l) RKD_VERSION_GH_LATEST=1 ;;
			*) emerg "Invalid option specified: $opt" ;;
		esac
	done

	shift "$(( OPTIND - 1 ))"
	
	# Ensure the directory to download to exists
	mkdir -p "$BASEDIR/src"

	# Download all core components
	for component in moarvm nqp rakudo
	do
		download_core "$component"
	done

	mkdir -p "$BASEDIR/src/rakudo-star-modules"

	# Download all modules available over http
	list_modules "http" | while read -r name _ url prefix
	do
		download_module_http "$name" "$url" "$prefix"
	done

	# Download all modules available over git
	list_modules "git" | while read -r name _ url ref
	do
		download_module_git "$name" "$url" "$ref"
	done
}

download_core() {
	local VERSION
	local source
	local destination

	if [[ $RKD_VERSION_GH_LATEST ]]
	then
		TMP_VERSION="$(config_etc_kv "fetch_core.txt" "${1}_url" | sed -E "s|(https://github.com/.+/.+/releases)/download/.+|\1/latest|")"
		
		if [[ "$(curl -v --stderr - $TMP_VERSION | egrep -i 'location: ')" =~ /tag/([0-9]+.[0-9]+)(.[0-9]+) ]]
		then
			VERSION="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
		else
			warn "\"-l\" option set but \"$TMP_VERSION\" doesn't match an expected ${1} GitHub release tag"
			warn "falling back to the version given in \"fetch_core.txt\""
			VERSION="$(config_etc_kv "fetch_core.txt" "${1}_version")"
		fi
	else
		VERSION="$(config_etc_kv "fetch_core.txt" "${1}_version")"
	fi
	
	source="$(config_etc_kv "fetch_core.txt" "${1}_url" | sed "s/%s/$VERSION/g")"
	destination="$BASEDIR/src/$1-$VERSION"

	if [[ -d $destination ]]
	then
		warn "Skipping sources for $1, destination already exists: $destination"
		return 0
	fi

	mkdir -p -- "$destination"

	tarball="$(fetch_http "$source")" \
		&& tar xzf "$tarball" -C "$destination" \
		&& return

	crit "Failed to download $destination"
	rm -fr -- "$destination"
}

download_module_git() {
	local name=$1
	local url=$2
	local ref=$3
	local destination="$BASEDIR/src/rakudo-star-modules/$name"

	if [[ -d "$destination" ]]
	then
		warn "Skipping sources for $name, destination already exists: $destination"
		return 0
	fi

	notice "Cloning $url@$ref to $destination"

	mkdir -p -- "$destination"
	chgdir "$destination"

	git -c init.defaultBranch=main init > /dev/null
	git remote add origin "$url" 2> /dev/null
	git fetch --quiet origin -a 2> /dev/null

	# Try to use the ref (branch or tag)
	if ! git reset --quiet --hard "origin/$ref" > /dev/null 2>&1
	then
		# Or the commit hash
		git reset --quiet --hard "$(git log -1 --format=format:"%H" "$ref")"
	fi

	rm -fr -- .git
}

download_module_http() {
	local name=$1
	local url=$2
	local prefix=$3
	local destination="$BASEDIR/src/rakudo-star-modules/$name"
	local tarball
	local extracted

	if [[ -d "$destination" ]]
	then
		warn "Skipping sources for $name, destination already exists: $destination"
		return 0
	fi

	tarball="$(fetch_http "$url")"
	extracted="$(tmpdir)"

	notice "Extracting $tarball into $extracted"
	tar xzf "$tarball" -C "$extracted"

	notice "Moving $extracted/$prefix to $destination"
	mv -- "$extracted/$prefix" "$destination"
}

list_modules() {
	awk '/^[^#]/ && $2 == "'"$1"'" { print }' "$BASEDIR/etc/modules.txt"
}
