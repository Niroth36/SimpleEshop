# SimpleEshop Email Services

This directory contains the serverless email services used by the SimpleEshop application. These services are responsible for sending emails to users based on specific events, such as user registration and order confirmation.

## Overview

The SimpleEshop application uses two standalone email services:

1. **Welcome Email Service**: Sends a welcome email to users when they register for an account.
2. **Order Confirmation Email Service**: Sends an order confirmation email to users when they place an order.

These services are event-driven and are triggered by MinIO bucket notifications when new objects (JSON files) are created in specific buckets.

## Architecture

The email services follow an event-driven architecture:

1. The SimpleEshop web application stores event data (user registrations or order confirmations) as JSON files in MinIO buckets.
2. MinIO sends notifications to the appropriate email service when new files are created in the buckets.
3. The email service retrieves the data from MinIO, processes it, and sends an email to the user via the Mailpit SMTP server.

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  SimpleEshop │     │    MinIO    │     │ Email       │     │   Mailpit   │
│  Web App     │────▶│  Storage    │────▶│ Services    │────▶│  SMTP Server│
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
      │                                        │                   │
      │                                        │                   │
      └────────────────────────────────────────┴───────────────────┘
                          Direct API calls
```

## Services

### Welcome Email Service

Located in the `welcome-email` directory, this service:

- Listens for notifications from the `user-registrations` bucket in MinIO
- Processes user registration data
- Sends a welcome email to the user's email address

### Order Confirmation Email Service

Located in the `order-confirmation-email` directory, this service:

- Listens for notifications from the `order-confirmations` bucket in MinIO
- Processes order data
- Sends an order confirmation email to the user's email address with order details

## Configuration

Both services are configured using environment variables in the `docker-compose.yml` file:

### Welcome Email Service

```yaml
environment:
  MINIO_HOST: minio
  MINIO_PORT: 9000
  MINIO_ACCESS_KEY: minioadmin
  MINIO_SECRET_KEY: minioadmin
  SMTP_HOST: mailpit
  SMTP_PORT: 1025
```

### Order Confirmation Email Service

```yaml
environment:
  MINIO_HOST: minio
  MINIO_PORT: 9002
  MINIO_ACCESS_KEY: minioadmin
  MINIO_SECRET_KEY: minioadmin
  SMTP_HOST: mailpit
  SMTP_PORT: 1025
```

**Note**: The Order Confirmation Email Service uses port 9002 to connect to MinIO, while the Welcome Email Service uses port 9000. This is because MinIO is exposed on port 9002 in the docker-compose.yml file.

## Service Structure

Each service consists of the following files:

- **Dockerfile.standalone**: Defines how the service is built as a standalone container
- **handler.js**: Contains the main logic for processing events and sending emails
- **index.js**: Sets up the service, including MinIO client configuration and event handling
- **package.json**: Defines the service's dependencies

## Testing

You can test the email services using the provided test scripts:

### Welcome Email Service

```bash
./test-welcome-email.sh
```

This script:
1. Creates a test user registration JSON file
2. Uploads it to the `user-registrations` bucket in MinIO
3. Waits for the welcome-email service to process the event
4. You can check the Mailpit web interface at http://localhost:8025 to see if the email was sent

### Order Confirmation Email Service

```bash
./test-order-confirmation-email.sh
```

This script:
1. Creates a test order JSON file
2. Uploads it to the `order-confirmations` bucket in MinIO
3. Waits for the order-confirmation-email service to process the event
4. You can check the Mailpit web interface at http://localhost:8025 to see if the email was sent

### Integration Test

```bash
./test-integration.sh
```

This script tests the integration between MinIO, the Welcome Email Service, and Mailpit.

## Deployment

The email services are deployed as Docker containers using Docker Compose. To deploy them:

```bash
docker compose up -d welcome-email order-confirmation-email
```

To check if the services are running:

```bash
docker ps | grep simpleeshop-welcome-email
docker ps | grep simpleeshop-order-confirmation-email
```

To view the logs of the services:

```bash
docker logs simpleeshop-welcome-email
docker logs simpleeshop-order-confirmation-email
```

## Troubleshooting

If the email services are not working correctly:

1. Check if the services are running:
   ```bash
   docker ps | grep simpleeshop-welcome-email
   docker ps | grep simpleeshop-order-confirmation-email
   ```

2. Check the logs for errors:
   ```bash
   docker logs simpleeshop-welcome-email
   docker logs simpleeshop-order-confirmation-email
   ```

3. Verify that MinIO is running and accessible:
   ```bash
   docker ps | grep simpleeshop-minio
   ```

4. Verify that Mailpit is running and accessible:
   ```bash
   docker ps | grep simpleeshop-mailpit
   ```

5. Run the test scripts to verify that the services are working:
   ```bash
   ./test-welcome-email.sh
   ./test-order-confirmation-email.sh
   ```

6. Check the Mailpit web interface at http://localhost:8025 to see if the emails were sent.

7. Run the system check script to verify that all components are working:
   ```bash
   ./check-system.sh
   ```