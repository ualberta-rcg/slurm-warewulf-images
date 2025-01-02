FROM ubuntu:22.04

# Environment settings
ENV DEBIAN_FRONTEND=noninteractive

# Install System Dependencies and Upgrade
RUN apt update && apt upgrade -y && apt install -y \
    # Core Utilities
    wget \
    unzip \
    git \
    curl \
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
    
    # Monitoring & Debugging Tools
    htop \
    iftop \
    iotop \
    atop \
    sysstat \
    dstat \
    tcpdump \
    traceroute \
    lsof \
    strace \
    tmux \
    screen \
    less \
    nano \
    vim \
    
    # Networking Tools
    iputils-ping \
    dnsutils \
    ncdu \
    nmap \
    socat \
    
    # Python & Pip Dependencies
    python3-pip \
    python3-dev \
    python3-venv \
    
    # MySQL Client
    libmysqlclient-dev \
    mysql-client \
    
    # Cockpit for System Management
    cockpit \
    
    # OpenSCAP Dependencies
    libopenscap8 \
    
    # Security Tools
    fail2ban \
    ufw \
    openssl \
    gnupg-agent \
    
    # Miscellaneous
    jq \
    whois \
    zip \
    unzip \
    tree \
    curl \
    
    # Log Management
    logrotate \
    rsyslog \
    
    && apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/*

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

# Add OpenSCAP Scripts
COPY openscap_scan.sh /openscap_scan.sh
COPY openscap_remediate.sh /openscap_remediate.sh

# Make scripts executable
RUN chmod +x /openscap_scan.sh /openscap_remediate.sh

CMD ["/bin/bash"]
