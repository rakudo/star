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
	local OPTIND

	while getopts ":b:p:" opt
	do
		case "$opt" in
			b) RSTAR_BACKEND=$OPTARG ;;
			p) RSTAR_PREFIX=$OPTARG ;;
		esac
	done

	shift $(( OPTIND -1 ))
	# TODO: Check if binaries are available

	mkdir -p -- "$RSTAR_PREFIX"
	local prefix_absolute="$(CDPATH="" cd -- "$RSTAR_PREFIX" && pwd -P)"

	info "Installing Raku in $prefix_absolute"

	# Compile all core components
	for component in moarvm nqp rakudo
	do
		VERSION="$(config_etc_kv "dist_$component.txt" "version")" \
			build_"$component" \
				--prefix="$RSTAR_PREFIX" \
				--relocatable \
			&& continue

		die "Build failed!"
	done

	# Install community modules
	failed_modules=()

	for module in $(awk '/^[^#]/ {print $1}' "$BASEDIR/etc/modules.txt")
	do
		info "Installing $module"

		install_raku_module "$BASEDIR/dist/src/modules/$module" \
			&& continue

		failed_modules+=("$module")
	done

	# Show a list of all modules that failed to install
	if [[ $failed_modules ]]
	then
		crit "The following modules failed to install:"

		for module in "${failed_modules[@]}"
		do
			crit "  $module"
		done
	fi

	# Friendly message
	info "Rakudo Star has been installed into $prefix_absolute!"
	info "You may need to add the following paths to your \$PATH:"
	info "  $prefix_absolute/bin"
	info "  $prefix_absolute/share/perl6/site/bin"
	info "  $prefix_absolute/share/perl6/vendor/bin"
	info "  $prefix_absolute/share/perl6/core/bin"
}

build_moarvm() {
	info "Starting build on MoarVM"

	build_prepare "$BASEDIR/dist/src/core/moarvm-$VERSION" || return
	perl Configure.pl \
		"$@" \
		&& make \
		&& make install \
		|| return
}

build_nqp() {
	info "Starting build on NQP"

	build_prepare "$BASEDIR/dist/src/core/nqp-$VERSION" || return
	perl Configure.pl \
		--backend="$RSTAR_BACKEND" \
		"$@" \
		&& make \
		&& make install \
		|| return
}

build_rakudo() {
	info "Starting build on Rakudo"

	build_prepare "$BASEDIR/dist/src/core/rakudo-$VERSION" || return
	perl Configure.pl \
		--backend="$RSTAR_BACKEND" \
		"$@" \
		&& make \
		&& make install \
		|| return
}

build_prepare() {
	local source="$1"
	local destination="$(tempdir)"

	notice "Using $destination as working directory"

	cp -R -- "$source/." "$destination" \
		&& cd -- "$destination" \
		|| return
}

install_raku_module() {
	"$RSTAR_PREFIX/bin/raku" "$BASEDIR/lib/install-module.raku" "$1"
}
