FROM ubuntu:22.04

# Environment settings
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt update && apt install -y \
    libopenscap8 \
    wget \
    unzip \
    git \
    curl \
    sudo \
    && apt clean

# Fetch the latest SCAP Security Guide
RUN export SSG_VERSION=$(curl -s https://api.github.com/repos/ComplianceAsCode/content/releases/latest | grep -oP '"tag_name": "\K[^"]+' || echo "0.1.66") && \
    echo "Using SCAP Security Guide version: $SSG_VERSION" && \
    wget -O /ssg.zip "https://github.com/ComplianceAsCode/content/releases/download/${SSG_VERSION}/scap-security-guide-${SSG_VERSION}.zip" && \
    if [ -f "/ssg.zip" ]; then \
        unzip -jo /ssg.zip "scap-security-guide-${SSG_VERSION}/*" -d /usr/share/xml/scap/ssg/content/ && \
        rm -f /ssg.zip; \
    else \
        echo "Failed to download SCAP Security Guide"; exit 1; \
    fi

# Add OpenSCAP Scripts
COPY openscap_scan.sh /openscap_scan.sh
COPY openscap_remediate.sh /openscap_remediate.sh

# Make scripts executable
RUN chmod +x /openscap_scan.sh /openscap_remediate.sh

CMD ["/bin/bash"]
