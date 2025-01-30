#!/bin/bash
#set -e

# Log everything we do
exec 1> >(logger -s -t $(basename $0)) 2>&1

echo "Starting first boot configuration..."

SLURM_VERSION=24-05-5-1
PREFIX=/opt/software/slurm
PATH=/usr/local/ssl/bin:$PREFIX/bin:/opt/software/slurm/sbin:${PATH:-}
LD_LIBRARY_PATH=/usr/local/ssl/lib:${LD_LIBRARY_PATH:-}
NVIDIA_DRIVER_VERSION=535
NVIDIA_VISIBLE_DEVICES=all
NVIDIA_DRIVER_CAPABILITIES=compute,utility
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
    wget \
    curl \
    unzip \
    git \
    cron \
    libdbus-1-dev \
    locales \
    bash-completion \
    net-tools \
    openssh-server \
    openssh-client \
    gnupg \
    lsb-release \
    ca-certificates \
    rsync \
    cron \
    tzdata \
    tree \
    nano \
    vim \
    tmux \
    jq \
    linux-image-generic \
    systemd \
    sudo \
    libssl-dev \
    libcurl4-openssl-dev \
    libhwloc-dev \
    openmpi-bin \
    libopenmpi-dev \
    libnuma-dev \
    kmod \
    libpmix-dev \
    libevent-dev \
    libxml2-dev \
    numactl \
    prometheus-node-exporter \
    nfs-common \
    cockpit \
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
    openscap-scanner \
    netbase \
    ipmitool \
    rdma-core \
    build-essential \
    cmake \
    libhwloc15 \
    libtool \
    zlib1g-dev \
    liblua5.3-0 \
    libnuma1 \
    libpam0g \
    librrd8 \
    libyaml-0-2 \
    libjson-c5 \
    libhttp-parser2.9 \
    libev4 \
    libssl3 \
    libcurl4 \
    libbpf1 \
    libdbus-1-3 \
    libfreeipmi17 \
    libibumad3 \
    libibmad5 \
    libev-dev \
    gettext \
    linux-headers-generic \
    pkg-config \
    autoconf \
    automake \
    gcc \
    make \
    python3 \
    python3-pip \
    python3-venv \
    munge \
    libmunge-dev \
    libmunge2 \
    libpmix-bin \
    rrdtool \
    librrd-dev \
    libhdf5-dev \
    libmariadb-dev \
    libjson-c-dev \
    libyaml-dev \
    libpam0g-dev \
    libjwt-dev \
    lua5.3 \
    liblua5.3-dev \
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
ln -s /opt/slurm-job-exporter/slurm-job-exporter.py /usr/bin/slurm-job-exporter 
chmod +x /usr/bin/slurm-job-exporter

# Install Slurm Job Exporter Service
cp /opt/slurm-job-exporter/slurm-job-exporter.service /etc/systemd/system/slurm-job-exporter.service 
sed -i '/\[Service\]/a WorkingDirectory=/opt/slurm-job-exporter' /etc/systemd/system/slurm-job-exporter.service 
chmod 644 /etc/systemd/system/slurm-job-exporter.service 

# Configure and build Slurm with the additional features enabled
mkdir -p /usr/src && cd /usr/src && \
curl -LO https://github.com/SchedMD/slurm/archive/refs/tags/slurm-${SLURM_VERSION}.tar.gz && \
tar -xzf slurm-${SLURM_VERSION}.tar.gz && cd slurm-slurm-${SLURM_VERSION} && \
./configure --prefix=$PREFIX \
            --sysconfdir=/etc/slurm \
            --with-munge \
            --with-pmix \
            --with-hdf5 \
            --with-mysql \
            --enable-debug \
            --enable-pam \
            --enable-restd \
            --enable-lua \
            --enable-rrdtool \
            --enable-mpi 
            
make -j$(nproc) 
make install 
cd contribs 
make 
make install
touch /var/log/slurm/slurm-dbd.log
touch /var/log/slurm/slurmctld.log
mkdir /var/spool/slurmd
chown -R slurm:slurm /etc/slurm /var/spool/slurmctld /var/run/slurm /var/log/slurm /opt/software/slurm/sbin /var/spool/slurmd
echo "PATH=/opt/software/slurm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin" >> /etc/environment
echo 'export PATH="/opt/software/slurm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"' >> /etc/bash.bashrc

cat <<EOF > /etc/systemd/system/slurmd.service
[Unit]
Description=Slurm Node Daemon
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=slurm
Group=slurm
ExecStart=/opt/software/slurm/sbin/slurmd -D
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable munge
systemctl start munge
systemctl enable slurmd
systemctl start slurmd

# Zabbix Setup
sed 's#Server=.*#Server=192.168.1.0/24#' -i /etc/zabbix/zabbix_agentd.conf
service zabbix-agent restart

# Disable and cleanup
systemctl disable firstboot.service
rm /etc/systemd/system/firstboot.service
#rm -- "$0"

echo "First boot configuration complete"
