#!/bin/bash
# ------------------------------------------------------------------
# [Author] Title
#          Description
#
#          This script uses shFlags -- Advanced command-line flag
#          library for Unix shell scripts.
#          http://code.google.com/p/shflags/
#
# Dependency:
#     http://shflags.googlecode.com/svn/trunk/source/1.0/src/shflags
# ------------------------------------------------------------------
VERSION=0.1.0
SUBJECT=some-unique-id
USAGE="Usage: command -hv args"

if [ $# == 0 ] ; then
    echo $USAGE
    exit 1;
fi


iptables -F #reset IPTABLES

iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

iptables -P INPUT DROP # set default DROP policy 
iptables -P OUTPUT ACCEPT

iptables -A INPUT -i lo -j ACCEPT  #Allow loopback traffic
iptables -A OUTPUT -o lo -j ACCEPT

iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
iptables -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT
iptables -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT #ACCEPT ICMP packets

if [ $1 != "E" ] ; then
	iptables -A INPUT -i eth0 -p tcp -s  100.64.0.0/16 --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A INPUT -i eth0 -p tcp -s  10.21.32.0/24 --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A INPUT -i eth0 -p tcp -s  198.18.0.0/16 --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A OUTPUT -o eth0 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
	#On all machines exlcuding E allow inbound ssh connections from the 100.64.0.0/16, 10.21.32.0/24, and 198.18.0.0/16 subnets
fi

if [ $1 != "A" ] ; then
	iptables -P FORWARD DROP #disble forwarding on non routers
else
    iptables -P FORWARD ACCEPT #enable forwarding on routers
fi




service iptables save # make sure to save rules!!! 
