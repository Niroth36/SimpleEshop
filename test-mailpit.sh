#!/bin/bash

# Script to test Mailpit directly using curl

echo "Testing Mailpit SMTP server..."

# Use curl to send a simple email to Mailpit
# Mailpit SMTP server is running on port 1025
cat <<EOF | curl --url smtp://localhost:1025 --mail-from sender@example.com --mail-rcpt recipient@example.com --upload-file -
From: Sender <sender@example.com>
To: Recipient <recipient@example.com>
Subject: Test Email from Curl

This is a test email sent directly to Mailpit using curl.
Testing the SMTP functionality.

Regards,
Test Script
EOF

echo ""
echo "Email sent to Mailpit. Check the web interface at http://localhost:8025"
echo "You should see a new email from sender@example.com to recipient@example.com"