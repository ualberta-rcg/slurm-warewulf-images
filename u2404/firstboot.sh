#!/bin/bash
#set -e

# Log everything we do
exec 1> >(logger -s -t $(basename $0)) 2>&1

echo "Starting first boot configuration..."

DEBIAN_FRONTEND=noninteractive

# Setup System
for playbook in $(ls /etc/ansible/playbook/*.yaml | sort); do
    ansible-playbook "$playbook"
done

rm /etc/systemd/system/firstboot.service
#rm -- "$0"
systemctl daemon-reload

echo "First boot configuration complete"
