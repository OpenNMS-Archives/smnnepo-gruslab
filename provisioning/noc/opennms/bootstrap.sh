#! /bin/bash

echo "NOC OPENNMS BOOTSTRAPPING!!!!!"

# No questions from apt
export DEBIAN_FRONTEND=noninteractive

# Configure routes
cat > /etc/network/if-up.d/route-add << EOF
#!/bin/sh
ip route add 172.16.0.0/16 via 10.10.10.1
EOF

chmod 755 /etc/network/if-up.d/route-add

ip route add 172.16.0.0/16 via 10.10.10.1
