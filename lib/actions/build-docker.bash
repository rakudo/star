#!/usr/bin/env bash

RSTAR_DEPS_BIN+=(
	docker
)

action() {
	local OPTIND
	local name
	local version
	local description
	local tag
	local dockerfile
	local target

	while getopts ":T:b:d:ln:t:" opt
	do
		case "$opt" in
			T) tag=$OPTARG ;;
			b) RSTAR_BACKEND=$OPTARG ;;
			d) description=$OPTARG ;;
			l) tag_latest=1 ;;
			n) name=$OPTARG ;;
			t) version=$OPTARG ;;
			*) emerg "Invalid option specified: $opt" ;;
		esac
	done

	shift $(( OPTIND - 1 ))

	SOURCE_DATE_EPOCH="$(git log -1 --pretty=format:%at)"

	if (( $# < 1 ))
	then
		alert "You must specify a base image to build for"
		action_build_docker_list
		return 2
	fi

	target=$1
	shift

	# Show warnings
	if [[ -n $tag ]] && [[ -n $tag_latest ]]
	then
		warn "-l is ignored if -T is given"
	fi

	if (( 0 < $# ))
	then
		warn "Only $target will be built, additional arguments are being ignored!"
	fi

	# Set defaults for the Docker tag value
	[[ -z $name ]] && name="$USER/rakudo-star"

	# Build up a nice tag if none was explicitly defined
	if [[ -z $tag ]]
	then
		[[ -z $version ]] && version="$(datetime %Y.%m)"
		[[ -z $description ]] && description="$target"

		tag="$version-$description"
	fi

	dockerfile="$BASEDIR/lib/docker/$target.Dockerfile"

	debug "Using $dockerfile"

	if [[ ! -f $dockerfile ]]
	then
		alert "Target '$target' is not supported"
		action_build_docker_list
		return 2
	fi

	# Build the image
	docker build \
		-t "$name:$tag" \
		-f "$dockerfile" \
		--build-arg SOURCE_DATE_EPOCH="$SOURCE_DATE_EPOCH" \
		--build-arg RSTAR_BACKEND="$RSTAR_BACKEND" \
		"$BASEDIR"

	# Also tag the image as "latest"
	if [[ $tag_latest ]]
	then
		docker tag "$name:$tag" "$name:latest-$target"
	fi
}

action_build_docker_list() {
	chgdir "$BASEDIR/lib/docker" > /dev/null

	info "Available targets are:"

	for target in *.Dockerfile
	do
		info "  ${target%.*}"
	done
}
