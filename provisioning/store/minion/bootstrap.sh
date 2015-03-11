#! /bin/bash

KARAF_VERSION=2.4.0
KARAF_ARCHIVE=apache-karaf-${KARAF_VERSION}.tar.gz
KARAF_DIR=apache-karaf-${KARAF_VERSION}
KARAF_DOWNLOAD_URL=http://mirror.synyx.de/apache/karaf/${KARAF_VERSION}

source /opt/provisioning/shared/utils.sh

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

# create swap file of 2GB (block size 1MB)
/bin/dd if=/dev/zero of=/swapfile bs=1M count=2K
/sbin/mkswap /swapfile
/sbin/swapon /swapfile
/bin/echo '/swapfile          swap            swap    defaults        0 0' >> /etc/fstab

# Install
apt-get update
apt-get install -y openjdk-7-jre
apt-get install -y snmp
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
waitForPort 8101 || exit 1

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
waitForPort 8101 || exit 1

# Register with "central" opennms
export SMNNEPO_HOME="/opt/apache/${KARAF_DIR}"
export OPENNMS="http://172.16.0.253:8980"
export USERNAME=admin
export PASSWORD=admin
export LOCATION=store$1
export SCRIPTDIR="$OPENNMS/smnnepo"

echo -n "Configuring root instance: URL: $OPENNMS, Location: $LOCATION: "
"$SMNNEPO_HOME"/bin/client -a 8101 -r 30 "source" "$SCRIPTDIR/smnnepo-setup.karaf" root "\"$USERNAME\"" "\"$PASSWORD\"" "\"$OPENNMS\"" "\"$LOCATION\""

"$SMNNEPO_HOME"/bin/admin list | grep '^\[' | sed 's#[][/]# #g' | while read LINE; do
        PORT=`echo "$LINE" | awk '{print $1}'`
        INSTANCE=`echo "$LINE" | awk '{print $6}'`

        # Configure all instances except root
        if [ "$INSTANCE" != "root" ]; then
                echo -n "Configuring subinstance $INSTANCE: "
                "$SMNNEPO_HOME"/bin/client -r 10 -a $PORT "source" "\"$SCRIPTDIR/smnnepo-setup.karaf\"" $INSTANCE "\"$USERNAME\"" "\"$PASSWORD\"" "\"$OPENNMS\"" "\"$LOCATION\"" >> /tmp/smnnepo.log 2>&1
                 RETVAL="$?"

                if [ $RETVAL -eq 0 ]; then
                        echo "OK"
                else
                        echo "FAILED. See /tmp/smnnepo.log for details."
                        exit $RETVAL
                fi
        fi
done
