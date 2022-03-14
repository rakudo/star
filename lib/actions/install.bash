#!/usr/bin/env bash

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

	# Throw OS-specific warnings, if any
	case ${RSTAR_PLATFORM["key"]} in
		openbsd)
			# Check for userlimits
			if [[ -z "$(userinfo "$(whoami)" | awk '$1 == "class" { print $2 }')" ]]
			then
				warn "Your user does not have a class, this may limit the installer's memory"
				warn "usage, which can result in failure to compile."
			fi
			;;
	esac

	# Prepare environment for a reproducible install
	case ${RSTAR_PLATFORM["key"]} in
		dragonfly)        LC_ALL=C           ;;
		linux-arch_linux) LC_ALL=en_US.UTF-8 ;;
		*)                LC_ALL=C.UTF-8     ;;
	esac

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

	# Create the installation directory
	mkdir -p -- "$RSTAR_PREFIX"

	# Use an absolute path when reporting about the installation path
	prefix_absolute="$(CDPATH="" cd -- "$RSTAR_PREFIX" 2> /dev/null && pwd -P)"
	info "Installing Raku in $prefix_absolute"

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
	local args

	args+=("--prefix=$RSTAR_PREFIX")

	# Build relocatable components when not on OpenBSD.
	if [[ ${RSTAR_PLATFORM[os]} != "openbsd" ]]
	then
		args+=("--relocatable")
	fi

	# Compile all core components
	for component in moarvm nqp rakudo
	do
		VERSION="$(config_etc_kv "fetch_core.txt" "${component}_version")" \
			build_"$component" "${args[@]}" && continue

		die "Build failed!"
	done
}

action_install_modules() {
	local failed_modules
	local modules

	notice "Starting installation of bundled modules"

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
	local logfile="/dev/stdout"

	info "Starting build on MoarVM"

	build_prepare "$BASEDIR/src/moarvm-$VERSION/MoarVM-$VERSION" || return

	if [[ -z "$RSTAR_DEBUG" ]]
	then
		logfile="$(tmpfile)"
		notice "Build log available at $logfile"
	fi

	{
		perl Configure.pl "$@" \
		&& make \
		&& make install \
		> "$logfile" \
		|| return
	} > "$logfile" 2>&1
}

build_nqp() {
	local logfile="/dev/stdout"

	info "Starting build on NQP"

	build_prepare "$BASEDIR/src/nqp-$VERSION/nqp-$VERSION" || return

	if [[ -z "$RSTAR_DEBUG" ]]
	then
		logfile="$(tmpfile)"
		notice "Build log available at $logfile"
	fi

	{
		perl Configure.pl --backend="$RSTAR_BACKEND" "$@" \
		&& ${RSTAR_PLATFORM[make]} \
		&& ${RSTAR_PLATFORM[make]} install \
		|| return
	} > "$logfile" 2>&1
}

build_rakudo() {
	local logfile="/dev/stdout"

	info "Starting build on Rakudo"

	build_prepare "$BASEDIR/src/rakudo-$VERSION/rakudo-$VERSION" || return

	if [[ -z "$RSTAR_DEBUG" ]]
	then
		logfile="$(tmpfile)"
		notice "Build log available at $logfile"
	fi

	{
		perl Configure.pl --backend="$RSTAR_BACKEND" "$@" \
		&& ${RSTAR_PLATFORM[make]} \
		&& ${RSTAR_PLATFORM[make]} install \
		|| return
	} > "$logfile" 2>&1
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
	if [[ -f "$1/Build.pm6" ]]
	then
		"$RSTAR_PREFIX/bin/raku" "$RSTAR_PREFIX/share/perl6/vendor/bin/zef" build "$1"
	fi

	"$RSTAR_PREFIX/bin/raku" "$BASEDIR/lib/install-module.raku" "$1"
}

