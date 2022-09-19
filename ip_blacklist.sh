#!/bin/bash

# Error handling
#set -o errexit
# Last excecuted command
#trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# Print an error message before exiting
#trap 'echo "\"${last_command}\" command failed with exit code $?."' EXIT

# Root check function
root_check() {
    if [ "$EUID" -ne 0 ]
    then
    echo "Please run as root"
    exit
    fi
}

# Root Check
root_check

## Dependancies
dpkg --list | grep ipset &>/dev/null
if [[ $? -eq 1 ]]
then
    apt-get install -y ipset
fi

dpkg --list | grep iptables-persistent &>/dev/null
if [[ $? -eq 1 ]]
then
    apt-get install -y iptables-persistent
fi

## Blocking bad IPs
for i in blocklists/*; do
    g=${i#"blocklists/"}
    t=${g#"/"}
    grep $t /etc/iptables/rules.v4 &>/dev/null
    if [[ $? -eq 1 ]]
    then
        # Create blacklist with ipset utility
        ipset create $t hash:ip hashsize 4096

        # Set up iptables rules. Match with blacklist and drop traffic
        iptables -I INPUT -m set --match-set $t src -j DROP
        iptables -I FORWARD -m set --match-set $t src -j DROP
    fi
    ipset restore < $i
done

## Save new config
iptables-save > /etc/iptables/rules.v4