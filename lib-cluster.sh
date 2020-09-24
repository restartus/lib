#!/usr/bin/env bahs
## manage remote clusters
##

# wait_for a host to return
# reboot_and_wait user@host...
reboot_and_wait() {
    if (( $# < 1 )); then log_warning $FUNCNAME needs at least one argument; fi
    for user in $@
    do
        log_verbose changed configuration reboot rpi
        ssh "$user" sudo reboot || true
        local host=${user#*@}
        while ! ping -c 1 "$host"
        do
            sleep 5
        done
        log_verbose $host so check on ssh $user
        while ! ssh "$user" :
        do
            sleep 5
        done
        log_verbose reboot completed
    done
}
