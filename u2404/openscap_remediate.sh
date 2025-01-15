#!/bin/bash

# Define SCAP Guide and Profile
SCAP_GUIDE="/usr/share/xml/scap/ssg/content/ssg-ubuntu2204-ds.xml"
PROFILE="xccdf_org.ssgproject.content_profile_cis_level2_server"

echo "🔧 Applying CIS Level 2 Server Profile Remediation..."

oscap xccdf eval \
    --remediate \
    --profile $PROFILE \
    --results /home/oscap-results-remediated.xml \
    --report /home/oscap-results-remediated.html \
    $SCAP_GUIDE

echo "✅ Remediation Complete. Report saved to /home/oscap-results-remediated.html"

rm -rf /usr/share/xml/scap/ssg/content

# Clean Up APT Repo
apt remove openscap -y 
apt autoremove -y 
apt clean 
rm -rf /var/lib/apt/lists/* 
