#FROM ghcr.io/hpcng/warewulf-debian:12.0
#FROM nvidia/cuda:12.6.3-base-ubuntu22.04
FROM nvidia/cuda:12.6.3-runtime-ubuntu24.04

# Environment settings
ENV DEBIAN_FRONTEND=noninteractive
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
    build-essential \
    software-properties-common \
    locales \
    bash-completion \
    net-tools \
    openssh-server \
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
    linux-tools-common \
    linux-tools-generic \
    openscap-scanner \
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
    rdma-core \
    infiniband-diags \
    ibutils \
    libnuma-dev \
    kmod \
    nvidia-container-toolkit \
    libpmix-dev \
    libevent-dev \
    libxml2-dev \
    numactl \
    nvidia-cuda-toolkit \
    prometheus-node-exporter \
    datacenter-gpu-manager \
    nfs-common \
    watchdog \
    cockpit
    
# Install Networking, Monitoring & Debugging Tools
RUN DEBIAN_FRONTEND=noninteractive dpkg --configure -a && \
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
    tcpdump 

# Lets Upgrade one more time
RUN apt update && apt upgrade -y && \
    mkdir -p /var/run/nvidia-persistenced && \
    echo "nvidia" >> /etc/modules && \
    echo "nvidia_uvm" >> /etc/modules && \
    mkdir /run/sshd && chmod 755 /run/sshd

# Install Puppet Agent
RUN wget https://apt.puppetlabs.com/puppet-release-focal.deb && \
    dpkg -i puppet-release-focal.deb && \
    apt update && apt install -y puppet-agent && \
    rm -f puppet-release-focal.deb

# Install Slurm Job Exporter 
RUN mkdir -p /opt/slurm-job-exporter && \
    chown -R root:root /opt/slurm-job-exporter && \
    cd /opt/slurm-job-exporter && \
    git clone https://github.com/guilbaults/slurm-job-exporter.git . && \
    python3 -m venv /opt/slurm-job-exporter/venv && \
    /opt/slurm-job-exporter/venv/bin/pip install -r requirements.txt && \
    ln -s /opt/slurm-job-exporter/venv/bin/slurm-job-exporter.py /usr/bin/slurm-job-exporter && \
    chmod +x /usr/bin/slurm-job-exporter

# Install Slurm Job Exporter Service
RUN cp /opt/slurm-job-exporter/slurm-job-exporter.service /etc/systemd/system/slurm-job-exporter.service && \
    sed -i '/\[Service\]/a WorkingDirectory=/opt/slurm-job-exporter' /etc/systemd/system/slurm-job-exporter.service && \
    chmod 644 /etc/systemd/system/slurm-job-exporter.service 

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

# Create a default user
RUN useradd -m -s /bin/bash wwuser && \
    echo "wwuser:wwpassword" | chpasswd && \
    usermod -aG sudo wwuser

EXPOSE 22

# Clean Up APT Repo
RUN apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/* && rm /usr/sbin/policy-rc.d

# Add OpenSCAP Scripts
COPY openscap_scan.sh /openscap_scan.sh
COPY openscap_remediate.sh /openscap_remediate.sh

# Make scripts executable
RUN chmod +x /openscap_scan.sh /openscap_remediate.sh
#CMD ["/bin/bash"]

CMD ["/lib/systemd/systemd"]
