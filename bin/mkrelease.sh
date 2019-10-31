#! /usr/bin/env sh

readonly BASEDIR=$(CDPATH="" cd -- "$(dirname -- "$0")/.." && pwd -P)

main()
{
  if [ -z "$1" ]
  then
    usage
    exit 1
  fi

	cd -- "$BASEDIR"
	make -f tools/star/Makefile all VERSION="$1"
	make -f tools/star/Makefile release VERSION="$1"
}

usage()
{
  print "NYI"
}

main "$@"
