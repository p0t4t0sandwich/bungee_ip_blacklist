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

zgrep "Query - Incorrect magic" /root/waterfall/logs/latest.log | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | grep -v -e "^0" -e "255.255.255.255" -e "0.0.0.0" -e "8.8.8.8" -e "1.1.1.1" -e "1.0.0.1" -e "127.0.0.1" | sort -u | sed 's/^/add emerg /' | sed -e 's/$/ -exist/' > emerg

grep "emerg" /etc/iptables/rules.v4 &>/dev/null
if [[ $? -eq 1 ]]
then
    # Create blacklist with ipset utility
    ipset create emerg hash:ip hashsize 4096

    # Set up iptables rules. Match with blacklist and drop traffic
    iptables -I INPUT -m set --match-set emerg src -j DROP
    iptables -I FORWARD -m set --match-set emerg src -j DROP

    iptables-save > /etc/iptables/rules.v4
fi
ipset restore < emerg
