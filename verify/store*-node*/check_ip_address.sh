ifconfig eth1 | grep $(hostname |sed 's/store[0-9]*-node/192.168.0./g')
