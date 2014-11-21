#! /bin/bash

echo "STORE $1 NODE $2 BOOTSTRAPPING!!!!!"

# No questions from apt
export DEBIAN_FRONTEND=noninteractive

# Configure routes
cat > /etc/network/if-up.d/route-add << EOF
#!/bin/sh
ip route add 10.10.10.0/24 via 192.168.0.254
ip route add 172.16.0.0/24 via 192.168.0.254
EOF

chmod 755 /etc/network/if-up.d/route-add

ip route add 10.10.10.0/24 via 192.168.0.254
ip route add 172.16.0.0/24 via 192.168.0.254
