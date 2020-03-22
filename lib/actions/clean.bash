#!/usr/bin/env bash

action() {
	remove "$BASEDIR/tmp"
	remove "$BASEDIR/install"
}

remove() {
	info "Removing $1"
	rm -fr -- "$1"
}
