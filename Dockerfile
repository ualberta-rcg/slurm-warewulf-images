FROM nvidia/cuda:12.6.3-base-ubuntu22.04

# Environment settings
ENV DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# Add support for loading NVIDIA modules at boot
RUN echo "nvidia" >> /etc/modules
RUN echo "nvidia_uvm" >> /etc/modules

# Install System Dependencies and Upgrade
RUN apt update && apt upgrade -y && apt install -y \
    # Core Utilities
    wget \
    curl \
    unzip \
    zip \
    git \
    sudo \
    build-essential \
    software-properties-common \
    locales \
    bash-completion \
    iproute2 \
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
    less \
    screen \
    tmux \
    jq \
    whois \
    linux-tools-common \
    linux-tools-generic \
    
    # Python & Pip Dependencies
    python3 \
    python3-pip \
    python3-dev \
    python3-venv \
    
    # MySQL Client
    libmysqlclient-dev \
    mysql-client \
    
    # HPC Tools & Libraries
    libssl-dev \
    libcurl4-openssl-dev \
    libhwloc-dev \
    libpam-dev \
    openmpi-bin \
    libopenmpi-dev \
    mpich \
    ganglia-monitor \
    collectd \
    rdma-core \
    infiniband-diags \
    ibutils \
    libnuma-dev \
    kmod \
    nvidia-container-toolkit \
    nvidia-docker2 \
    libpmix-dev \
    libevent-dev \
    libxml2-dev \
    man-db \
    numactl \
    nvidia-cuda-toolkit \
    prometheus-node-exporter \
    datacenter-gpu-manager \
    
    # Networking Tools
    bridge-utils \
    vlan \
    ethtool \
    mtr \
    iperf3 \
    iptables-persistent \
    iputils-ping \
    dnsutils \
    ncdu \
    nmap \
    socat \
    traceroute \
    tcpdump \
    
    # Monitoring & Debugging Tools
    htop \
    iftop \
    iotop \
    atop \
    sysstat \
    dstat \
    nmon \
    lsof \
    strace \
    
    # Security Tools
    auditd \
    openssl \
    
    # Logging Tools
    logrotate \
    rsyslog \
    
    # File System and Storage Tools
    nfs-common \
    cifs-utils \
    
    # Cluster & Stability Utilities
    watchdog \
    corosync \
    pacemaker \
    
    # Automation Tools
    ansible \
    
    # Cockpit for System Management
    cockpit 

RUN mkdir -p /var/run/nvidia-persistenced

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
    pip3 install -r requirements.txt && \
    ln -s /opt/slurm-job-exporter/slurm-job-exporter.py /usr/bin/slurm-job-exporter && \
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

# Clean Up APT Repo
RUN apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/*

# Add OpenSCAP Scripts
COPY openscap_scan.sh /openscap_scan.sh
COPY openscap_remediate.sh /openscap_remediate.sh

# Make scripts executable
RUN chmod +x /openscap_scan.sh /openscap_remediate.sh

CMD ["/bin/bash"]
