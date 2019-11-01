#! /usr/bin/env sh

main()
{
    if [ -z "$1" ]
    then
        usage
        exit 1
    fi

    printf "md5    %s\n" "$(md5sum "$1" | cut -f1 -d" ")"
    printf "sha1   %s\n" "$(sha1sum "$1" | cut -f1 -d" ")"
    printf "sha224 %s\n" "$(sha224sum "$1" | cut -f1 -d" ")"
    printf "sha256 %s\n" "$(sha256sum "$1" | cut -f1 -d" ")"
    printf "sha384 %s\n" "$(sha384sum "$1" | cut -f1 -d" ")"
    printf "sha512 %s\n" "$(sha512sum "$1" | cut -f1 -d" ")"
}

usage()
{
    printf "NYI\n"
}

main "$@"
