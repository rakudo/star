#!/usr/bin/env bash

RSTAR_DEPS_BIN+=(
	awk
)

action() {
	for key in "${!RSTAR_PLATFORM[@]}"
	do
		printf "%-15s %s\n" "$key" "${RSTAR_PLATFORM[$key]}"
	done
}
