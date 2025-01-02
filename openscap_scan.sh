#!/bin/bash

# Define SCAP Guide and Profile
SCAP_GUIDE="/usr/share/xml/scap/ssg/content/ssg-ubuntu2204-ds.xml"
PROFILE="xccdf_org.ssgproject.content_profile_cis_level2_server"

echo "🔍 Starting OpenSCAP Scan with CIS Level 2 Server Profile..."

oscap xccdf eval \
    --profile $PROFILE \
    --results /home/oscap-results.xml \
    --report /home/oscap-results.html \
    $SCAP_GUIDE

echo "✅ OpenSCAP Scan Complete. Report saved to /home/oscap-results.html"
