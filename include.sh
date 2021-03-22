#!/usr/bin/env bash
##
## Note that since include.sh is normally sourced
## the Shebang has no effect so this must work for BASH or for Zsh
##
##
## Standard include for all script
## symlink this to the CWD of each script directory
#

# assumes that the workspace has a "git" subdirectory
# check for the function and do not process is it already exixts
# https://stackoverflow.com/questions/85880/determine-if-a-function-exists-in-bash

# https://stackoverflow.com/questions/9901210/bash-source0-equivalent-in-zsh#23259585
# this should be compatible with bash or zsh, it fails when BASH_SOURCE does not
# exist
# this works for zsh only not supported
#lib_name="$(basename "${BASH_SOURCE:-"${(%):-%N}"}")"
# create a variable that is just the filename without an extension
lib_name="$(basename "${BASH_SOURCE[0]}")"
lib_name="${lib_name%.*}"
# dashes are not allowed in bash variable names so make them underscores
lib_name=${lib_name//-/_}
#debugging
#echo "$lib_name"
#echo "${BASH_SOURCE[*]}"
# This is how to create a pointer by reference in bash so
# it checks for the existance of the variable named in $lib_name
# note how we use the escaped $ to get the reference
# This does not work as a bash
# if [[ ! -z $BASH &&  -z ${!lib_name} ]]
if [[ ! -v "$lib_name" ]]; then
	eval "$lib_name=true"

	find_ws() {
		local dir=${1:-$SCRIPT_DIR}
		# shellcheck disable=SC2016,SC1004
		local find_cmd='$(find "$dir" -maxdepth 2 \
            -name mnt -prune -o -name git -print -quit 2>/dev/null)'
		local found
		while true; do
			# do not go into mnt
			eval found="$find_cmd"
			if [[ -n $found ]]; then
				dirname "$found"
				return 0
			fi
			if [[ $dir = / ]]; then break; fi
			dir=$(dirname "$dir")
		done
		# https://stackoverflow.com/questions/1489277/how-to-use-prune-option-of-find-in-sh
		# do not go down into the mount directory
		eval dir="$find_cmd"
		# if no ws, then create one
		if [[ -z $dir ]]; then mkdir -p "${dir:=$HOME/ws/git}"; fi
		eval dir="$find_cmd"
		echo "$dir"
	}

	# now call find_ws to figure out the workspace
	export WS_DIR="${WS_DIR:-$(find_ws "$SCRIPT_DIR")}"
	export SOURCE_DIR="${SOURCE_DIR:-"$WS_DIR/git/src"}"
	export BIN_DIR="${BIN_DIR:-"$WS_DIR/git/src/bin"}"
	# in the world where there is no single src dir, this is the same as all the
	# git repos
	if [[ ! -e $SOURCE_DIR ]]; then
		SOURCE_DIR="$WS_DIR/git"
	fi

	# look for libs locally two levels up, then down from WS_DIR
	source_lib() {
		while (($# > 0)); do
			# Change the sourcing to look first down from WS_DIR for speed
			# exclude mnt so we do not disaoppear into sshfs mounts
			# maxdepth needs to be high enough for ws/git/user to find
			# ws/git/src/infra/lib
			local lib
			#if $DEBUG; then echo "looking for $1"; fi
			lib="$(find "$WS_DIR" "$SCRIPT_DIR"/{.,..,../..,../../..} -maxdepth 7 \
				-name mnt -prune -o -name "$1" -print -quit)"
			#if $DEBUG; then echo "found $lib"; fi
			if [[ -n $lib ]]; then
				# shellcheck disable=SC1090
				source "$lib"
			fi
			shift
		done
	}
	source_lib lib-debug.sh
fi
