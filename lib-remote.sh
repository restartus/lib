#!/usr/bin/env bash
##
## Library for running things remotely
## We copy into the same directory structure as git uses
##

# Note we assume ssh and rsync start at the home directory of the user

# usage: remote_config [user@]host
remote_config() {
	if (($# < 1)); then return 1; fi
	local remote="$1"

	local remote_script_dir=${remote_script_dir:-"ws/git/src"}
	ssh "$remote" mkdir -p "$remote_script_dir/"{bin,lib,etc}
	# use scp because rsync is required on the other side
	scp -r "$SOURCE_DIR/bin/include.sh" "$remote:$remote_script_dir/bin"
	scp -r "$SOURCE_DIR/lib" "$remote:$remote_script_dir/"
}

# This puts the script in the same relative location on the target machine
# so if the script is in $WS_DIR/bin on the host, it will also be there at
# the target. We need to adjust the user name since $HOME on remote machine is not the
# same as $HOME on the local machine
# -f means force the remote installation of libraries
# -a means copy the contents of the script directory
# usage: remote_run [-fr] [user@]host[.local] script_script [arguments....]
remote_run() {
	if (($# < 1)); then return 1; fi
	local force=false
	local all=false
	local sudo=""

	# http://stackoverflow.com/questions/16654607/using-getopts-inside-a-bash-function
	local OPTIND opt
	while getopts "afs" opt; do
		case "$opt" in
		f)
			force=true
			;;
		a)
			all=true
			;;
		s)
			sudo=sudo
			;;
		esac
	done
	shift $((OPTIND - 1))

	if (($# < 2)); then
		return 2
	fi
	local remote="$1"
	local script="$(readlink -f "$2")"
	local surround_sh="$(dirname "$script")/surround.sh"
	local script_rel_to_wsdir=${script#$WS_DIR/}
	local relative_ws_dir=${WS_DIR#$HOME/}
	local remote_script="$relative_ws_dir/$script_rel_to_wsdir"
	local remote_script_dir="$(dirname "$remote_script")"
	shift 2
	if $force || ! ssh "$remote" [ -e $relative_ws_dir/git/src/lib ]; then
		remote_config "$remote"
	fi

	ssh "$remote" mkdir -p "$remote_script_dir"
	if $all; then
		scp -r "$(dirname "$script")"/* "$remote:$remote_script_dir"
	else
		scp "$script" "$remote:$remote_script_dir"
	fi

	# most of rich's scripts need surround.sh too
	if [[ -e "$surround_sh" ]]; then
		scp "$surround_sh" "$remote:$remote_script_dir"
	fi
	ssh -t "$remote" $sudo "$remote_script" $@
}
