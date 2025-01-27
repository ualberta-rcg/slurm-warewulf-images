#FROM nvidia/cuda:12.6.3-base-ubuntu24.04
FROM ubuntu:24.10

# Environment settings
ENV DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_DRIVER_VERSION=535
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# Temporarily disable service configuration
RUN echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d

# Install System Dependencies and Upgrade
RUN DEBIAN_FRONTEND=noninteractive apt update && DEBIAN_FRONTEND=noninteractive apt install -y \
    # Core Utilities
    wget \
    curl \
    unzip \
    git \
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
    python3 \
    python3-pip \
    python3-venv \
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
    cockpit && \
    DEBIAN_FRONTEND=noninteractive dpkg --configure -a && \
    apt install -f -y \
    htop \
    iftop \
    iotop \
    sysstat \
    lsof \ 
    strace \    
    openssl \
    ethtool \
    iperf3 \
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
    python3-dev \
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
    mailutils \
    liblua5.3-dev \
    software-properties-common && \
    ln -sf /usr/bin/python3 /usr/local/bin/python3 && \
    ln -sf /usr/bin/pip3 /usr/local/bin/pip3 && \
    mkdir -p /var/run/munge /run/munge /var/lib/munge /var/log/munge /etc/munge && \
    mkdir -p /var/log/slurm/ /etc/slurm && \
    chown -R munge:munge /etc/munge /var/run/munge /var/lib/munge /var/log/munge /run/munge && \
    chmod 700 /var/lib/munge /var/run/munge && \
    chmod 755 /run/munge && \
    apt list nvidia-driver-*

# Add CVMFS repository and install the package
RUN wget https://cvmrepo.s3.cern.ch/cvmrepo/apt/cvmfs-release-latest_all.deb && \
    dpkg -i cvmfs-release-latest_all.deb && rm -f cvmfs-release-latest_all.deb && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    cvmfs \
    cvmfs-fuse3

# Lets Upgrade and install prerequisites
RUN apt update && apt upgrade -y && \
    mkdir -p /var/run/nvidia-persistenced && \
    echo "nvidia" >> /etc/modules && \
    echo "nvidia_uvm" >> /etc/modules && \
    mkdir /run/sshd && chmod 755 /run/sshd

# Install the NVIDIA driver from Ubuntu repositories
RUN apt-get install -y --no-install-recommends \
    nvidia-driver-${NVIDIA_DRIVER_VERSION} \
    nvidia-settings \
    nvidia-prime

# Install NVIDIA utilities and libraries from Ubuntu repositories
RUN apt-get install -y --no-install-recommends \
    libnvidia-compute-${NVIDIA_DRIVER_VERSION} \
    libnvidia-gl-${NVIDIA_DRIVER_VERSION} \
    nvidia-modprobe

# Precompile NVIDIA kernel modules
RUN nvidia-modprobe && \
    nvidia-smi && \
    depmod -a && \
    modprobe nvidia

# Install Slurm Job Exporter 
RUN mkdir -p /opt/slurm-job-exporter && \
    chown -R root:root /opt/slurm-job-exporter && \
    cd /opt/slurm-job-exporter && \
    git clone https://github.com/guilbaults/slurm-job-exporter.git . && \
    python3 -m venv /opt/slurm-job-exporter/venv && \
    /opt/slurm-job-exporter/venv/bin/pip install -r requirements.txt && \
    ln -s /opt/slurm-job-exporter/slurm-job-exporter.py /usr/bin/slurm-job-exporter && \
    chmod +x /usr/bin/slurm-job-exporter

# Install Slurm Job Exporter Service
RUN cp /opt/slurm-job-exporter/slurm-job-exporter.service /etc/systemd/system/slurm-job-exporter.service && \
    sed -i '/\[Service\]/a WorkingDirectory=/opt/slurm-job-exporter' /etc/systemd/system/slurm-job-exporter.service && \
    chmod 644 /etc/systemd/system/slurm-job-exporter.service 

