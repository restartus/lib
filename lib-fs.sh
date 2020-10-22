#!/usr/bin/env bash
##
## utility functions for @rich
## Note that in these libraries you should not assume include.sh is loaded
## So do not use log_verbose etc.
##

# takes the standard input and adds pretty spaces
# and an indent
# usage: indent_output amount_of_indent
# https://unix.stackexchange.com/questions/148109/shifting-command-output-to-the-right

# Get the profiles loaded into this script

# find_dropbox and return the location fixes the links
dropbox_find() {
	if [[ ! -e $HOME/Dropbox ]]; then
		log_verbose "first look for personal then other enterprise dropbox folders"
		for dropbox in "$HOME/Dropbox (Personal)" "$HOME/Dropbox "*; do
			if [[ -e $dropbox ]]; then
				ln -s "$dropbox" "$HOME/Dropbox"
				exit
			fi
		done
	fi
	# could not find dropbox
	exit 1
}

# is_ssd [disks] returns 0 if they are all ssds otherwise the number of non-SSDs
disk_is_ssd() {
	if [[ $# -lt 1 ]]; then return 1; fi
	if [[ $OSTYPE =~ darwin ]]; then return; fi
	error=0
	local rotational
	for disk in "$@"; do
		# use readlink to get the true /dev/sd name
		disk="$(readlink -f "$disk")"
		# if the disk doesn't exist then say it is not an ssd
		rotational="/sys/block/$(basename "$disk")/queue/rotational"
		if [[ ! -e $rotational ]] || (($(cat "$rotational") != 0)); then
			((++error))
		fi
	done
	return "$error"
}

# usage: disk_size [list of disks]
# stdout: drive size
disk_size() {
	log_verbose "disk_size got $*"
	for d in "$@"; do
		# make sure it is valid and onliy see the main drive
		# Need eval because this comes in with quotes
		if ! eval lsblk --nodeps "$d" >/dev/null 2>&1; then
			continue
		fi
		# Note you need -e to allow spaces and -n to prevent newline
		echo -en "$d "
		# Sort it do not use --scsi since for ata drives no size is output
		eval lsblk --nodeps --output size --noheadings "$d"
	done
}

# sort the disks by biggest first this maximizes the free space
# REturns the list of driver
disk_sort() {
	log_verbose "disk_sort got $*"
	log_verbose "disk_size returned $(disk_size "$@")"

	disk_size "$@" | sort -k2,2 -r | cut -d ' ' -f 1
}

# Given a list of disks, uses the number and returns the configuration type
# So it is ready for sroting
zfs_disk_configuration() {

	log_verbose "zfs_disk count $# and arguments are $*"
	if (($# == 1)); then
		echo "$1"
		return
	fi

	# the new recommendation for SSDs and big drives is just to mirror
	# this magic one liner sorts all the disks listed by their size according
	# lsblk note we use $@ to preserve white spaces in names
	# And we are making this an array
	# This does not work with real disk names not by-id
	# disks=($(echo $@ | xargs readlink -f | \
	#    xargs lsblk --all --nodeps -o name,size --noheadings --paths | \
	#    sort -k2,2 -r | cut -d ' ' -f 1))

	# sort the disks by biggest first this maximizes the free space
	log_verbose "disks are $*"
	local disks
	disks="$(disk_sort "$@")"
	log_verbose "disk_sort returned $disks"
	# note bash cannot parse disks=($(disk_sort $@)) into an array so do in two pieces
	# https://github.com/koalaman/shellcheck/wiki/SC2206
	IFS=" " read -r -a disks <<<"$disks"
	local count=${#disks[@]}
	# keep pushing out mirrors from large3st to smallest disks
	log_verbose "disk count $count for ${disks[*]}"
	while ((count > 1)); do
		log_verbose "count is $count"
		# -n mean no newline and -e means keep spaces
		echo -ne "mirror ${disks[0]} ${disks[1]} "
		# Use array operation to remove first two elements
		# http://tldp.org/LDP/abs/html/arrays.html
		IFS=" " read -r -a disks <<<"${disks[@]:2}"
		count=$((count - 2))
	done
	# push out last disk as a spare
	if ((count == 1)); then
		# $disks is same as ${disks[0]}
		echo -ne "spare ${disks[*]}"
	fi
	return

	case $# in
	0)
		return
		;;
	1)
		echo "$*"
		;;
	2)
		echo "mirror $*"
		;;
		# http://eonstorage.blogspot.com/2010/03/whats-best-pool-to-build-with-3-or-4.html
		# http://blog.delphix.com/matt/2014/06/06/zfs-stripe-width/
		# http://www.zfsbuild.com/2010/05/26/zfs-raid-levels/
	3)
		echo "mirror $1 $2 spare $3"
		;;
	4)
		# This creates a Raid 10 note we do not check
		# the sizes of these with lsblk to match like to like
		# so we are assuming they are of the same size.
		# https://askubuntu.com/questions/332949/what-command-do-i-use-to-find-physical-disk-size
		echo "mirror $1 $2 mirror $3 $4"
		;;
	5)
		# old recommendation see above
		echo "raidz $*"
		;;
	[6-9] | 10)
		echo "raidz2 $*"
		;;
	1[1-9])
		echo "raidz3 $*"
		;;
	*)
		# too many disks to configure manually
		return 1
		;;
	esac
}

