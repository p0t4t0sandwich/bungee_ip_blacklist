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

# Gathering lists for:
# ar.zone ARGENTENA
# bd.zone BANGLADESH
# bg.zone BULGARIA
# br.zone BRAZIL
# by.zone BELARUS
# cn.zone CHINA
# co.zone COLOMBIA
# il.zone ISRAEL
# in.zone INDIA
# ir.zone IRAN
# kp.zone N-KOREA
# ly.zone LIBYAN
# mn.zone MONGOLIA
# mu.zone MAURITIUS
# pa.zone PANAMA
# sd.zone SUDAN
# tw.zone TAIWAN
# ua.zone UKRAINE
# ro.zone ROMANIA
# ru.zone RUSSIA
# ve.zone VENEZUELA
# vn.zone VIET NAM
mkdir -p country_blocklists
(
    cd country_blocklists
    wget --no-check-certificate https://www.ipdeny.com/ipblocks/data/countries/ar.zone
    wget --no-check-certificate https://www.ipdeny.com/ipblocks/data/countries/bd.zone
    wget --no-check-certificate https://www.ipdeny.com/ipblocks/data/countries/bg.zone
    wget --no-check-certificate https://www.ipdeny.com/ipblocks/data/countries/br.zone
    wget --no-check-certificate https://www.ipdeny.com/ipblocks/data/countries/by.zone
    wget --no-check-certificate https://www.ipdeny.com/ipblocks/data/countries/cn.zone
    wget --no-check-certificate https://www.ipdeny.com/ipblocks/data/countries/co.zone
    wget --no-check-certificate https://www.ipdeny.com/ipblocks/data/countries/il.zone
    wget --no-check-certificate https://www.ipdeny.com/ipblocks/data/countries/in.zone
    wget --no-check-certificate https://www.ipdeny.com/ipblocks/data/countries/ir.zone
    wget --no-check-certificate https://www.ipdeny.com/ipblocks/data/countries/kp.zone
    wget --no-check-certificate https://www.ipdeny.com/ipblocks/data/countries/ly.zone
    wget --no-check-certificate https://www.ipdeny.com/ipblocks/data/countries/mn.zone
    wget --no-check-certificate https://www.ipdeny.com/ipblocks/data/countries/mu.zone
    wget --no-check-certificate https://www.ipdeny.com/ipblocks/data/countries/pa.zone
    wget --no-check-certificate https://www.ipdeny.com/ipblocks/data/countries/sd.zone
    wget --no-check-certificate https://www.ipdeny.com/ipblocks/data/countries/tw.zone
    wget --no-check-certificate https://www.ipdeny.com/ipblocks/data/countries/ua.zone
    wget --no-check-certificate https://www.ipdeny.com/ipblocks/data/countries/ro.zone
    wget --no-check-certificate https://www.ipdeny.com/ipblocks/data/countries/ru.zone
    wget --no-check-certificate https://www.ipdeny.com/ipblocks/data/countries/ve.zone
    wget --no-check-certificate https://www.ipdeny.com/ipblocks/data/countries/vn.zone
)

## Blocking bad IPs

cat country_blocklists/* | sed 's/^/add country_blocklist /' | sed -e 's/$/ -exist/' > country_blocklist

grep "country_blocklist" /etc/iptables/rules.v4 &>/dev/null
if [[ $? -eq 1 ]]
then
    # Create blacklist with ipset utility
    ipset create country_blocklist hash:net hashsize 4096

    # Set up iptables rules. Match with blacklist and drop traffic
    iptables -I INPUT -m set --match-set country_blocklist src -j DROP
    iptables -I FORWARD -m set --match-set country_blocklist src -j DROP
fi
ipset restore < country_blocklist

## Save new config
iptables-save > /etc/iptables/rules.v4

rm country_blocklist
rm -r country_blocklists/