# Configure and build Slurm with the additional features enabled
RUN mkdir -p /usr/src && cd /usr/src && \
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
                --enable-mpi && \
    make -j$(nproc) && make install && \
    cd contribs && make && make install && \
    touch /var/log/slurm/slurm-dbd.log && \
    touch /var/log/slurm/slurmctld.log

# Enable Services Manually Without systemctl
RUN mkdir -p /etc/systemd/system/multi-user.target.wants && \
    ln -s /lib/systemd/system/cockpit.socket /etc/systemd/system/multi-user.target.wants/cockpit.socket || true && \
    ln -s /lib/systemd/system/nvidia-dcgm.service /etc/systemd/system/multi-user.target.wants/nvidia-dcgm.service || true && \
    ln -s /lib/systemd/system/prometheus-node-exporter.service /etc/systemd/system/multi-user.target.wants/prometheus-node-exporter.service || true && \
    ln -s /etc/systemd/system/slurm-job-exporter.service /etc/systemd/system/multi-user.target.wants/slurm-job-exporter.service || true

# Fetch the latest SCAP Security Guide
RUN export SSG_VERSION=$(curl -s https://api.github.com/repos/ComplianceAsCode/content/releases/latest | grep -oP '"tag_name": "\K[^"]+' || echo "0.1.66") && \
    echo "🔄 Using SCAP Security Guide version: $SSG_VERSION" && \
    SSG_VERSION_NO_V=$(echo "$SSG_VERSION" | sed 's/^v//') && \
    echo "🔄 Stripped Version: $SSG_VERSION_NO_V" && \
    wget -O /ssg.zip "https://github.com/ComplianceAsCode/content/releases/download/${SSG_VERSION}/scap-security-guide-${SSG_VERSION_NO_V}.zip" && \
    mkdir -p /usr/share/xml/scap/ssg/content && \
    if [ -f "/ssg.zip" ]; then \
        unzip -jo /ssg.zip "scap-security-guide-${SSG_VERSION_NO_V}/*" -d /usr/share/xml/scap/ssg/content/ && \
        rm -f /ssg.zip; \
    else \
        echo "❌ Failed to download SCAP Security Guide"; exit 1; \
    fi

# Create Users
RUN groupadd -g 1000 wwgroup && useradd -m -u 1000 -g slurm -s /bin/bash wwuser && \
    echo "wwuser:wwpassword" | chpasswd && \
    usermod -aG sudo wwuser && \
    groupadd -r slurm && useradd -r -g slurm -s /bin/false slurm && \
    mkdir -p /var/spool/slurmctld /var/log/slurm/ /var/run/slurm && \
    chown -R slurm:slurm /etc/slurm /var/spool/slurmctld /var/run/slurm /var/log/slurm /opt/software/slurm/sbin && \
    chmod 644 /etc/slurm/* && \
    chown munge:munge -R /etc/munge
    
EXPOSE 22

# Clean Up
RUN apt-get purge -y \
    build-essential \
    cmake \
    gcc \
    make \
    man-db \
    zlib1g-dev \
    linux-headers-generic \
    pkg-config \
    autoconf \
    automake \
    libssl-dev \
    libev-dev \
    libevent-dev \
    libtool \
    libyaml-dev \
    libpam0g-dev \
    liblua5.3-dev \
    libmunge-dev \
    libhdf5-dev \
    libmariadb-dev \
    librrd-dev \
    libjson-c-dev \
    libhwloc-dev \
    libnuma-dev \
    libcurl4-openssl-dev \
    software-properties-common \
    libjwt-dev && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /usr/src/* /var/lib/apt/lists/* /tmp/* \
    /var/tmp/* /var/log/* /usr/share/doc /usr/share/man \
    /usr/share/locale /usr/share/info && rm /usr/sbin/policy-rc.d

# Add OpenSCAP Scripts
COPY openscap_scan.sh /openscap_scan.sh
COPY openscap_remediate.sh /openscap_remediate.sh

# Make scripts executable
RUN chmod +x /openscap_scan.sh /openscap_remediate.sh

CMD ["/sbin/init"]
