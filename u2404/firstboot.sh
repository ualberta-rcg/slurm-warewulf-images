#!/bin/bash
set -e

# Log everything we do
exec 1> >(logger -s -t $(basename $0)) 2>&1

echo "Starting first boot configuration..."

SLURM_VERSION=24-05-5-1
PREFIX=/opt/software/slurm

# Install CVMFS
apt-get update
apt-get upgrade
apt-get install -y cvmfs cvmfs-fuse3
apt update -y 
apt upgrade -y 
mkdir -p /var/run/nvidia-persistenced
echo "nvidia" >> /etc/modules 
echo "nvidia_uvm" >> /etc/modules

# Install the NVIDIA driver from Ubuntu repositories
apt-get install -y nvidia-driver-${NVIDIA_DRIVER_VERSION} nvidia-settings nvidia-prime

# Install NVIDIA utilities and libraries from Ubuntu repositories
RUN apt install -y libnvidia-compute-${NVIDIA_DRIVER_VERSION} libnvidia-gl-${NVIDIA_DRIVER_VERSION} nvidia-modprobe

# NVIDIA setup
nvidia-modprobe
nvidia-smi
depmod -a
modprobe nvidia

# Zabbix Setup
sed 's#Server=.*#Server=192.168.1.0/24#' -i /etc/zabbix/zabbix_agentd.conf

# Disable and cleanup
systemctl disable firstboot.service
rm /etc/systemd/system/firstboot.service
rm -- "$0"

echo "First boot configuration complete"
