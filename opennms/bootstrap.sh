#! /bin/bash
OPENNMS_HOME=/opt/opennms
JDK_ZIP="jdk-7u71-linux-x64.tar.gz"
JDK_DIR="jdk1.7.0_71"
DOWNLOAD_URL="http://ea6566d40c07b47034b0-1800c102c9a9eeb4a8314a4974feca8c.r88.cf2.rackcdn.com"
OPENNMS_RELEASE="stable"
JAVA_HOME="/opt/java/oracle/${JDK_DIR}"
JAVA_BIN="${JAVA_HOME}/bin/java"
LOCAL_SETUP=1

echo "OPENNMS BOOTSTRAPPING!!!!!"
echo "OPENNMS HOME:"${OPENNMS_HOME}
echo "JDK ZIP:"${JDK_ZIP}
echo "JDK Directory:"${JDK_DIR}
echo "Download location:"${DOWNLOAD_URL}
echo "OpenNMS Release:"${OPENNMS_RELEASE}

# we need an opennms.tar.gz file
if [ ! -f /opt/provisioning/opennms.tar.gz ]; then
    echo "There is no opennms.tar.gz file located in /opt/provisioning."
    exit 1
fi

# we need a smnnepo.war file
if [ ! -f /opt/provisioning/smnnepo.war ]; then
    echo "There is no smnnepo.war file located in /opt/provisioning."
    exit 1
fi

# create swap file of 2GB (block size 1MB)
/bin/dd if=/dev/zero of=/swapfile bs=1M count=2K
/sbin/mkswap /swapfile
/sbin/swapon /swapfile
/bin/echo '/swapfile          swap            swap    defaults        0 0' >> /etc/fstab

# Fix possible perl:warning: Setting locale failed error
locale-gen de_DE de_DE.UTF-8
dpkg-reconfigure locales

# Add OpenNMS Repository. We need this for icmp/icmp6 and opennms itself
cat << EOF | tee /etc/apt/sources.list.d/opennms.list
# contents of /etc/apt/sources.list.d/opennms.list
deb http://debian.opennms.org ${OPENNMS_RELEASE} main
deb-src http://debian.opennms.org ${OPENNMS_RELEASE} main
EOF

# Download and add the opennms PGP key
wget -O - http://debian.opennms.org/OPENNMS-GPG-KEY | sudo apt-key add -

apt-get update;
apt-get install -y tree vim
apt-get install -y jicmp jicmp6
apt-get install -y openjdk-7-jre
apt-get install -y sshpass

# Install and Configure Postgresql
apt-get install -y postgresql postgresql-contrib
PG_VERSION=`pg_lsclusters -h | head -n 1 | cut -d' ' -f1`
echo "You are running PostgresSQL Version $PG_VERSION"
cp /opt/provisioning/pg_hba.conf.template /etc/postgresql/${PG_VERSION}/main/pg_hba.conf
service postgresql restart

# Download and extract Oracle JDK 7
echo "Downloading $JDK_ZIP from $DOWNLOAD_URL"
mkdir -p /opt/java/oracle
if [ ! -f /opt/java/oracle/${JDK_ZIP} ]; then
    wget --no-verbose --output-document /opt/java/oracle/${JDK_ZIP} ${DOWNLOAD_URL}/${JDK_ZIP}
fi
if [ ! -d /opt/java/oracle/${JDK_DIR} ]; then
    tar xvf /opt/java/oracle/${JDK_ZIP} -C /opt/java/oracle
fi

# Configure OpenNMS
rm -rf ${OPENNMS_HOME}
mkdir -p ${OPENNMS_HOME}
tar xvf /opt/provisioning/opennms.tar.gz -C ${OPENNMS_HOME}

${OPENNMS_HOME}/bin/runjava -S ${JAVA_BIN}
${OPENNMS_HOME}/bin/install -dis

# Copy the smnnepo server components to opennms
cp /opt/provisioning/smnnepo.war ${OPENNMS_HOME}/jetty-webapps

# Overwrite some default config parameters
cp /opt/provisioning/opennms.conf ${OPENNMS_HOME}/etc

# set JAVA_HOME in opennms.conf
cat << EOF | tee -a ${OPENNMS_HOME}/etc/opennms.conf

JAVA_HOME=${JAVA_HOME}
EOF

# Register OpenNMS as a service
cp /opt/provisioning/opennms-server.opennms.init /etc/init.d/opennms
chmod +x /etc/init.d/opennms
update-rc.d opennms defaults

# Start OpenNMS
/etc/init.d/opennms start

# we have to wait until the karaf port is available. This may take a while
# TODO use a function for this code. It is also used in minion/bootstrap.sh
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

# Setup Minion Server
sshpass -p admin ssh -o StrictHostKeyChecking=no -p 8101 admin@localhost 'source http://localhost:8980/smnnepo/opennms-setup.karaf'
#sshpass -p admin ssh -o StrictHostKeyChecking=no -p 8101 admin@localhost 'features:install sample-storage-rrd'
