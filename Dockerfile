# Base Image: Ubuntu 22.04 Minimal
FROM ubuntu:22.04

# Set environment variables for non-interactive installation
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

# Fetch the latest Security Content Automation Protocol (SCAP) Guide
RUN SSG_VERSION=$(curl -s https://api.github.com/repos/ComplianceAsCode/content/releases/latest | grep -oP '"tag_name": "\K[^"]+') && \
    wget https://github.com/ComplianceAsCode/content/releases/download/${SSG_VERSION}/scap-security-guide-${SSG_VERSION}.zip -O /ssg.zip && \
    unzip -jo /ssg.zip "scap-security-guide-${SSG_VERSION}/*" -d /usr/share/xml/scap/ssg/content/ && \
    rm -f /ssg.zip

# Add OpenSCAP Scripts
COPY openscap_scan.sh /openscap_scan.sh
COPY openscap_remediate.sh /openscap_remediate.sh

# Make scripts executable
RUN chmod +x /openscap_scan.sh /openscap_remediate.sh

# Default command
CMD ["/bin/bash"]
