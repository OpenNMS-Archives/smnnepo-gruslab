#! /bin/bash
OPENNMS_HOME=/opt/opennms
JDK_ZIP="jdk-7u71-linux-x64.tar.gz"
JDK_DIR="jdk1.7.0_71"
DOWNLOAD_URL="http://ea6566d40c07b47034b0-1800c102c9a9eeb4a8314a4974feca8c.r88.cf2.rackcdn.com"
OPENNMS_RELEASE="stable"
JAVA_HOME="/opt/java/oracle/$JDK_DIR/bin/java"
LOCAL_SETUP=1

echo "OPENNMS BOOTSTRAPPING!!!!!"
echo "OPENNMS HOME:"${OPENNMS_HOME}
echo "JDK ZIP:"${JDK_ZIP}
echo "JDK Directory:"${JDK_DIR}
echo "Download location:"${DOWNLOAD_URL}
echo "OpenNMS Release:"${OPENNMS_RELEASE}

# we need an opennms tar.gz file
if [ ! -f /opt/provisioning/opennms.tar.gz ]; then
    echo "There is no opennms.tar.gz file located in /opt/provisioning."
    exit 1
fi

# create swap file of 2GB (block size 1MB)
/bin/dd if=/dev/zero of=/swapfile bs=1024 count=2097152
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



# TODO this is the old way of installing debian packages manually. I keep it for now, but it may be removed later
#if [ $LOCAL_SETUP == 1 ]; then
#    echo "Installing OpenNMS from local debian packages"
#    apt-get install -y libdbd-pg-perl libdbi-perl libgetopt-mixed-perl
#    #apt-get install -y default-mta # TODO do we need this?
#    apt-get install -y heirloom-mailx
#
#    dpkg -i libopennms-java_*_all.deb
#    dpgk -i libopennmsdeps-java_*_all.deb
#
#    dpkg -i opennms-common_*_all.deb
#    dpkg -i opennms-contrib_*_all.deb
#    #dpkg -i opennms-db_*_.deb # we do not need this to be installed
#    dpkg -i opennms-doc_*_all.deb
#    dpkg -i opennms-jmx-config-generator_*_all.deb
#    dpkg -i opennms-server_*_all.deb
#    dpkg -i opennms-webapp-jetty_*_all.deb
#    dpkg -i opennms-ncs_*_all.deb
#    dpkg -i opennms-plugin-protocol-radius_*_all.deb
#    dpkg -i opennms-plugin-protocol-xml_*_all.deb
#    dpkg -i opennms-plugin-protocol-xmp_*_all.deb
#    dpkg -i opennms-plugin-protocol-cifs_*_all.deb
#    dpkg -i opennms-plugin-protocol-dhcp_*_all.deb
#    dpkg -i opennms-plugin-provisioning-dns_*_all.deb
#    dpkg -i opennms-plugin-provisioning-link_*_all.deb
#    dpkg -i opennms-plugin-provisioning-map_*_all.deb
#    dpkg -i opennms-plugin-provisioning-rancid_*_all.deb
#    dpkg -i opennms-plugin-provisioning-snmp-asset_*_all.deb
#    dpkg -i opennms-plugin-provisioning-snmp-hardware-inventory_*_all.deb
#    dpkg -i opennms-plugin-ticketer-jira_*_all.deb
#    dpkg -i opennms-plugin-ticketer-otrs_*_all.deb
#    dpkg -i opennms-plugin-ticketer-rt_*_all.deb
#    dpkg -i opennms-plugin-collector-vtdxml-handler_*_all.deb
#    dpkg -i opennms-plugin-collector-juniper-tca_*_all.deb
#    dpkg -i opennms-plugins_*_all.deb
#    dpkg -i opennms_*_all.deb

#else
#    apt-get install -y opennms
#    echo "Not yet implemented"
#    exit 3
#fi

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

${OPENNMS_HOME}/bin/runjava -S ${JAVA_HOME}
${OPENNMS_HOME}/bin/install -dis

# Start OpenNMS
${OPENNMS_HOME}/bin/opennms start
