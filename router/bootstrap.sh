#! /bin/bash

echo "ROUTER BOOTSTRAPPING!!!!!"

# No questions from apt
export DEBIAN_FRONTEND=noninteractive

# Install service for restoring firewall rules
apt-get -q -y install iptables-persistent

# Configure IP forwarding
tee /etc/sysctl.d/99-ip_forward.conf << EOF |
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
sysctl -p -


# Configure firewall
## By default nothing can pass through
iptables -P FORWARD DROP
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT

## DPAT to the NOC network
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE

## Allow anything on local loopback
iptables -A INPUT -i lo -j ACCEPT

## Allow answers on established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

## Accept ICMP-Echo and SSH to router
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

## For each store...
for x in $(seq 2 $((2 + $1))); do
  ### Allow connections from store to NOC network
  iptables -A FORWARD -i "eth${x}" -o "eth1" -j ACCEPT

  ### Allow answers on established connections
  iptables -A FORWARD -i "eth1" -o "eth${x}" -m state --state ESTABLISHED,RELATED -j ACCEPT
done

# Save the firewall state
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

