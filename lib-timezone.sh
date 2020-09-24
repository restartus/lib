#!/usr/bin/env bash
#
# Find and set timezones works on Mac or Ubuntu
#

get_timezone() {
    if [[ $OSTYPE =~ darwin ]]
    then
        sudo systemsetup -gettimezone | cut -d ' ' -f 3
    else
        cat /etc/timezone
    fi
}

set_timezone() {
    if (( $# < 1 )); then return 1; fi
    local tz="$1"
    if [[ $OSTYPE =~ darwin ]]
    then
        sudo systemsetup -settimezone "$tz"
    else
        sudo datetimectl set-timezone "$tz"
    fi
}
