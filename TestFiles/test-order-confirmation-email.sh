#!/bin/bash

# Script to directly test the order-confirmation-email service

echo "Testing the order-confirmation-email service directly..."

# Create a temporary directory for our test files
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

# Create a test JSON file with order data
echo "Creating test order data..."
cat > test-order-data.json <<EOF
{
  "orderData": {
    "orderId": "ORD-12345",
    "userId": 123,
    "username": "testuser",
    "email": "ordertest@example.com",
    "items": [
      {
        "id": 1,
        "name": "Intel Core i7 Processor",
        "price": 349.99,
        "quantity": 1
      },
      {
        "id": 2,
        "name": "32GB DDR4 RAM",
        "price": 129.99,
        "quantity": 2
      },
      {
        "id": 3,
        "name": "1TB SSD Storage",
        "price": 99.99,
        "quantity": 1
      }
    ],
    "total": 709.96,
    "orderDate": "$(date -Iseconds)"
  }
}
EOF

# Check if the order-confirmation-email service is running
echo "Checking if order-confirmation-email service is running..."
if ! docker ps | grep -q simpleeshop-order-confirmation-email; then
    echo "order-confirmation-email service is not running. Starting it now..."
    docker compose up -d order-confirmation-email
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

# Check if the order-confirmations bucket exists, create it if not
echo "Checking if order-confirmations bucket exists..."
if ! $MC_CMD ls simpleeshop/order-confirmations &> /dev/null; then
    echo "Creating order-confirmations bucket..."
    $MC_CMD mb simpleeshop/order-confirmations
fi

# Upload the test file to MinIO
echo "Uploading test file to MinIO..."
$MC_CMD cp test-order-data.json simpleeshop/order-confirmations/order-12345-$(date +%s).json

# Wait for the event to be processed
echo "Waiting for the event to be processed..."
sleep 5

# Clean up
cd - > /dev/null
rm -rf $TEMP_DIR

echo ""
echo "order-confirmation-email service test complete."
echo "Check the Mailpit web interface at http://localhost:8025 to see if an order confirmation email was sent to ordertest@example.com"
echo "If you see the email, the order-confirmation-email service is working correctly."
