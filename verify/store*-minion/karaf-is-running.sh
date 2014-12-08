source /opt/provisioning/shared/utils.sh

if ! ps aux | grep -i '[k]araf' > /dev/null; then
    echo "Karaf is not running."
    exit 1
fi

if ! checkPort 8101; then
    echo "Port 8101 is not available."
    exit 1
fi