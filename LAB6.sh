#!/bin/bash
# ------------------------------------------------------------------
# By Milan Formanek 	LAB6 Deployment Script
# ------------------------------------------------------------------
VERSION=0.1.0
SUBJECT=some-unique-id
USAGE="Run on the individual DM machines with the letter name of the machine as the parameter."

if [ $# == 0 ] ; then
    echo $USAGE
    exit 1;
fi

if [ $1 == "OFF" ] ; then #ENABLE EVERITHING IN IPTABLES for testing
    iptables -P INPUT ACCEPT 
    iptables -P FORWARD ACCEPT 
    iptables -P OUTPUT ACCEPT
    iptables -F #reset IPTABLES
    service iptables save # make sure to save rules!!! 
    exit 1;
fi

iptables -F #reset IPTABLES

iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT #Allow return packets for ESTABLISHED and RELATED packets

iptables -P INPUT DROP # set default DROP policy 
iptables -P OUTPUT ACCEPT

iptables -A INPUT -i lo -j ACCEPT  #Allow loopback traffic
iptables -A OUTPUT -o lo -j ACCEPT

iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
iptables -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT
iptables -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT #ACCEPT ICMP packets.

if [ $1 != "E" ] ; then
	iptables -A INPUT -p tcp -s  100.64.0.0/16 --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A INPUT -p tcp -s  10.21.32.0/24 --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A INPUT -p tcp -s  198.18.0.0/16 --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A OUTPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
	#On all machines exlcuding E allow inbound ssh connections from the 100.64.0.0/16, 10.21.32.0/24, and 198.18.0.0/16 subnets
fi

if [ $1 != "A" ] ; then
	iptables -P FORWARD DROP #disble forwarding on non routers
else #RULES FOR ROUTER/MACHINE A
    	iptables -P FORWARD DROP #enable forwarding on routers
    	iptables -A FORWARD -s 157.240.28.35 -j DROP
    	iptables -A FORWARD -d 157.240.28.35 -j DROP #block FACEBOOK
    	iptables -A FORWARD -s 216.176.177.74 -j DROP
    	iptables -A FORWARD -d 216.176.177.74 -j DROP #block CHEESEBURGER.com
    
    	iptables -A FORWARD -p tcp -s  100.64.0.0/16 --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A FORWARD -p tcp -s  10.21.32.0/24 --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A FORWARD -p tcp -s  198.18.0.0/16 --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
    	iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT #FORWARD SSH
	
	iptables -A FORWARD -p tcp --dport 80 -d 100.64.21.0/24  -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
	iptables -A FORWARD -p tcp --dport 443 -d 100.64.21.0/24 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT 
	iptables -A FORWARD -p tcp --sport 80 -s 100.64.21.0/24  -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
	iptables -A FORWARD -p tcp --sport 443 -s 100.64.21.0/24 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT 
	
	iptables -A FORWARD -p icmp --icmp-type echo-request -j ACCEPT
	iptables -A FORWARD -p icmp --icmp-type echo-reply -j ACCEPT
	iptables -A FORWARD -p icmp --icmp-type time-exceeded -j ACCEPT
	iptables -A FORWARD -p icmp --icmp-type destination-unreachable -j ACCEPT #ACCEPT ICMP packets
	

	iptables -A FORWARD -p udp --sport 1024:65535 --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A FORWARD -p udp --sport 53 --dport 1024:65535 -m state --state ESTABLISHED -j ACCEPT
	iptables -A FORWARD -p udp --sport 53 --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A FORWARD -p udp --sport 53 --dport 53 -m state --state ESTABLISHED -j ACCEPT 
	#allow inbound DNS lookup on chase
	
	

	iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT #Allow return packets for ESTABLISHED and RELATED packets
	

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
	SERVER_IP="100.64.21.4"
	iptables -A INPUT -p udp -s 0/0 --sport 1024:65535 -d $SERVER_IP --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A OUTPUT -p udp -s $SERVER_IP --sport 53 -d 0/0 --dport 1024:65535 -m state --state ESTABLISHED -j ACCEPT
	iptables -A INPUT -p udp -s 0/0 --sport 53 -d $SERVER_IP --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A OUTPUT -p udp -s $SERVER_IP --sport 53 -d 0/0 --dport 53 -m state --state ESTABLISHED -j ACCEPT 
	#allow inbound DNS lookup on chase.
fi

if [ $1 == "E" ] ; then #RULES FOR MACHINE E - FILE SERVER
	iptables -A INPUT -p tcp -s 10.21.32.0/24 --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A OUTPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT #enable SSH connections only from 10.21.32.0/24 net
	
	iptables -A INPUT -m state --state NEW -p udp --dport 137 -j ACCEPT
	iptables -A INPUT -m state --state NEW -p udp --dport 138 -j ACCEPT
	iptables -A INPUT -m state --state NEW -p tcp --dport 139 -j ACCEPT
	iptables -A INPUT -m state --state NEW -p tcp --dport 445 -j ACCEPT
	#allow incoming connections for CIFS and SMB
fi

service iptables save # make sure to save rules!!! 
