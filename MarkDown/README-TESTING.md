# SimpleEshop Testing Guide

This guide provides instructions for testing the SimpleEshop application and its event-driven components.

## Prerequisites

Before running the tests, make sure you have the following installed:

- Docker and Docker Compose
- MinIO Client (`mc`)
- curl

## Quick Start

1. **Start all services**:
   ```bash
   docker compose up -d
   ```

2. **Check system status**:
   ```bash
   ./check-system.sh
   ```
   This script will check if all components are running correctly and provide guidance if any issues are found.

3. **Run all tests**:
   ```bash
   ./run-all-tests.sh
   ```
   This script will run all component tests in sequence and provide a summary of the results.

## Component Tests

### 1. Mailpit (Email Service)

Tests the Mailpit SMTP server by sending a test email directly using curl.

```bash
./test-mailpit.sh
```

After running the test, check the Mailpit web interface at http://localhost:8025 to see if the test email was received.

### 2. Welcome Email Service

Tests the welcome-email service that listens for MinIO events and sends welcome emails to new users.

```bash
./test-welcome-email.sh
```

This script uploads a test user registration JSON file to MinIO, which triggers the welcome-email service to send a welcome email.

After running the test, check the Mailpit web interface at http://localhost:8025 to see if a welcome email was sent to directtest1@example.com.

### 3. Order Confirmation Email Service

Tests the order-confirmation-email service that listens for MinIO events and sends order confirmation emails to users when they submit an order.

```bash
./test-order-confirmation-email.sh
```

This script uploads a test order JSON file to MinIO, which triggers the order-confirmation-email service to send an order confirmation email.

After running the test, check the Mailpit web interface at http://localhost:8025 to see if an order confirmation email was sent to ordertest@example.com.

### 4. Integration Test

Tests the integration between MinIO, the welcome-email service, and Mailpit by simulating a user registration.

```bash
./test-integration.sh
```

After running the test, check the Mailpit web interface at http://localhost:8025 to see if a welcome email was sent to integrationtest@example.com.

## Troubleshooting

### Common Issues

1. **Welcome-email service issues**:
   - Make sure the welcome-email service is running: `docker ps | grep welcome-email`
   - Check the welcome-email logs: `docker logs simpleeshop-welcome-email`
   - Restart the service: `docker compose restart welcome-email`

2. **Order-confirmation-email service issues**:
   - Make sure the order-confirmation-email service is running: `docker ps | grep order-confirmation-email`
   - Check the order-confirmation-email logs: `docker logs simpleeshop-order-confirmation-email`
   - Restart the service: `docker compose restart order-confirmation-email`

3. **MinIO connection issues**:
   - Make sure the MinIO container is running: `docker ps | grep minio`
   - Check the MinIO logs: `docker logs simpleeshop-minio`
   - Verify the MinIO port is correct (9002): `nc -z localhost 9002`

4. **Email not received in Mailpit**:
   - Make sure the Mailpit container is running: `docker ps | grep mailpit`
   - Check the Mailpit logs: `docker logs simpleeshop-mailpit`
   - Verify the SMTP port is correct (1025): `nc -z localhost 1025`

### Restarting the System

If you encounter persistent issues, try restarting the entire system:

```bash
docker compose down
docker compose up -d
./check-system.sh
```

## Starting Services

To start all services:

```bash
docker compose up -d
```

To start only the welcome-email service:

```bash
docker compose up -d welcome-email
```

To start only the order-confirmation-email service:

```bash
docker compose up -d order-confirmation-email
```

## Web Interfaces

- **Mailpit**: http://localhost:8025
- **MinIO Console**: http://localhost:9001
- **Welcome Email Service**: http://localhost:8080
- **Order Confirmation Email Service**: http://localhost:8081
- **Web App**: http://localhost:3000
