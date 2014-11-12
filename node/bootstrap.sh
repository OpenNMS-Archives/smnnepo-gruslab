#! /bin/bash

echo "STORE $1 NODE $2 BOOTSTRAPPING!!!!!"

# Configure routes
cat > /etc/network/if-up.d/route-add << EOF
#!/bin/sh
ip route add 192.168.0.0/24 via 192.168.$1.1
EOF

chmod 755 /etc/network/if-up.d/route-add

ip route add 192.168.0.0/24 via 192.168.$1.1
