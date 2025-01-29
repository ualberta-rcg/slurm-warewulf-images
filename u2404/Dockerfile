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
    mkdir -p /usr/src/nvidia-${NVIDIA_DRIVER_VERSION} && \
    cat <<EOF > /usr/src/nvidia-${NVIDIA_DRIVER_VERSION}/dkms.conf
PACKAGE_NAME="nvidia"
PACKAGE_VERSION="${NVIDIA_DRIVER_VERSION}"
AUTOINSTALL="yes"

MAKE[0]="'make' -j\$(nproc) NV_EXCLUDE_BUILD_MODULES='' KERNEL_UNAME=\${kernelver} modules"

BUILT_MODULE_NAME[0]="nvidia"
DEST_MODULE_LOCATION[0]="/kernel/drivers/video"
BUILT_MODULE_NAME[1]="nvidia-uvm"
DEST_MODULE_LOCATION[1]="/kernel/drivers/video"
BUILT_MODULE_NAME[2]="nvidia-modeset"
DEST_MODULE_LOCATION[2]="/kernel/drivers/video"
BUILT_MODULE_NAME[3]="nvidia-drm"
DEST_MODULE_LOCATION[3]="/kernel/drivers/video"
EOF

RUN ls -la /lib/modules/${KERNEL_VERSION}/build && \
    NVIDIA_DRIVER_VERSION=$(wget -qO- https://us.download.nvidia.com/XFree86/Linux-x86_64/latest.txt | awk '{print $1}') && \
    dkms add -m nvidia -v ${NVIDIA_DRIVER_VERSION} || { echo "Failed to add DKMS module."; exit 1; } && \
    dkms build -m nvidia -v ${NVIDIA_DRIVER_VERSION} -k ${KERNEL_VERSION} || { echo "Failed to build DKMS module."; exit 1; } && \
    dkms install -m nvidia -v ${NVIDIA_DRIVER_VERSION} -k ${KERNEL_VERSION} || { echo "Failed to install DKMS module."; exit 1; } && \
    echo "NVIDIA driver successfully installed." && \
    rm -rf /usr/src/nvidia-${NVIDIA_DRIVER_VERSION} && \
    echo "nvidia" >> /etc/modules && echo "nvidia_uvm" >> /etc/modules

# Optional: Persist the kernel modules into the initramfs
RUN update-initramfs -u -k ${KERNEL_VERSION}

# Clean Up APT Repo
RUN apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/* && rm /usr/sbin/policy-rc.d

# Copy the firstboot files
COPY firstboot.service /etc/systemd/system/
COPY firstboot.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/firstboot.sh

# Clean Up
RUN apt-get purge -y \
    linux-headers-generic \
    linux-headers-${KERNEL_VERSION} \
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
