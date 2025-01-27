#!/bin/bash
set -e

# Log everything we do
exec 1> >(logger -s -t $(basename $0)) 2>&1

echo "Starting first boot configuration..."

# Install CVMFS
apt-get update
apt-get install -y cvmfs cvmfs-fuse3

# NVIDIA setup
nvidia-modprobe
nvidia-smi
depmod -a
modprobe nvidia

# Add any other node setup here

# Disable and cleanup
systemctl disable firstboot.service
rm /etc/systemd/system/firstboot.service
rm -- "$0"

echo "First boot configuration complete"
