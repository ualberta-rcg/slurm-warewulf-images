FROM nvidia/cuda:12.6.3-base-rockylinux9

# Environment settings
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# Install System Dependencies and Upgrade
RUN dnf update -y && \
    dnf install -y epel-release && \
    dnf update -y && \
    dnf install -y \
    # Core Utilities
    wget \
    curl \
    unzip \
    git \
    bash-completion \
    net-tools \
    openssh-server \
    openssh-clients \
    gnupg2 \
    ca-certificates \
    rsync \
    tzdata \
    tree \
    nano \
    vim \
    tmux \
    jq \
    kernel \
    kernel-devel \
    sudo \
    python3 \
    python3-pip \
    openssl-devel \
    libcurl-devel \
    hwloc \
    openmpi \
    numactl \
    golang-github-prometheus-node-exporter \
    nfs-utils \
    cockpit \
    htop \
    iftop \
    iotop \
    sysstat \
    lsof \
    strace \
    ethtool \
    iperf3 \
    iptables-services \
    iputils \
    bind-utils \
    traceroute \
    tcpdump \
    pciutils \
    libxml2-devel \
    libevent-devel \
    numactl-libs \
    dbus \
    rdma-core \
    openscap-scanner \
    --allowerasing --nobest && \
    dnf clean all

# NVIDIA Modules Setup
RUN mkdir -p /var/run/nvidia-persistenced && \
    echo "nvidia" >> /etc/modules-load.d/nvidia.conf && \
    echo "nvidia_uvm" >> /etc/modules-load.d/nvidia.conf

# Enable Required Services
RUN systemctl enable cockpit.socket || true && \
    systemctl enable prometheus-node-exporter.service || true

# Install Puppet Agent
RUN dnf install -y https://yum.puppet.com/puppet-release-el-8.noarch.rpm && \
    dnf install -y puppet-agent && \
    rm -f /etc/yum.repos.d/puppet*.repo

# Install Slurm Job Exporter
RUN mkdir -p /opt/slurm-job-exporter && \
    cd /opt/slurm-job-exporter && \
    git clone https://github.com/guilbaults/slurm-job-exporter.git . && \
    python3 -m venv /opt/slurm-job-exporter/venv && \
    /opt/slurm-job-exporter/venv/bin/pip install -r requirements.txt && \
    ln -s /opt/slurm-job-exporter/slurm-job-exporter.py /usr/bin/slurm-job-exporter && \
    chmod +x /usr/bin/slurm-job-exporter

# Install Slurm Job Exporter Service
RUN cp /opt/slurm-job-exporter/slurm-job-exporter.service /etc/systemd/system/slurm-job-exporter.service && \
    sed -i '/\[Service\]/a WorkingDirectory=/opt/slurm-job-exporter' /etc/systemd/system/slurm-job-exporter.service && \
    chmod 644 /etc/systemd/system/slurm-job-exporter.service && \
    systemctl enable slurm-job-exporter.service || true

# Fetch the latest SCAP Security Guide
RUN export SSG_VERSION=$(curl -s https://api.github.com/repos/ComplianceAsCode/content/releases/latest | grep -oP '"tag_name": "\K[^"]+' || echo "0.1.66") && \
    echo "🔄 Using SCAP Security Guide version: $SSG_VERSION" && \
    SSG_VERSION_NO_V=$(echo "$SSG_VERSION" | sed 's/^v//') && \
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
    usermod -aG wheel wwuser

# Expose SSH Port
EXPOSE 22

# Clean up DNF
RUN dnf autoremove -y && dnf clean all

# Add OpenSCAP Scripts
COPY openscap_scan.sh /openscap_scan.sh
COPY openscap_remediate.sh /openscap_remediate.sh

# Make scripts executable
RUN chmod +x /openscap_scan.sh /openscap_remediate.sh

# Command to start systemd
CMD ["/usr/sbin/init"]
