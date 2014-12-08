#!/bin/sh

function waitForPort {
    local SUCCESS=
    for ((TIME=0; TIME<=300; TIME+=5)); do
        if checkPort $1; then
            SUCCESS='yep'
            echo "Port $1 available!"
            break
        fi
        echo "Waiting for port $1 to become available."
        sleep 5
    done
    if [[ -z "${SUCCESS}" ]]; then
        echo "Port $1 is not available. Exiting..."
        return 1
    fi
}

function checkPort {
    ss -nltp | grep $1 > /dev/null
}