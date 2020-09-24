#!/usr/bin/env bash
##
## Avahi publishing
## Either can do static publish via a file
## Or dynamic publishing by running a process
## Use the later when the service is only up temporarily
##

# avahi_publish service name type port [text]
# Adds an nice Mac icon as well
avahi_publish() {
    if [[ $OSTYPE =~ darwin ]]
    then
        log_verbose for linux only
        return
    fi
    # http://www.win.tue.nl/~johanl/educ/IoT-Course/mDNS-SD%20Tutorial.pdf
    # note this file must end in .service
    local dir="/etc/avahi/services"
    local service_file="$dir/${1:-nfs}.service"
    local name="${2:-"$HOSTNAME nfs"}"
    local protocol="${3:-"_nfs._tcp"}"
    local port="${4:-2049}"
    local text="${5:-""}"

    if [[ -e $service_file ]]
    then
        log_verbose $service_file already exists do not overwrite
        return
    fi

    # Ubuntu 14.04 does not like this header and throws an error
    #<?xml version="1.0" standalone='no'?><!--*-nxml-*-->
    #<!DOCTYPE service=group SYSTEM "avahi-service.dtd">
    sudo tee "$service_file" <<-EOF
<service-group>
  <name replace-wildcards="yes">$name</name>
  <service>
     <type>$protocol</type>
     <port>$port</port>
EOF
    # optionally put in  a text record
    if [[ -n $text ]]
    then
        sudo tee -a "$service_file" <<<"    <txt-record>$text</txt-record>"
    fi
    # http://simonwheatley.co.uk/2008/04/avahi-finder-icons/
    sudo tee -a "$service_file" <<-EOF
  </service>
  <service>
       <type>_device-info._tcp</type>
       <port>0</port>
       <txt-record>model=RackMac</txt-record>
   </service>
</service-group>
EOF

log_verbose added avahi nfs and check now for success
# with Ubuntu 16.04 the name comes out as capital letters use -i
# http://droptips.com/using-grep-and-ignoring-case-case-insensitive-grep
if ! sudo grep -i "$name"  /var/log/syslog
then
    return 1
fi

}

# avahi_publish_temp_start name type port text
avahi_publish_start() {
# The equivalent way for a temporary service
    #http://www.noah.org/wiki/Avahi_Notes
    # Needs to go in background
    if [[ $OSTYPE =~ darwin ]]
    then
        log_verbose linux only
        return
    fi
    local name="${1:-"Samba on $HOSTNAME"}"
    local protocol="${2:-"_smb"}"
    local port="${3:-445}"
    local text="${4:-""}"
    if ! pgrep "avahi-publish-service $name $protocol $port $text"
    then
        avahi-publish-service "$name" "$protocol" "$port" "$text" &
    fi
}

# avahi_publish_temp_stop name type port text
avahi_publish_stop() {
    if [[ $OSTYPE =~ darwin ]]
    then
        log_verbose linux only
        return
    fi
    local name="${1:-"Samba on $HOSTNAME"}"
    local protocol="${2:-"_smb"}"
    local port="${3:-445}"
    local text="${4:-""}"
    pkill avahi-public-service $name $protocol $port $text
}
