# bungee_ip_blacklist
A quick program to scrape bungee logs for possible DDOS addresses.

## Reasoning
I started this project due to the occasional DDOS attack on a Minecraft Server I help maintain. The general idea is that there are two variants of the program to be used in different scenarios.

One that can be used in a low CPU/low Memory environment, at the cost of taking an average of 4 times as long. The other is structured in such a way that it can crunch through millions of lines of logs in seconds, at the cost of more resources.

The emerg.sh file is the low-cost variant, with the intent being a quick response for a proxy-server to attempt to elevate an ongoing attack, while the logs are sent to better hardware to be processed and have a blacklist sent back.

possibly_bad.sh is a script that uses ipset and iptables to block entire country-blocks of IP addresses, sourced from the [IP Deny Website](https://www.ipdeny.com/ipblocks/). The list of countries can be easily changed by swapping out the wget URLs.

## Where do I plan to go next?
I’m planning on creating a Discord bot that can be added to an admin server/channel that can be used to react to an ongoing attack.
Additionally I’ll be writing up a script that can offload the mass-compute aspect of the program.
