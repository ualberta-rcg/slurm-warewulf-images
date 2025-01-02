#!/bin/bash

# Fetch latest SSG version
SSG_VERSION=$(git ls-remote --tags --ref --sort v:refname https://github.com/ComplianceAsCode/content.git | grep -Pio '(\d+(\.)){2}[\w\.-][\d+]' | tail -1)

if [ -n "$SSG_VERSION" ]; then
    echo "🔄 Downloading SCAP Security Guide v${SSG_VERSION}..."
    wget https://github.com/ComplianceAsCode/content/releases/download/v${SSG_VERSION}/scap-security-guide-${SSG_VERSION}.zip -O ssg.zip
    unzip -jo ssg.zip "scap-security-guide-${SSG_VERSION}/*" -d /ssg

    echo "🛡️ Running OpenSCAP Scan..."
    oscap xccdf eval \
        --profile xccdf_org.ssgproject.content_profile_cis_level2_server \
        --results /home/oscap-results.xml \
        /ssg/ssg-ubuntu2204-ds.xml

    echo "📊 Generating Compliance Report..."
    oscap xccdf generate report /home/oscap-results.xml > /home/oscap-results.html
fi
