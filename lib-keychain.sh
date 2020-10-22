#!/usr/bin/env bash
# vi: se ts=4 sw=4 et
##
## use the openssh keychain and not gnome on Linux
## On mac's the El Capitan keychain supports id_ed25519

## usage use_openssh_keychain [key1 key2...]
## returns 0 if no reboot required other wise returns 1
use_openssh_keychain() {
	local keys="$@"
	local no_keychain_found=0

	# only for linux systems
	if [[ $OSTYPE =~ darwin ]]; then
		return
	fi

	# disable the Gnome keyring not compatible with id_ed25519 keys
	# do not need to disable gnome keyring if present, just start keychain
	# and point the SSH_AUTH_SOCK to it
	# if set | grep -q "^SSH_AUTH_SOCK=.*keyring"
	# then
	#    if pgrep ssh-agent
	#   then
	#       note this does not work on Ubuntu, you cannot just kill the gnome keyring
	#       pkill ssh-agent
	#   fi
	# fi

	# keychain will start if it isn't already and running eval will mean we use it instead of the
	# gnome keyring and if the keys requested are not there it will add them
	eval $(keychain --eval $@)
	# The daemon has keyring if it gnome keyring, it has agent if it is keychain
	#if [[ -z $SSH_AUTH_SOCK || ! $SSH_AUTH_SOCK =~ agent ]]
	#then
	# keychain will ignore if they are already present
	#   eval $(keychain --eval $@)
	# if no keychain is found, you need to eval the keychain --eval command or
	# have it at boot up.
	#     no_keychain_found=1
	#else
	#    ssh-add $@
	# fi

	# We should not ever need this as the logic above should handle
	# But if it fails this is @jmc's fall back search
	if [[ -z $SSH_AUTH_SOCK ]]; then
		# Use the ssh-agent if it is active
		# Normally prebuild.sh should add the keychain and ssh-add to the .bash_profile
		# But if it doesn't, we manually go through looking for the right agent
		agents=($(find /tmp/ssh-* -user $USER -name agent.* -print 2>/dev/null || true))
		for agent in ${agents[@]}; do
			log_verbose Trying $agent for $KEY
			if [[ ! -r $agent ]]; then
				continue
			fi
			if SSH_AUTH_SOCK="$agent" ssh-add -l | grep -q "$KEY"; then
				continue
			fi
			export SSH_AUTH_SOCK="$agent"
			break
		done
	fi
	return $no_keychain_found
}
