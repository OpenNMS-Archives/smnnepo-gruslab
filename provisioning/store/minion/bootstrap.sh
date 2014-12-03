#! /bin/bash

KARAF_VERSION=2.4.0
KARAF_ARCHIVE=apache-karaf-${KARAF_VERSION}.tar.gz
KARAF_DIR=apache-karaf-${KARAF_VERSION}
KARAF_DOWNLOAD_URL=http://mirror.synyx.de/apache/karaf/${KARAF_VERSION}

echo "STORE $1 MINION BOOTSTRAPPING!!!!!"

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

# Install
apt-get update
apt-get install -y openjdk-7-jre
apt-get install -y sshpass

# Set JAVA_HOME
cp /opt/provisioning/set-java-home.sh /etc/profile.d/
source /etc/profile.d/set-java-home.sh
echo "JAVA_HOME=${JAVA_HOME}"

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

# we have to wait until the karaf port is available. This may take a while
# TODO use a function for this code. It is also used in opennms/bootstrap.sh
SUCCESS='nope'
for ((TIME=0; TIME<=300; TIME+=5)); do
    if ss -nltp | grep 8101 > /dev/null; then
        SUCCESS='yep'
        echo "Port 8101 available!"
        break
    fi
    echo "Waiting for port 8101 to become available."
    sleep 5
done
if [ "${SUCCESS}" != 'yep' ]; then
    echo "Port 8101 is not available. It is very likely that karaf was not able to start. Exiting..."
    exit 1
fi

# Register karaf as a service
sshpass -p karaf ssh -o StrictHostKeyChecking=no -p 8101 karaf@localhost << EOF
features:install -v wrapper
wrapper:install -D "Karaf Minion"
EOF
ln -s /opt/apache/${KARAF_DIR}/bin/karaf-service /etc/init.d/
update-rc.d karaf-service defaults

# We have to stop the running karaf and start the service instead
/opt/apache/${KARAF_DIR}/bin/stop
service karaf-service start

# TODO use a function for this code. It is also used in opennms/bootstrap.sh
SUCCESS='nope'
for ((TIME=0; TIME<=300; TIME+=5)); do
    if ss -nltp | grep 8101 > /dev/null; then
        SUCCESS='yep'
        echo "Port 8101 available!"
        break
    fi
    echo "Waiting for port 8101 to become available."
    sleep 5
done
if [ "${SUCCESS}" != 'yep' ]; then
    echo "Port 8101 is not available. It is very likely that karaf was not able to start. Exiting..."
    exit 1
fi

# register with "central" opennms
sshpass -p karaf ssh -o StrictHostKeyChecking=no -p 8101 karaf@localhost 'source file:///opt/provisioning/smnnepo-setup.karaf admin admin http://172.16.0.253:8980 store$1'
