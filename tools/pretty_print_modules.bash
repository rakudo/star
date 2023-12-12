#!/usr/bin/env bash
# set -x

BASEDIR="$(CDPATH="" cd -- "$(dirname -- "$0")/.." && pwd -P)"
# export BASEDIR
MODULESDIR="${BASEDIR}/tmp/modules"
MODULES_LOCAL="${BASEDIR}/etc/modules.txt"
MODULES_LOCAL_TEMP="${MODULESDIR}/modules_temp.txt"
MODULES_GIT_REMOTE="https://raw.githubusercontent.com/rakudo/star/master/etc/modules.txt"

MODULES_LOCAL=${1:-$MODULES_LOCAL}
MODULES_LOCAL_TEMP=${2:-$MODULES_LOCAL_TEMP}

# Initialize arrays to store maximum string lengths and the fields of the git or https matching lines
declare -a max_lengths fields
#
#####
#
function clean_modules_dir() {
    
    if [ -d "$MODULESDIR" ]; then
      \rm -rf -- "$MODULESDIR"
    fi
    mkdir -p -- "$MODULESDIR"
    
}

# If module file names are given as parameters, ensure the directories exist to store those files
function mk_local_modules_dirs() {
    
    local LOCAL_MODULES_DIR
    
    for LOCAL_MODULES_DIR in $MODULESDIR $MODULES_LOCAL $MODULES_LOCAL_TEMP; do
      LOCAL_MODULES_DIR=$(dirname -- "$LOCAL_MODULES_DIR")
      if [ ! -d "$LOCAL_MODULES_DIR" ]; then mkdir -p -- "$LOCAL_MODULES_DIR"; fi
    done
    
}

# Ensure we have a modules.txt file to work with
function get_modules_file() {
    
    if [ ! -s "$MODULES_LOCAL" ]; then
      curl -s "$MODULES_GIT_REMOTE" --output "$MODULES_LOCAL"
    fi
	
	# should never happen, but who knows... maybe the GitHub repo is not available for whatever reason
    if [ ! -s "$MODULES_LOCAL" ]; then
      echo "\"$MODULES_LOCAL\" not found and couldn't be downloaded from \"$MODULES_GIT_REMOTE\"".
    exit $LINENO
    fi
    
}

# Function to find the maximum of two numbers
function max {
  if (( $1 > $2 )); then
    echo "$1"
  else
    echo "$2"
  fi
}

# Function to print a field with padding to the maximum length
function pretty_print {
    local field="$1"
    local length="$2"
    printf "%-${length}s  " "$field"
}

clean_modules_dir
mk_local_modules_dirs
get_modules_file

while IFS= read -r MODULES_FILE_LINE; do
    # Check if the second field contains "git" or "https"
    # if [[ "$MODULES_FILE_LINE" =~ " git " || "$MODULES_FILE_LINE" =~ " https " ]]; then
    if [[ "$MODULES_FILE_LINE" =~ " git " ]]; then

        # Split the line into an array using whitespace as the delimiter
        read -ra fields <<< "$MODULES_FILE_LINE"
        
        # Clone the git repository from the third field
        git clone --quiet "${fields[2]}" "$MODULESDIR/${fields[0]}" > /dev/null 2>&1 # || return
        
        # Get the latest tag or current branch
        pushd "$MODULESDIR/${fields[0]}" > /dev/null
        GIT_TAG=$(git describe --tags --abbrev=0 2>/dev/null)
        if [[ $? -ne 0 ]]; then
          GIT_TAG="$(git tag --sort=committerdate | tail -1)" # this doesn't work if developers mix-in characters into their tags... like starting with vX.Y.Z
        fi
        
        GIT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
        
        # # Update the 4th field based on tag or branch
        # if [[ -n "$GIT_TAG" && "${fields[3]}" != "$GIT_TAG" ]]; then
            # fields[3]="$GIT_TAG"
        # elif [[ -n "$GIT_BRANCH" && "${fields[3]}" != "$GIT_BRANCH" ]]; then
            # fields[3]="$GIT_BRANCH"
       
        # fi
        if [ "$GIT_TAG" != "" ]; then
            fields[3]="$GIT_TAG"
        else
            fields[3]="$GIT_BRANCH"
        fi
        # Check if META6.json file exists
        if [[ -f META6.json ]]; then
            # Parse META6.json for the "version" key
            VERSION=$(jq -r '.version' META6.json 2>/dev/null)
            if [[ -n "$VERSION" && "$VERSION" != "${fields[3]}" && "v$VERSION" != "${fields[3]}" ]]; then
                echo "WARNING: Version mismatch for ${fields[0]} (\"${fields[2]}\") found. META6.json has \"$VERSION\" but latest 'git tag' is \"${fields[3]}\"" >&2
                ###### gh auth login
                ###### gh auth status
                ###### gh issue create --title "Version mismatch for HTTP-UserAgent" --body "META6.json has \"1.1.52\" but latest 'git tag' is \"v1.1.38\""
            fi
        fi
        echo "${fields[*]}"
        popd > /dev/null
    else
        # For lines that don't match "git" or "https", simply print them as they are
        echo "$MODULES_FILE_LINE"
    fi
done < $MODULES_LOCAL > $MODULES_LOCAL_TEMP

# Loop through each line in the modules.txt file and find the maximum string lengths
# Calculate the maximum string length for each field and update max_lengths array
while IFS= read -r MODULES_FILE_LINE; do
    # Check if the second field contains "git" or "https"
    # if [[ "$MODULES_FILE_LINE" =~ " git " || "$MODULES_FILE_LINE" =~ " https " ]]; then
    if [[ "$MODULES_FILE_LINE" =~ " git " ]]; then

        # Split the line into an array using whitespace as the delimiter
        read -ra fields <<< "$MODULES_FILE_LINE"
        
        # Loop through each field and update the maximum string length in the max_lengths array
        for (( i=0; i<${#fields[@]}; i++ )); do
            max_lengths[$i]=$(max ${#fields[$i]} ${max_lengths[$i]:-0})
        done
    fi
done < $MODULES_LOCAL_TEMP
        
# Print the modules.txt file again with fields aligned to the maximum length
while IFS= read -r MODULES_FILE_LINE; do
    # Check if the second field contains "git" or "https"
    # if [[ "$MODULES_FILE_LINE" =~ " git " || "$MODULES_FILE_LINE" =~ " https " ]]; then
    if [[ "$MODULES_FILE_LINE" =~ " git " ]]; then

        # Split the line into an array using whitespace as the delimiter
        read -ra fields <<< "$MODULES_FILE_LINE"
        # Loop through each field and print it with padding to the maximum length
        for (( i=0; i<${#fields[@]}; i++ )); do
            pretty_print "${fields[$i]}" ${max_lengths[$i]}
        done
        printf "\n"
    else
        # For lines that don't match "git" or "https", simply print them as they are
        echo "$MODULES_FILE_LINE"
    fi
done < $MODULES_LOCAL_TEMP > $MODULES_LOCAL && \rm $MODULES_LOCAL_TEMP
