#!/bin/sh
sshpass -p admin \
    ssh -o StrictHostKeyChecking=no \
        -p 8101 admin@localhost \
        'source http://localhost:8980/smnnepo/opennms-setup.karaf'

#sshpass -p admin ssh -o StrictHostKeyChecking=no -p 8101 admin@localhost 'features:install sample-storage-rrd'
