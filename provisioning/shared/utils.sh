#!/bin/sh

function waitForPort {
    SUCCESS='nope'
    for ((TIME=0; TIME<=300; TIME+=5)); do
        if checkPort $1; then
            SUCCESS='yep'
            echo "Port $1 available!"
            break
        fi
        echo "Waiting for port $1 to become available."
        sleep 5
    done
    if [ "${SUCCESS}" != 'yep' ]; then
        echo "Port $1 is not available. Exiting..."
        exit 1
    fi
}

function checkPort {
    return $(ss -nltp | grep $1 > /dev/null)
}