#!/bin/bash

echo "🔧 Remediating CIS Level 2 Server Profile..."
oscap xccdf eval \
    --remediate \
    --profile xccdf_org.ssgproject.content_profile_cis_level2_server \
    --results /home/oscap-results.xml \
    /ssg/ssg-ubuntu2204-ds.xml

echo "📊 Generating Remediation Report..."
oscap xccdf generate report /home/oscap-results.xml > /home/oscap-results.html
