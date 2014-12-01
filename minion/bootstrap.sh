#! /bin/bash

KARAF_VERSION=2.4.0
KARAF_ARCHIVE=apache-karaf-${KARAF_VERSION}.tar.gz
KARAF_DIR=apache-karaf-${KARAF_VERSION}
KARAF_DOWNLOAD_URL=http://mirror.synyx.de/apache/karaf/${KARAF_VERSION}

echo "STORE $1 MINION BOOTSTRAPPING!!!!!"

# Configure routes
cat > /etc/network/if-up.d/route-add << EOF
#!/bin/sh
ip route add 192.168.0.0/24 via 192.168.$1.1
EOF

chmod 755 /etc/network/if-up.d/route-add
ip route add 192.168.0.0/24 via 192.168.$1.1

# Install
apt-get update
apt-get install -y openjdk-7-jre
apt-get install -y sshpass

# Download and extract Apache Karaf 2.3.9
echo "Downloading $KARAF_ARCHIVE from $KARAF_DOWNLOAD_URL"
mkdir -p /opt/apache
if [ ! -f /opt/apache/${KARAF_ARCHIVE} ]; then
    wget --no-verbose --output-document /opt/apache/${KARAF_ARCHIVE} ${KARAF_DOWNLOAD_URL}/${KARAF_ARCHIVE}
    cd /opt/apache
    md5sum -c /opt/provisioning/${KARAF_ARCHIVE}.md5
    if [ $? -ne 0 ]; then
        echo "The download of $KARAF_ARCHIVE failed."
        exit 1
    fi
fi
if [ ! -d /opt/apache/${KARAF_DIR} ]; then
    tar xvf /opt/apache/${KARAF_ARCHIVE} -C /opt/apache
fi

# start Karaf
/opt/apache/${KARAF_DIR}/bin/start

# TODO register karaf as a service

# register with "central" opennms
chmod +x /opt/provisioning/karafWrapper.sh
/opt/provisioning/karafWrapper.sh $1
