FROM ubuntu:22.04

# Install dependencies
RUN apt update && apt install -y \
    libopenscap8 \
    scap-security-guide \
    curl \
    zip \
    wget \
    git \
    sudo \
    && apt clean

# Add OpenSCAP Profile
RUN mkdir -p /ssg
COPY openscap_scan.sh /openscap_scan.sh
COPY openscap_remediate.sh /openscap_remediate.sh

RUN chmod +x /openscap_scan.sh /openscap_remediate.sh

# Set default command
CMD ["/bin/bash"]
