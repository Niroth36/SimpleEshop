#!/bin/bash

# Script to test the integration between MinIO, Welcome Email Service, and Mailpit

echo "Testing the integration between MinIO, Welcome Email Service, and Mailpit..."

# Check if welcome-email service is running
echo "Checking if welcome-email service is running..."
if ! docker ps | grep -q simpleeshop-welcome-email; then
    echo "welcome-email service is not running. Starting it now..."
    docker compose up -d welcome-email
fi

# Create a temporary directory for our test files
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

# Create a test user registration JSON file
echo "Creating a test user registration JSON file..."
cat > test-user.json <<EOF
{
  "userData": {
    "userId": 999,
    "username": "integrationtest",
    "email": "integrationtest@example.com",
    "registrationDate": "$(date -Iseconds)"
  }
}
EOF

# Install MinIO client if not already installed
if ! command -v mc &> /dev/null; then
    echo "MinIO client (mc) not found. Installing it now..."
    wget https://dl.min.io/client/mc/release/linux-amd64/mc -O mc
    chmod +x mc
    MC_CMD="./mc"
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

# Upload the test user registration JSON file to MinIO
echo "Uploading test user registration to MinIO..."
$MC_CMD cp test-user.json simpleeshop/user-registrations/user-999-$(date +%s).json

# Wait for the welcome-email service to process the event
echo "Waiting for the welcome-email service to process the event..."
sleep 5

# Clean up
cd - > /dev/null
rm -rf $TEMP_DIR

echo ""
echo "Integration test complete."
echo "Check the Mailpit web interface at http://localhost:8025 to see if a welcome email was sent to integrationtest@example.com"
echo "If you see the email, the integration between MinIO, Welcome Email Service, and Mailpit is working correctly."
