# Testing SimpleEshop Components

This document provides instructions for testing the individual components of SimpleEshop as well as their integration.

## Prerequisites

Before running the tests, make sure the SimpleEshop application is up and running:

```bash
docker compose up -d
```

Verify that all containers are running:

```bash
docker ps
```

All containers should be in a healthy state.

## 1. Testing Mailpit (Email Service)

Mailpit is a simple SMTP server and web interface for testing email functionality.

### Run the Mailpit Test

```bash
./test-mailpit.sh
```

### Expected Results

- The script will send a test email to Mailpit
- You should see a success message in the terminal
- Open http://localhost:8025 in your browser
- You should see a new email from sender@example.com to recipient@example.com
- Click on the email to view its contents

If you can see the test email in the Mailpit web interface, Mailpit is working correctly.

## 2. Testing the Welcome Email Service

This test directly tests the welcome-email service by uploading a test user registration file to MinIO.

### Run the Welcome Email Test

```bash
./test-welcome-email.sh
```

### Expected Results

- The script will check if the welcome-email service is running and start it if needed
- It will create a test user registration JSON file
- It will upload this file to the MinIO bucket
- The welcome-email service should detect the new file and process it
- The service should send a welcome email via Mailpit
- Open http://localhost:8025 in your browser
- You should see a new email sent to directtest1@example.com

If you see the welcome email in Mailpit, the welcome-email service is working correctly.

### Troubleshooting Welcome Email Service

If the test fails, check the welcome-email service logs:

```bash
docker logs simpleeshop-welcome-email
```

Common issues include:
- MinIO connection issues
- SMTP connection issues
- JSON parsing errors

## 3. Testing the Order Confirmation Email Service

This test directly tests the order-confirmation-email service by uploading a test order file to MinIO.

### Run the Order Confirmation Email Test

```bash
./test-order-confirmation-email.sh
```

### Expected Results

- The script will check if the order-confirmation-email service is running and start it if needed
- It will create a test order JSON file with items, prices, quantities, and total
- It will upload this file to the MinIO bucket
- The order-confirmation-email service should detect the new file and process it
- The service should send an order confirmation email via Mailpit
- Open http://localhost:8025 in your browser
- You should see a new email sent to ordertest@example.com with order details

If you see the order confirmation email in Mailpit, the order-confirmation-email service is working correctly.

### Troubleshooting Order Confirmation Email Service

If the test fails, check the order-confirmation-email service logs:

```bash
docker logs simpleeshop-order-confirmation-email
```

Common issues include:
- MinIO connection issues
- SMTP connection issues
- JSON parsing errors
- Issues with formatting order items

## 4. Testing the Integration

This test verifies that the entire pipeline works: MinIO triggers the welcome-email service, which sends an email via Mailpit.

### Prerequisites

You need the MinIO client (`mc`) installed. If you don't have it:

```bash
# For Linux
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
sudo mv mc /usr/local/bin/

# For macOS
brew install minio/stable/mc
```

### Run the Integration Test

```bash
./test-integration.sh
```

### Expected Results

- The script will create a test user registration JSON file
- It will upload this file to the MinIO bucket
- This should trigger the welcome-email service
- The service should send a welcome email via Mailpit
- Open http://localhost:8025 in your browser
- You should see a new email sent to integrationtest@example.com

If you see the welcome email in Mailpit, the integration is working correctly.

### Troubleshooting Integration

If the integration test fails:

1. Check if MinIO received the file:
   ```bash
   mc ls simpleeshop/user-registrations
   ```

2. Check if the welcome-email service is running:
   ```bash
   docker ps | grep welcome-email
   ```

3. Check the welcome-email service logs:
   ```bash
   docker logs simpleeshop-welcome-email
   ```

4. Check if the bucket notification is being received by the service:
   ```bash
   docker logs simpleeshop-welcome-email | grep "Received notification"
   ```

## 5. Testing the Complete User Registration Flow

To test the complete user registration flow from the web application:

1. Open http://localhost:3000/auth.html in your browser
2. Register a new user with a valid email
3. Check http://localhost:8025 to see if a welcome email was sent

## 6. Testing the Complete Order Submission Flow

To test the complete order submission flow from the web application:

1. Open http://localhost:3000 in your browser
2. Add items to your cart
3. Proceed to checkout and complete the order
4. Check http://localhost:8025 to see if an order confirmation email was sent with the order details

## Running All Tests

To run all tests in sequence:

```bash
./run-all-tests.sh
```

This script will run all component tests and provide a summary of the results.

## Conclusion

By testing each component separately and then testing their integration, you can identify where issues might be occurring in the system. This approach helps isolate problems and makes debugging easier.
