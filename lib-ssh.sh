#!/usr/bin/env bash
##
## library functions for dealing with private and ssh secrets
##
## Mainly does the installation into $CWD/.ssh
##
##


## install_ssh_dir copies from $3 to $4 with user $1 and group $2
ssh_install_dir() {
    if (( $# != 4 )); then return 1; fi
    local user=${1:-"$USER"}
    local group=${2:-"$(id -gn)"}
    if [[ $OSTYPE =~ darwin ]]
    then
	local src=${3:-"/Volumes/Private/ssh/$user"}
    else
	local src=${3:-"$HOME/Private/ssh/$user"}
    fi
    local dest=${4:-"$HOME/.ssh"}
    mkdir -p "$dest"
    if [[ ! -e $src ]]; then return 2; fi

    # create the target directory
    sudo install -d -m 750 -o "$user" -g "$group" "$dest"

    if [[  -d "$src" ]]
    then
        # Note we are doing backups as we blow away .ssh
        # For Mac compatibility do not use the -- options
        sudo install -C -b -m 600 -o "$user" -g "$group" "$src"/{authorized_keys,config,*.pub,known_hosts,*.fingerprint} "$dest"
	# Now link the secrets in so that they work only if the src is open
	cd "$src"
	for secret in aws-access-key* *.pem *.id_rsa *.id_ed25519 *.json
	do
            # if we do not wild card match look for a real asterisk in the name
            if [[ $secret =~ ^"*." ]]
            then
                log_verbose no $secret found
                continue
            fi
	    # If there is no match, then the for in returns the wild card
	    # so need to make sure the src exists
	    # Note that -e does not detect a symbolic link on a Mac, need to use -L as well
	    if [[ -e $src/$secret && ! -e $dest/$secret || ! -L $dest/$secret ]]
	    then
		    ln -s "$src/$secret" "$dest"
	    fi
	done
	cd -
    fi

    # for security make sure all of destination has correct permissions
    sudo chown -R "$user:$group" "$dest"
    sudo chmod -R og-rwx "$dest"
}

# See http://help.github.com/articles/error-agent-admitted-failure-to-sign
# The new PCKS bcrypt for on-disk encryption does not work with gnome-keyring
# Use the search for id_ed25519 as a proxy although you can apply the bcrypt to id_rsa
# keys as well so this is not perfect
# Returns 0 if you should exit as we have replaced something
# argument #1 is the key to search for otherwise just search for id_ed25519 keys
# in config
# usage: ssh_use_openssh_keychain
use_openssh_keychain() {
	if ! dpkg -s openssh-client | grep 'Status:.* installed'
    then
		# this requires privilege so will fail in install-agent.sh for instance
		sudo apt-get install -y openssh-client
    fi
    # Now use keychain so ssh-add's survive reboots and logout
    # http://www.cyberciti.biz/faq/ubuntu-debian-linux-server-install-keychain-apt-get-command/
	if ! command -v keychain
	then
		sudo apt-get install -y keychain
	fi


    # looking for a particular key
    if (( $# > 0)) && ! grep "$1" "$HOME/.ssh/config"
    then
        return 1
    elif ! grep "id_ed255119" "$HOME/.ssh/config"
    then
        return 1
    elif [[ ! $SSH_AUTH_SOCK =~ keyring$ ]]
	then
        return 1
    fi

    # https://bugs.launchpad.net/ubuntu/+source/gnome-keyring/+bug/1387303
    # This autostart works for 14.04, but not for 14.10 and there after
    # https://wiki.archlinux.org/index.php/GNOME_Keyring
    if ! grep -q "^X-GNOME-Autostart-enabled=false" /etc/xdg/autostart/gnome-keyring-ssh.desktop
    then
        sudo tee -a /etc/xdg/autostart/gnome-keyring-ssh.desktop <<<'X-GNOME-Autostart-enabled=false'
        echo $SCRIPTNAME: To get rid of gnome-keyring ssh-agent a logout required
    fi
    # This is the "correct" way, but doesn't seem to work for 14.04
    # http://ubuntuforums.org/showthread.php?t=2250516
    # https://www.digitalocean.com/community/tutorials/how-to-configure-a-linux-service-to-start-automatically-after-a-crash-or-reboot-part-1-practical-examples
    # this works for ubuntu 14.04 using upstart
    # this works for upstart (ubuntu 14.04)
    mkdir -p "$HOME/.config/upstart"
    echo manual | tee -a "$HOME/.config/upstart/gnome-keyring.override"

    # This works for systemd (ubuntu 16.04)
    # https://wiki.archlinux.org/index.php/GNOME/Keyring
    # https://askubuntu.com/questions/162850/how-to-disable-the-keyring-for-ssh-and-gpg/213522
    mkdir -p "$HOME/.config/autostart"
    cp /etc/xdg/autostart/gnome-keyring-ssh.desktop "$HOME/.config/autostart"
    cat > "$HOME/.config/autostart/gnome-keyring-ssh.desktop" <<<"Hidden=true"
    return 0

}

## move_and_link home_dir private_dir target_dirs...
ssh_move_and_link() {
    if (( $# < 3 ))
    then
        return 1
    fi
    local home_dir=${1:-"$HOME"}
    local private_dir=${2:-"$HOME/Private"}
    shift 2
    local target_dirs
    if [[ -z $@ ]]
    then
        target_dirs="ssh aws"
    else
        target_dirs="$@"
    fi
    for dir in $target_dirs
    do
        source_dir="$home_dir/.$dir"
        if [[ ! -d "$source_dir" ]]
        then
            continue
        fi
        dest_dir="$private_dir/$dir"
        mkdir -p "$dest_dir"

        log_verbose "copy from source_dir=$source_dir dest_dir=$dest_dir"
        # handle .ssh as a special case
        if [[ $dir == ssh ]]
        then
            pushd "$source_dir" >/dev/null
            log_verbose "$dir handled specially only move private keys"
            for key in *{id_rsa,id_ed25519} aws-*-key
            do
                # do not move if we have already symlinked
                if [[ ! -L $key ]]
                then
                    mv -ub "$key" "$dest_dir"
                    ln -srb "$dest_dir/$key" .
                fi
            done
            popd > /dev/null
            continue
        fi

        # For other directories, move and then symlink it all if we haven't already
        if [[ ! -L $source_dir ]]
        then
            mv -ub "$source_dir" "$dest_dir"
            ln -srb "$dest_dir" "$home_dir"
        fi
    done
}

# Make sure the permissions are correct in an .ssh directory
set_ssh_permissions() {
    local dir="${1:-"$HOME/.ssh"}"
    chmod og-rwx "$dir"
    chmod -R og-rwx "$dir"/*
}


# paramaters are the site and the private key to use for it
add_site_to_ssh_config() {
    if [[ $# < 2 ]]
    then
        return 1
    fi
    cat >> config <<-EOF
Host $1
    IdentityFile $2
EOF
}
