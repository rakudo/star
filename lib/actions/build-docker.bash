#!/usr/bin/bash

action() {
	local OPTIND
	local base_image
	local base_tag
	local output_tag
	local dockerfile
	local template
	local install_options

	while getopts ":B:b:f:T:t:" opt
	do
		case "$opt" in
			b) RSTAR_BACKEND=$OPTARG ;;
			B) base_image=$OPTARG ;;
			T) base_tag=$OPTARG ;;
			t) output_tag=$OPTARG ;;
			f) template=$OPTARG ;;
			*) emerg "Invalid option specified: $opt" ;;
		esac
	done

	# Base image must be specified
	if [[ -z $base_image ]]
	then
		emerg "Must specify a base image with -B"
		exit 2
	fi

	# Tag of base image defaults to 'latest'
	[[ -z $base_tag ]] && base_tag="latest"

	# Set a default tag for the built image with relevant information
	if [[ -z "$output_tag" ]]
	then
		output_tag="rakudo:$base_image-$base_tag"
		if [[ ! -z $RSTAR_BACKEND ]]
		then
			output_tag="$output_tag-$RSTAR_BACKEND"
		fi
	fi

	dockerfile=$(tempfile)

	# We use the Dockerfile template for this image + tag pair if it exists,
	# or use the image default template
	if [[ -z $template ]] && [[ -f "$BASEDIR/lib/docker/$base_image/$base_tag" ]]
	then
		template="$BASEDIR/lib/docker/$base_image/$base_tag"
	else
		if [[ -f "$BASEDIR/lib/docker/$base_image" ]]
		then
			template="$BASEDIR/lib/docker/$base_image"
		else
			# Die if we have not found a template to use
			emerg "No Dockerfile template found for '$base_image:$base_tag'!"
			exit 2
		fi
	fi

	# Fill in template placeholders
	if [[ ! -z $RSTAR_BACKEND ]]
	then
		install_options="$install_options -b "'"'"$RSTAR_BACKEND"'"'
	fi

	sed < "$template" > "$dockerfile" \
		-e "s/{{INSTALL_OPTIONS}}/$install_options/" \
		-e "s/{{TAG}}/$base_tag/"

	# Build the image with the generated Dockerfile
	docker build -t "$output_tag" -f "$dockerfile" "$BASEDIR"

	shift $(( OPTIND -1 ))
}
