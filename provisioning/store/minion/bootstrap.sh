#! /bin/bash

echo "STORE $1 MINION BOOTSTRAPPING!!!!!"

# No questions from apt
export DEBIAN_FRONTEND=noninteractive

# Configure routes
cat > /etc/network/if-up.d/route-add << EOF
#!/bin/sh
ip route add 10.10.10.0/24 via 192.168.$1.1
EOF

chmod 755 /etc/network/if-up.d/route-add

ip route add 10.10.10.0/24 via 192.168.$1.1
