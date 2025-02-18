#!/bin/bash
#set -e

# Log everything we do
exec 1> >(logger -s -t $(basename $0)) 2>&1

echo "Starting first boot configuration..."

SLURM_VERSION=24-05-5-1
PATH=/usr/local/ssl/bin:$PREFIX/bin:/opt/software/slurm/sbin:${PATH:-}
LD_LIBRARY_PATH=/usr/local/ssl/lib:${LD_LIBRARY_PATH:-}
DEBIAN_FRONTEND=noninteractive

# NVIDIA setup
nvidia-modprobe
nvidia-smi
depmod -a
modprobe nvidia

# Install CVMFS
wget https://cvmrepo.s3.cern.ch/cvmrepo/apt/cvmfs-release-latest_all.deb
dpkg --force-all -i cvmfs-release-latest_all.deb 
rm -f cvmfs-release-latest_all.deb

# Install Zabbix Agent
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.0+ubuntu24.04_all.deb
dpkg --force-all -i zabbix-release_latest_7.0+ubuntu24.04_all.deb
rm -f zabbix-release_latest_7.0+ubuntu24.04_all.deb

# Install System Dependencies and Upgrade
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install --install-recommends -y \
    libpmix-dev \
    libpmix2 \
    libopenmpi-dev \
    libopenmpi3 \
    openmpi-bin \
    golang \
    rsyslog \
    make \
    wget \
    curl \
    unzip \
    git \
    hwloc \
    libdbus-1-dev \
    locales \
    bash-completion \
    net-tools \
    sssd \
    gnupg \
    lsb-release \
    ca-certificates \
    rsync \
    tzdata \
    tree \
    nano \
    vim \
    tmux \
    jq \
    linux-image-generic \
    linux-headers-generic \
    systemd \
    sudo \
    openmpi-bin \
    kmod \
    numactl \
    htop \
    iftop \
    iotop \
    sysstat \
    lsof \
    strace \
    openssl \
    ethtool \
    iptables-persistent \
    iputils-ping \
    dnsutils \
    traceroute \
    tcpdump \
    apt-utils \
    systemd-sysv \
    dbus \
    pciutils \
    ifupdown \
    netbase \
    ipmitool \
    rdma-core \
    libdbus-1-3 \
    gettext \
    pkg-config \
    python3 \
    python3-pip \
    python3-venv \
    python3-psutil \
    prometheus-node-exporter \
    pcm \
    munge \
    rrdtool \
    zabbix-agent \
    cvmfs \
    cvmfs-fuse3

ln -sf /usr/bin/python3 /usr/local/bin/python3 
ln -sf /usr/bin/pip3 /usr/local/bin/pip3 
mkdir -p /var/run/munge /run/munge /var/lib/munge /var/log/munge /etc/munge /var/log/slurm/ /etc/slurm /var/spool/slurmctld /var/run/slurm
chown -R munge:munge /etc/munge /var/run/munge /var/lib/munge /var/log/munge /run/munge 
chmod 700 /var/lib/munge /var/run/munge 
chmod 755 /run/munge
echo "wwuser:wwpassword" | chpasswd
usermod -aG sudo wwuser
    
# Install Slurm Job Exporter 
mkdir -p /opt/slurm-job-exporter 
chown -R root:root /opt/slurm-job-exporter 
cd /opt/slurm-job-exporter 
git clone https://github.com/guilbaults/slurm-job-exporter.git . 
python3 -m venv /opt/slurm-job-exporter/venv 
/opt/slurm-job-exporter/venv/bin/pip install -r requirements.txt 
sed -i '1i#!/usr/bin/env python3' /opt/slurm-job-exporter/slurm-job-exporter.py
sed -i 's#/var/run#/run#' /opt/slurm-job-exporter/slurm-job-exporter.service
ln -s /opt/slurm-job-exporter/slurm-job-exporter.py /usr/bin/slurm-job-exporter 
chmod +x /usr/bin/slurm-job-exporter

# Install Slurm Job Exporter Service
cp /opt/slurm-job-exporter/slurm-job-exporter.service /etc/systemd/system/slurm-job-exporter.service 
sed -i '/\[Service\]/a WorkingDirectory=/opt/slurm-job-exporter' /etc/systemd/system/slurm-job-exporter.service 
chmod 644 /etc/systemd/system/slurm-job-exporter.service 

# Install Slurm
# Define keywords to exclude (whitelist for exclusion)
EXCLUDE_KEYWORDS=("slurmdbd" "slurmctld" "slurmrestd")

# Step 1: Generate the list of .deb files
ALL_DEBS=($(find /slurm-debs/ -maxdepth 1 -type f -name "*.deb"))

# Step 2: Filter out unwanted .deb files
INSTALL_LIST=()
for deb in "${ALL_DEBS[@]}"; do
    skip=false
    for keyword in "${EXCLUDE_KEYWORDS[@]}"; do
        if [[ "$deb" == *"$keyword"* ]]; then
            skip=true
            break
        fi
    done
    if [ "$skip" = false ]; then
        INSTALL_LIST+=("$deb")
    fi
done

# Step 3: Display the list of packages to be installed
echo "The following .deb files will be installed:"
printf '%s\n' "${INSTALL_LIST[@]}"

# Step 4: Install the selected .deb packages
if [ "${#INSTALL_LIST[@]}" -gt 0 ]; then
    apt-get install -y "${INSTALL_LIST[@]}"
else
    echo "No .deb packages to install."
fi

# Setup Prometheus Slurm Exporter
cd /opt
git clone https://github.com/guilbaults/prometheus-slurm-exporter.git
cd prometheus-slurm-exporter
make build
cp bin/prometheus-slurm-exporter /usr/sbin/
#rm -rf /opt/prometheus-slurm-exporter

# Install Nvidia EnRoot
cd /tmp
curl -fSsL https://github.com/NVIDIA/enroot/releases/download/v3.4.1/enroot_3.4.1-1_$(dpkg --print-architecture).deb -o enroot.deb
apt-get install -y ./enroot.deb 
rm enroot.deb

# Install Nvidia Pyxis
cd /opt
git clone https://github.com/NVIDIA/pyxis
cd pyxis
make install

mkdir -p /var/spool/slurmd
chown -R slurm:slurm /var/spool/slurmd

timedatectl set-timezone America/Edmonton

systemctl daemon-reload
systemctl enable munge
systemctl start munge
systemctl enable slurmd
systemctl start slurmd
systemctl enable slurm-job-exporter
systemctl start slurm-job-exporter
systemctl enable pcm-sensor-server
systemctl start pcm-sensor-server
systemctl enable prometheus-slurm-exporter
systemctl start prometheus-slurm-exporter

# Zabbix Setup
sed 's#Server=.*#Server=192.168.1.0/24#' -i /etc/zabbix/zabbix_agentd.conf
service zabbix-agent restart

# CVMFS Setup
cvmfs_config setup
cvmfs_config probe

# Disable and cleanup
systemctl disable firstboot.service

# Remove Stuff
rm -rf /NVIDIA-Linux*
rm -rf /*.sh
rm -rf /*.xml
rm -rf /usr/src/*
rm -rf /slurm-debs

apt-get remove make cmake golang -y
apt autoremove -y
apt autoclean -y

rm /etc/systemd/system/firstboot.service
#rm -- "$0"

echo "First boot configuration complete"