# usage: Is_zfs properties dataset
# assumes zfs is loaded
zfs_list() {
	if (($# < 2)); then return 1; fi
	local option="${1:-"name,used,avail,refer,mountpoint"}"
	local dataset="${2:-$POOL/data}"
	sudo zfs list -H -o "$option" "$dataset"
}

# given list of disks see if they are already mounted
disks_not_mounted() {
	local mounts
	mounts=$(mount)
	if (($# < 1)); then
		echo -n 0
		return 0
	fi
	local already_mounted=0
	for disk in "$@"; do
		if [[ $mounts =~ $disk ]]; then
			log_warning "$disk is already mounted so cannot use"
			((++already_mounted))
		fi
	done
	echo -n "$already_mounted"
	return "$already_mounted"
}

# usage: disks_list_possible
# looks for drives that are available and not being used by zfs
# non standard use of return, this tells you how many drives were found
disks_list_possible() {
	local disks
	if [[ $OSTYPE =~ darwin ]]; then
		disks="$(find /dev -name "disk?" 2>/dev/null)"
	elif in_vmware_fusion && command -v lsblk >/dev/null; then
		# fusion only puts the CDROM into /dev/disk/by-id so use regular names
		# in fusion although we can list by-uuid, zfs refuses to mount htme.
		disks=$(find /dev/disk/by-uuid -mindepth 1)
		# so use lsblk to find drives and then sed to add /dev to their names
		disks=$(lsblk --raw --noheadings --nodeps --exclude 1,11 | cut -f1 -d' ' | sed 's$^$/dev/$')
		# This is a uuid for vmware also supports this and should be more
		# portable
	elif [[ -d /dev/disk/by-id ]]; then
		# do depth first search and search the not found
		# remove wwn (Worldwide name) is a 64bit unique identifiy for a driver
		# http://manpages.ubuntu.com/manpages/zesty/man8/lsscsi.8.html
		# lvm (logical volume manager) disks
		# -part  removes partitions of disk
		# http://www.atmel.com/products/memories/serial/mac-eui-serial-number.aspx
		# nvme-ieu which point to the underlying disks which is another unique identifier
		disks="$(find /dev/disk/by-id -mindepth 1 | grep -v -e "-part[0-9$]" -e wwn- -e lvm- -e nvme-eui\.)"
	fi

	local real_disk
	for disk in $disks; do
		# if this is a symlink then get the actual real disk name
		# convert to /dev/sd? usually
		real_disk="$(readlink -f "$disk")"
		# note this file runs early so do only depend on bash 3.2 features no |&
		# first see if the disk is mounted
		if mount 2>&1 | grep -q "^$real_disk"; then
			continue
		elif command -v zpool >/dev/null && sudo zpool status 2>/dev/null | grep -q "$(basename "$disk")"; then
			# if zfs is loaded make sure it is not on the zpool list
			continue
		fi
		# this is unallocated so send the name to stdout
		echo -n "\"$disk\" "
	done
}
