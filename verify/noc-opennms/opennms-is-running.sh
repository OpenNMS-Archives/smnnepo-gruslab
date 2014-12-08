source /opt/provisioning/shared/utils.sh

if ! checkPort 8101; then
    echo "Port 8101 is not available."
    exit 1
fi

if ! checkPort 8980; then
    echo "Port 8980 is not available."
    exit 1
fi