#!/bin/bash

# Script to directly test the welcome-email service

echo "Testing the welcome-email service directly..."

# Create a temporary directory for our test files
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

# Create a test JSON file with user data
echo "Creating test user data..."
cat > test-user-data.json <<EOF
{
  "userData": {
    "userId": 828,
    "username": "directtest1",
    "email": "directtest1@example.com",
    "registrationDate": "$(date -Iseconds)"
  }
}
EOF

# Check if the welcome-email service is running
echo "Checking if welcome-email service is running..."
if ! docker ps | grep -q simpleeshop-welcome-email; then
    echo "welcome-email service is not running. Starting it now..."
    docker compose up -d welcome-email
fi

# Upload the test file to MinIO
echo "Uploading test file to MinIO..."
# Check if mc (MinIO client) is installed
if ! command -v mc &> /dev/null; then
    echo "MinIO client (mc) is not installed. Installing it now..."
    wget https://dl.min.io/client/mc/release/linux-amd64/mc -O /tmp/mc
    chmod +x /tmp/mc
    MC_CMD="/tmp/mc"
else
    MC_CMD="mc"
fi

# Configure MinIO client
echo "Configuring MinIO client..."
$MC_CMD alias set simpleeshop http://localhost:9002 minioadmin minioadmin

# Check if the user-registrations bucket exists, create it if not
echo "Checking if user-registrations bucket exists..."
if ! $MC_CMD ls simpleeshop/user-registrations &> /dev/null; then
    echo "Creating user-registrations bucket..."
    $MC_CMD mb simpleeshop/user-registrations
fi

# Upload the test file to MinIO
echo "Uploading test file to MinIO..."
$MC_CMD cp test-user-data.json simpleeshop/user-registrations/user-828-$(date +%s).json

# Wait for the event to be processed
echo "Waiting for the event to be processed..."
sleep 5

# Clean up
cd - > /dev/null
rm -rf $TEMP_DIR

echo ""
echo "welcome-email service test complete."
echo "Check the Mailpit web interface at http://localhost:8025 to see if a welcome email was sent to directtest1@example.com"
echo "If you see the email, the welcome-email service is working correctly."
