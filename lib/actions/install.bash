#!/usr/bin/bash

RSTAR_DEPS_BIN+=(
	awk
	gcc
	make
	perl
)

RSTAR_DEPS_PERL+=(
	ExtUtils::Command
	Pod::Usage
)

action() {
	local LC_ALL
	local OPTIND
	local duration
	local init
	local prefix_absolute

	while getopts ":b:p:" opt
	do
		case "$opt" in
			b) RSTAR_BACKEND=$OPTARG ;;
			p) RSTAR_PREFIX=$OPTARG ;;
			*) emerg "Invalid option specified: $opt" ;;
		esac
	done

	shift $(( OPTIND - 1 ))

	# Prepare environment for a reproducible install
	LC_ALL=C.UTF-8

	# Distribution tarballs come with an epoch set, use it if you find it.
	if [[ -f "$BASEDIR/etc/epoch.txt" ]]
	then
		SOURCE_DATE_EPOCH="$(head -n1 "$BASEDIR/etc/epoch.txt")"
		debug "SOURCE_DATE_EPOCH set to $SOURCE_DATE_EPOCH (epoch.txt)"
	fi

	export LC_ALL
	export SOURCE_DATE_EPOCH

	# If no specific targets are specified, set all targets
	if (( $# < 1 ))
	then
		set -- core modules
	fi

	# Take note of the current time, so we can show how long it took later
	# on
	init="$(date +%s)"

	# Use an absolute path when reporting about the installation path
	prefix_absolute="$(CDPATH="" cd -- "$RSTAR_PREFIX" && pwd -P)"
	info "Installing Raku in $prefix_absolute"

	# Create the installation directory
	mkdir -p -- "$RSTAR_PREFIX"

	# Run each installation target
	for target in "$@"
	do
		if [[ $(type -t "action_install_$target") != "function" ]]
		then
			crit "Installation target '$target' is invalid"
			continue
		fi

		"action_install_$target"
	done

	duration="$(pp_duration "$init")"

	# Friendly message
	info "Rakudo Star has been installed into $prefix_absolute!"
	info "The installation took $duration."
	info ""
	info "You may need to add the following paths to your \$PATH:"
	info "  $prefix_absolute/bin"
	info "  $prefix_absolute/share/perl6/site/bin"
	info "  $prefix_absolute/share/perl6/vendor/bin"
	info "  $prefix_absolute/share/perl6/core/bin"
}

action_install_core() {
	# Compile all core components
	for component in moarvm nqp rakudo
	do
		VERSION="$(config_etc_kv "fetch_core.txt" "${component}_version")" \
			build_"$component" \
				--prefix="$RSTAR_PREFIX" \
				--relocatable \
			&& continue

		die "Build failed!"
	done
}

action_install_modules() {
	local failed_modules
	local modules

	modules="$(tmpfile)"

	awk '/^[^#]/ {print $1}' "$BASEDIR/etc/modules.txt" > "$modules"

	while read -r module
	do
		info "Installing $module"

		install_raku_module "$BASEDIR/src/rakudo-star-modules/$module" \
			&& continue

		failed_modules+=("$module")
	done < "$modules"

	# Show a list of all modules that failed to install
	if [[ ${failed_modules[*]} ]]
	then
		crit "The following modules failed to install:"

		for module in "${failed_modules[@]}"
		do
			crit "  $module"
		done
	fi
}

build_moarvm() {
	info "Starting build on MoarVM"

	build_prepare "$BASEDIR/src/moarvm-$VERSION" || return
	perl Configure.pl \
		"$@" \
		&& make \
		&& make install \
		|| return
}

build_nqp() {
	info "Starting build on NQP"

	build_prepare "$BASEDIR/src/nqp-$VERSION" || return
	perl Configure.pl \
		--backend="$RSTAR_BACKEND" \
		"$@" \
		&& make \
		&& make install \
		|| return
}

build_rakudo() {
	info "Starting build on Rakudo"

	build_prepare "$BASEDIR/src/rakudo-$VERSION" || return
	perl Configure.pl \
		--backend="$RSTAR_BACKEND" \
		"$@" \
		&& make \
		&& make install \
		|| return
}

build_prepare() {
	local source="$1"
	local destination

	destination="$(tmpdir)"

	notice "Using $destination as working directory"

	cp -R -- "$source/." "$destination" \
		&& cd -- "$destination" \
		|| return
}

install_raku_module() {
	"$RSTAR_PREFIX/bin/raku" "$BASEDIR/lib/install-module.raku" "$1"
}

