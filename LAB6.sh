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

if [ $1 == "OFF" ] ; then #ENABLE EVERITHING IN IPTABLES
    iptables -P INPUT ACCEPT 
    iptables -P FORWARD ACCEPT 
    iptables -P OUTPUT ACCEPT
    iptables -F #reset IPTABLES
    service iptables save # make sure to save rules!!! 
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
	iptables -A INPUT -p tcp -s  100.64.0.0/16 --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A INPUT -p tcp -s  10.21.32.0/24 --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A INPUT -p tcp -s  198.18.0.0/16 --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A OUTPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
	#On all machines exlcuding E allow inbound ssh connections from the 100.64.0.0/16, 10.21.32.0/24, and 198.18.0.0/16 subnets.
fi

if [ $1 != "A" ] ; then
	iptables -P FORWARD DROP #disble forwarding on non routers
else #RULES FOR ROUTER/MACHINE A
    iptables -P FORWARD ACCEPT #enable forwarding on routers
    iptables -A FORWARD -s 157.240.28.35 -j DROP
    iptables -A FORWARD -d 157.240.28.35 -j DROP #block FACEBOOK
    iptables -A FORWARD -s 216.176.177.74 -j DROP
    iptables -A FORWARD -d 216.176.177.74 -j DROP #block CHEESEBURGER.com
    
    	iptables -A FORWARD -p tcp -s  100.64.0.0/16 --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A FORWARD -p tcp -s  10.21.32.0/24 --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A FORWARD -p tcp -s  198.18.0.0/16 --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
    	iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT #FORWARD SSH
	
	iptables -A FORWARD -p tcp --dport 80 -d 100.64.21.2 -j ACCEPT
	iptables -A FORWARD -p tcp --dport 443 -d 100.64.21.2 -j ACCEPT #forward http and https to machine B
	iptables -A FORWARD -p tcp --dport 80 -d 100.64.21.5 -j ACCEPT
	iptables -A FORWARD -p tcp --dport 443 -d 100.64.21.5 -j ACCEPT #forward http and https to machine F
fi

if [ $1 == "B" ] || [ $1 == "F" ] ; then #RULES FOR MACHINE B AND F
	iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT #allow http and https inbound traffic
fi

if [ $1 == "C" ] ; then #RULES FOR MACHINE C
	iptables -P OUTPUT DROP #defaul output drop
	
	iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT #allow related connections
	
	iptables -A OUTPUT -p udp -d 100.64.21.4 --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A INPUT  -p udp -s 100.64.21.4 --sport 53 -m state --state ESTABLISHED     -j ACCEPT
	iptables -A OUTPUT -p tcp -d 100.64.21.4 --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A INPUT  -p tcp -s 100.64.21.4 --sport 53 -m state --state ESTABLISHED     -j ACCEPT #allow DNS lookup on chase
	
	iptables -A OUTPUT -p tcp -m tcp --dport 80 -j ACCEPT
	iptables -A OUTPUT -p tcp -m tcp --dport 443 -j ACCEPT #allow outbound http and https traffic
	
	iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT #allow outgoing ssh
	
	iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT
	iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT
	iptables -A OUTPUT -p icmp --icmp-type time-exceeded -j ACCEPT
	iptables -A OUTPUT -p icmp --icmp-type destination-unreachable -j ACCEPT #ACCEPT outbound ICMP packets #allow outgoing ICMP
	
	iptables -A OUTPUT -p tcp --sport 21 -m state --state ESTABLISHED -j ACCEPT
	iptables -A OUTPUT -p tcp --sport 20 -m state --state ESTABLISHED,RELATED -j ACCEPT
	iptables -A OUTPUT -p tcp --sport 1024: --dport 1024: -m state --state ESTABLISHED -j ACCEPT
	iptables -A INPUT -p tcp --dport 21 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A INPUT -p tcp --dport 20 -m state --state ESTABLISHED -j ACCEPT
	iptables -A INPUT -p tcp --sport 1024: --dport 1024: -m state --state ESTABLISHED,RELATED,NEW -j ACCEPT
	#FTP Rules
fi

if [ $1 == "D" ] ; then #RULES FOR MACHINE D - DNS SERVER
   	iptables -A OUTPUT -p udp  --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A INPUT  -p udp  --sport 53 -m state --state ESTABLISHED     -j ACCEPT
	iptables -A OUTPUT -p tcp  --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A INPUT  -p tcp  --sport 53 -m state --state ESTABLISHED     -j ACCEPT #allow inbound DNS lookup on chase
fi

service iptables save # make sure to save rules!!! 
