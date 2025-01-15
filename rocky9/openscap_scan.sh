#!/bin/bash

# Define SCAP Guide and Profile
SCAP_GUIDE="/usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml"
PROFILE="xccdf_org.ssgproject.content_profile_cis"

echo "🔍 Starting OpenSCAP Scan with CIS Level 2 Server Profile..."

oscap xccdf eval \
    --profile $PROFILE \
    --fetch-remote-resources \
    --results /home/oscap-results.xml \
    --report /home/oscap-results.html \
    --oval-results \
    $SCAP_GUIDE

echo "✅ OpenSCAP Scan Complete. Report saved to /home/oscap-results.html"
