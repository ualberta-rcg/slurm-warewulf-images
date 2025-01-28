#FROM nvidia/cuda:12.6.3-base-ubuntu24.04
FROM ubuntu:24.10

# Set Environment Variables
ENV PATH=/usr/local/ssl/bin:$PREFIX/bin:/opt/software/slurm/sbin:${PATH:-}
ENV LD_LIBRARY_PATH=/usr/local/ssl/lib:${LD_LIBRARY_PATH:-}
ENV DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV KERNEL_VERSION=6.11.0-14-generic

# Temporarily disable service configuration
RUN echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d

# Install System Dependencies and Upgrade
RUN DEBIAN_FRONTEND=noninteractive dpkg --configure -a && DEBIAN_FRONTEND=noninteractive apt update && DEBIAN_FRONTEND=noninteractive apt install -y \
    # Core Utilities
    wget \
    curl \
    unzip \
    locales \
    bash-completion \
    net-tools \
    openssh-server \
    openssh-client \
    gnupg \
    lsb-release \
    ca-certificates \
    tzdata \
    vim \
    jq \
    linux-image-generic \
    systemd \
    openmpi-bin \
    kmod \
    numactl \
    sysstat \
    lsof \ 
    iputils-ping \
    apt-utils \
    systemd-sysv \
    dbus \
    pciutils \
    openscap-scanner \
    netbase \
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
    gettext \
    pkg-config \
    autoconf \
    automake \
    gcc \
    make \
    libmunge2 \
    libpmix-bin \
    rrdtool \
    lua5.3 \
    build-essential \
    dkms \
    libglvnd-dev\ 
    pkg-config \
    xorg-dev \
    libx11-dev \
    libxext-dev \
    linux-headers-generic \
    linux-headers-${KERNEL_VERSION} \
    linux-image-${KERNEL_VERSION} \
    linux-modules-${KERNEL_VERSION} && \
    ln -s /usr/src/linux-headers-${KERNEL_VERSION} /lib/modules/${KERNEL_VERSION}/build

RUN NVIDIA_DRIVER_VERSION=$(wget -qO- https://us.download.nvidia.com/XFree86/Linux-x86_64/latest.txt | awk '{print $1}') && \
    # Create the directory for the NVIDIA driver version
    mkdir -p /usr/src/nvidia-${NVIDIA_DRIVER_VERSION} && \
    # Create dkms.conf
    echo "PACKAGE_NAME=\"nvidia\"" > /usr/src/nvidia-${NVIDIA_DRIVER_VERSION}/dkms.conf  && \
    echo "PACKAGE_VERSION=\"${NVIDIA_DRIVER_VERSION}\"" >> /usr/src/nvidia-${NVIDIA_DRIVER_VERSION}/dkms.conf  && \
    echo "BUILT_MODULE_NAME[0]=\"nvidia\"" >> /usr/src/nvidia-${NVIDIA_DRIVER_VERSION}/dkms.conf  && \
    echo "DEST_MODULE_LOCATION[0]=\"/kernel/drivers/video\"" >> /usr/src/nvidia-${NVIDIA_DRIVER_VERSION}/dkms.conf  && \
    echo "BUILT_MODULE_NAME[1]=\"nvidia-uvm\"" >> /usr/src/nvidia-${NVIDIA_DRIVER_VERSION}/dkms.conf  && \
    echo "DEST_MODULE_LOCATION[1]=\"/kernel/drivers/video\"" >> /usr/src/nvidia-${NVIDIA_DRIVER_VERSION}/dkms.conf  && \
    echo "BUILT_MODULE_NAME[2]=\"nvidia-modeset\"" >> /usr/src/nvidia-${NVIDIA_DRIVER_VERSION}/dkms.conf  && \
    echo "DEST_MODULE_LOCATION[2]=\"/kernel/drivers/video\"" >> /usr/src/nvidia-${NVIDIA_DRIVER_VERSION}/dkms.conf  && \
    echo "BUILT_MODULE_NAME[3]=\"nvidia-drm\"" >> /usr/src/nvidia-${NVIDIA_DRIVER_VERSION}/dkms.conf  && \
    echo "DEST_MODULE_LOCATION[3]=\"/kernel/drivers/video\"" >> /usr/src/nvidia-${NVIDIA_DRIVER_VERSION}/dkms.conf  && \
    echo "AUTOINSTALL=\"yes\"" >> /usr/src/nvidia-${NVIDIA_DRIVER_VERSION}/dkms.conf 


# Combine NVIDIA driver download, installation, and DKMS setup
RUN NVIDIA_DRIVER_VERSION=$(wget -qO- https://us.download.nvidia.com/XFree86/Linux-x86_64/latest.txt | awk '{print $1}') && \
    echo "Using NVIDIA driver version: $NVIDIA_DRIVER_VERSION" && \
    wget -q https://us.download.nvidia.com/XFree86/Linux-x86_64/${NVIDIA_DRIVER_VERSION}/NVIDIA-Linux-x86_64-${NVIDIA_DRIVER_VERSION}.run -O /tmp/NVIDIA.run && \
    chmod +x /tmp/NVIDIA.run && \
    # Extract the NVIDIA driver sources
    sh /tmp/NVIDIA.run -x -s --no-kernel-module && \
    cd NVIDIA-Linux-x86_64-${NVIDIA_DRIVER_VERSION} && \
    # Create DKMS source directory
    mkdir -p /usr/src/nvidia-${NVIDIA_DRIVER_VERSION} && \
    cp -r kernel/* /usr/src/nvidia-${NVIDIA_DRIVER_VERSION} && \
    # Install the driver without kernel modules
    /tmp/NVIDIA.run --no-systemd \
                      --no-kernel-module \
                      --silent \
                      --x-prefix=/usr \
                      --x-module-path=/usr/lib/xorg/modules \
                      --x-library-path=/usr/lib \
                      --kernel-source-path=/lib/modules/${KERNEL_VERSION}/build
                      
RUN ls -la /lib/modules/${KERNEL_VERSION}/build && \
    NVIDIA_DRIVER_VERSION=$(wget -qO- https://us.download.nvidia.com/XFree86/Linux-x86_64/latest.txt | awk '{print $1}') && \
    dkms add -m nvidia -v ${NVIDIA_DRIVER_VERSION} && \
    dkms build -m nvidia -v ${NVIDIA_DRIVER_VERSION} -k ${KERNEL_VERSION} && \
    dkms install -m nvidia -v ${NVIDIA_DRIVER_VERSION} -k ${KERNEL_VERSION} && \
    cd .. && \
    rm -rf NVIDIA-Linux-x86_64-${NVIDIA_DRIVER_VERSION} && \
    rm /tmp/NVIDIA.run && \
    echo "nvidia" >> /etc/modules && echo "nvidia_uvm" >> /etc/modules

# Optional: Persist the kernel modules into the initramfs
RUN update-initramfs -u -k ${KERNEL_VERSION}

# Clean Up APT Repo
RUN apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/* && rm /usr/sbin/policy-rc.d

# Copy the firstboot files
COPY firstboot.service /etc/systemd/system/
COPY firstboot.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/firstboot.sh

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
