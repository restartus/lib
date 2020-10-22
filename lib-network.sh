#!/usr/bin/env bash
##
## library network functions
## Note this need lib-install.sh
# https://www.icann.org/resources/pages/tlds-2012-02-25-en

TLD_URL=${TLD_URL:-"http://data.iana.org/TLD/tlds-alpha-by-domain.txt"}
TLD_LIST=${TLD_LIST:-"$WS_DIR/cache/$(basename "$TLD_URL")"}
# need the download url so make sure to source lib-network.sh

# We need this because ssh-keygen -R does not remove ipv6 addresses correctly
# usage: remove_from_authorized_hosts hosts...
remove_from_authorized_hosts() {
	for host in "$@"; do
		host="$(remove_account "$host")"
		ssh-keygen -R "$host"
		ssh-keygen -R "$(get_ip "$host")"
		ssh-keygen -R "$(get_ip6 "$host")"
	done
}

# add .local domain if there is TLD
# usage; add_local dns_name,...
add_local() {
	if [[ ! -e "$TLD_LIST" ]]; then
		download_url "$TLD_URL" "$(dirname "$TLD_LIST")"
	fi
	for host in "$@"; do
		local ext="${host##*.}"
		if [[ ! $ext =~ local ]] && ! grep "$ext" "$TLD_LIST"; then
			echo "$host.local"
		else
			echo "$host"
		fi
	done
}

# add account@ if not present to a ssh [user@]dns_name
# usage: add_account account_to_add hostnames...
add_account() {
	if (($# < 1)); then return 1; fi
	local account=$1
	shift
	for host in "$@"; do
		if [[ ! $host =~ @ ]]; then
			host="$account@$host"
		fi
		echo "$host"
	done
}

# make the account fully qualified with .local added and account added
# usage: add_accounts_and_local account [hostnames...]
add_account_and_local() {
	if (($# < 1)); then return 1; fi
	local account=$1
	shift
	add_local "$(add_account "$account" "$@")"
}

# creates a list of users names at host names if there are no specific ones, then generate them
# from prefix and count. it returns the fully qualifited version with
# account@host[.local] assuming mDNS is being used
# usage: generate_remotes account host-prefix total-number-of-hosts [hostnames...]
generate_remotes() {
	if (($# < 3)); then
		return 1
	fi
	local account="$1"
	if (($# == 3)); then
		local host="$2"
		local total="$3"
		# log_verbose no hostname given so autogenerate from $PREFIX for $TOTAL hosts
		for i in $(seq 0 $((total - 1))); do
			add_account_and_local "$account" "$host$i"
		done
	else
		shift 3
		log_verbose "adding $*"
		add_account_and_local "$account" "$@"
	fi
}

# get_mac_address hostnames,..
get_mac_address() {
	for host in "$@"; do
		host=$(add_local "$(remove _account "$host")")
		ip=$(ping -c 1 "$host" | head -1 | awk '{print $3}' | grep -o "[0-9.]*")
		arp -n -a | grep "$ip" | awk '{print $4}'
	done

}

get_user() {
	for remote in "$@"; do
		echo "${remote%@*}"
	done
}

get_host() {
	for remote in "$@"; do
		echo "${remote#*@}"
	done
}

# remove the account@ if present
remove_account() {
	for host in "$@"; do
		echo "${host#*@}"
	done
}

# remove .local if present
# usage: remove_local dns_name,...
remove_local() {
	for host in "$@"; do
		echo "${host%.local}"
	done
}

remove_account_and_local() {
	for host in "$@"; do
		remove_account "$(remove_local "$host")"
	done
}

# get_mac_address hostnames,..
get_mac_address() {
	for host in "$@"; do
		host=$(add_local "$(remove_account "$host")")
		ip=$(ping -c 1 "$host" | head -1 | awk '{print $3}' | grep -o "[0-9.]*")
		arp -n -a | grep "$ip" | awk '{print $4}'
	done
}

# http://superuser.com/questions/894424/is-there-an-easy-way-to-do-a-host-lookup-by-mac-address-on-a-lan
# get_ip dns_name
get_ip() {
	# note arp is different on OSX vs ubuntu
	# arp -a "$host" 2>/dev/null | grep -o '(.*)' | sed 's/[()]//g'
	#  ping generates stderr message if not found so mask it
	host="$(remove_account "${1:-localhost}")"
	ping -c 1 "$host" 2>/dev/null | awk 'NR==1 {print $3}' | tr -d '():'
}

# GEt ip v6
# usage: get_ip6 remote
get_ip6() {
	host="$(remove_account "${1:-localhost}")"
	ping6 -c 2 "$host" 2>/dev/null | awk 'NR==1 {print $5}'
}

# is the host alive stripping account@ as needed
# usage: host_aliive hostnames
host_alive() {
	for host in $(remove_account "$@"); do
		if ! ping -c 2 "$host" >/dev/null 2>&1; then
			return 1
		fi
	done
}

# get_ip machine interface from the remote side
get_from_remote_ip() {
	local machine=${1:root\@localhost}
	local interface=${2:eth0}
	ssh "$machine" ip -4 addr show "$interface" | grep inet | awk '{print $2}' | sed 's/\/.*//'
}

# write_ip machine_file host wan_ip [lan_ip]
write_ip() {
	local file=${1:-"$WS_DIR/git/personal/$USER/rpi.txt"}
	local host=${2:-"localhost"}
	local wan=${3:-"$(get_ip)"}
	local lan=${4:-""}
	echo "$host $wan $lan" >>"$file"
}

# read_ip machine_file (lan|wan)
# sends the IPs to stdout
read_ips() {
	local file=${1:-"$WS_DIR/git/user/$USER/rpi.txt"}
	local type=${2:-wan}
	while read -r HOST WAN LAN; do
		if [[ -z $HOST || $HOST =~ ^# ]]; then
			log_verbose skipping blank or comment line
			continue
		fi
		if [[ $type == wan ]]; then
			if [[ ! $MACHINES =~ $WAN ]]; then
				echo "\"$WAN\""
			fi
		else
			if [[ ! $MACHINES =~ $LAN ]]; then
				echo "\"$LAN\""
			fi
		fi
	done <"$file"
}
