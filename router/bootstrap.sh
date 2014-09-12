#! /bin/bash

echo "ROUTER BOOTSTRAPPING!!!!!"

# Configure IP forwarding
tee /etc/sysctl.d/99-ip_forward.conf << EOF |
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
sysctl -p -


# Configure firewall
iptables -P FORWARD DROP
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT

iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE

iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

iptables -A FORWARD -i eth1 -o eth2 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth3 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth4 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -j ACCEPT
iptables -A FORWARD -i eth3 -o eth1 -j ACCEPT
iptables -A FORWARD -i eth4 -o eth1 -j ACCEPT
