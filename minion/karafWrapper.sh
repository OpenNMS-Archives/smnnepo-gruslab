#!/bin/sh

sshpass -p karaf \
    ssh -o StrictHostKeyChecking=no \
        -p 8101 karaf@localhost \
        'source file:///opt/provisioning/smnnepo-setup.karaf admin admin http://192.168.0.2:8980 store$1'