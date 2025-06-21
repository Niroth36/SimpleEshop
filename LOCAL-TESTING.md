# SimpleEshop Local Testing Guide

This guide provides comprehensive instructions for testing SimpleEshop locally, including setting up the environment, running tests, and troubleshooting common issues.

## Table of Contents

1. [Setting Up the Local Environment](#setting-up-the-local-environment)
2. [System Health Check](#system-health-check)
3. [Component Testing](#component-testing)
   - [Testing Mailpit (Email Service)](#testing-mailpit-email-service)
   - [Testing Welcome Email Service](#testing-welcome-email-service)
   - [Testing Order Confirmation Email Service](#testing-order-confirmation-email-service)
   - [Testing Integration](#testing-integration)
4. [Application Testing](#application-testing)
   - [Testing User Registration](#testing-user-registration)
   - [Testing Product Browsing](#testing-product-browsing)
   - [Testing Shopping Cart](#testing-shopping-cart)
   - [Testing Checkout Process](#testing-checkout-process)
5. [Database Testing](#database-testing)
6. [Running All Tests](#running-all-tests)
7. [Troubleshooting](#troubleshooting)
8. [Useful Commands](#useful-commands)

## Setting Up the Local Environment

Before you can test SimpleEshop locally, you need to set up the environment:

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Niroth36/SimpleEshop.git
   cd SimpleEshop
   ```

2. **Start all services using Docker Compose**:
   ```bash
   docker compose up -d
   ```
   This command starts all the required services:
   - PostgreSQL database
   - Redis for session storage
   - MinIO for object storage
   - Mailpit for email testing
   - Welcome Email Service
   - Order Confirmation Email Service
   - SimpleEshop web application

3. **Wait for all services to initialize**:
   It may take a few moments for all services to start up and initialize. You can check the status of the containers:
   ```bash
   docker ps
   ```

## System Health Check

Before running tests, it's a good idea to verify that all components are running correctly:

```bash
./check-system.sh
```

This script checks:
- If all containers are running
- If all required ports are accessible
- If all service endpoints are responding

If any issues are found, the script will provide guidance on how to fix them.

## Component Testing

### Testing Mailpit (Email Service)

Mailpit is a simple SMTP server and web interface for testing email functionality.

1. **Run the Mailpit test**:
   ```bash
   ./test-mailpit.sh
   ```

2. **Verify the results**:
   - Open http://localhost:8025 in your browser
   - You should see a test email from sender@example.com to recipient@example.com
   - Click on the email to view its contents

### Testing Welcome Email Service

The Welcome Email Service listens for MinIO events and sends welcome emails to new users.

1. **Run the Welcome Email test**:
   ```bash
   ./test-welcome-email.sh
   ```

2. **Verify the results**:
   - Open http://localhost:8025 in your browser
   - You should see a welcome email sent to directtest1@example.com
   - The email should contain a welcome message

### Testing Order Confirmation Email Service

The Order Confirmation Email Service listens for MinIO events and sends order confirmation emails to users.

1. **Run the Order Confirmation Email test**:
   ```bash
   ./test-order-confirmation-email.sh
   ```

2. **Verify the results**:
   - Open http://localhost:8025 in your browser
   - You should see an order confirmation email sent to ordertest@example.com
   - The email should contain order details including items, quantities, prices, and total

### Testing Integration

This test verifies that the entire pipeline works: MinIO triggers the welcome-email service, which sends an email via Mailpit.

1. **Run the Integration test**:
   ```bash
   ./test-integration.sh
   ```

2. **Verify the results**:
   - Open http://localhost:8025 in your browser
   - You should see a welcome email sent to integrationtest@example.com

## Application Testing

### Testing User Registration

1. **Access the authentication page**:
   - Open http://localhost:3000/auth.html in your browser

2. **Register a new user**:
   - Click on the "Register" tab
   - Fill in the registration form with:
     - Username: testuser
     - Email: testuser@example.com
     - Password: password123
   - Click the "Register" button

3. **Verify registration**:
   - You should be redirected to the login page
   - You should be able to log in with the credentials you just created
   - Check http://localhost:8025 to see if a welcome email was sent to testuser@example.com

### Testing Product Browsing

1. **Access the main page**:
   - Open http://localhost:3000 in your browser

2. **Browse products**:
   - You should see a list of products with images, names, and prices
   - Try filtering products by category using the navigation menu
   - Click on a product to view more details

### Testing Shopping Cart

1. **Add items to cart**:
   - Click the "Add to Cart" button on several products
   - The cart icon should update to show the number of items in the cart

2. **View cart**:
   - Click on the cart icon or navigate to http://localhost:3000/cart.html
   - Verify that all the items you added are in the cart
   - Try changing the quantity of an item
   - Try removing an item from the cart

### Testing Checkout Process

1. **Proceed to checkout**:
   - From the cart page, click the "Checkout" button
   - You should be redirected to http://localhost:3000/checkout.html

2. **Complete the checkout form**:
   - Fill in the shipping information
   - Fill in the payment information
   - Click the "Place Order" button

3. **Verify order confirmation**:
   - You should see an order confirmation message
   - Check http://localhost:8025 to see if an order confirmation email was sent
   - The email should contain all the items you ordered, their quantities, prices, and the total

## Database Testing

You can test the database directly using the PostgreSQL client:

```bash
docker exec -it simpleeshop-postgres psql -U techhub -d techgearhub
```

Once connected, you can run SQL queries to verify the database state:

```sql
-- Check users table
SELECT * FROM users;

-- Check products table
SELECT * FROM products;

-- Check orders table
SELECT * FROM orders;

-- Check order_items table
SELECT * FROM order_items;
```

## Running All Tests

To run all component tests in sequence:

```bash
./run-all-tests.sh
```

This script will:
1. Test Mailpit
2. Test the Welcome Email Service
3. Test the Order Confirmation Email Service
4. Test the integration between components
5. Provide a summary of the results

## Troubleshooting

### Common Issues

#### Welcome Email Service Issues

- **Service not running**:
  ```bash
  docker ps | grep welcome-email
  ```
  If not running:
  ```bash
  docker compose up -d welcome-email
  ```

- **Check logs for errors**:
  ```bash
  docker logs simpleeshop-welcome-email
  ```

- **Restart the service**:
  ```bash
  docker compose restart welcome-email
  ```

#### Order Confirmation Email Service Issues

- **Service not running**:
  ```bash
  docker ps | grep order-confirmation-email
  ```
  If not running:
  ```bash
  docker compose up -d order-confirmation-email
  ```

- **Check logs for errors**:
  ```bash
  docker logs simpleeshop-order-confirmation-email
  ```

- **Restart the service**:
  ```bash
  docker compose restart order-confirmation-email
  ```

#### MinIO Issues

- **Service not running**:
  ```bash
  docker ps | grep minio
  ```
  If not running:
  ```bash
  docker compose up -d minio
  ```

- **Check logs for errors**:
  ```bash
  docker logs simpleeshop-minio
  ```

- **Verify port is accessible**:
  ```bash
  nc -z localhost 9002
  ```

#### Mailpit Issues

- **Service not running**:
  ```bash
  docker ps | grep mailpit
  ```
  If not running:
  ```bash
  docker compose up -d mailpit
  ```

- **Check logs for errors**:
  ```bash
  docker logs simpleeshop-mailpit
  ```

- **Verify port is accessible**:
  ```bash
  nc -z localhost 1025
  nc -z localhost 8025
  ```

#### Web Application Issues

- **Service not running**:
  ```bash
  docker ps | grep simpleeshop-app
  ```
  If not running:
  ```bash
  docker compose up -d app
  ```

- **Check logs for errors**:
  ```bash
  docker logs simpleeshop-app
  ```

- **Verify port is accessible**:
  ```bash
  nc -z localhost 3000
  ```

### Restarting the System

If you encounter persistent issues, try restarting the entire system:

```bash
docker compose down
docker compose up -d
./check-system.sh
```

## Useful Commands

- **Start all services**: `docker compose up -d`
- **Stop all services**: `docker compose down`
- **View container logs**: `docker logs <container-name>`
- **Run all tests**: `./run-all-tests.sh`
- **Test welcome-email service**: `./test-welcome-email.sh`
- **Test order-confirmation-email service**: `./test-order-confirmation-email.sh`
- **Check Mailpit web interface**: http://localhost:8025
- **Check MinIO web interface**: http://localhost:9001
- **Check Web App**: http://localhost:3000
- **View welcome-email logs**: `docker logs simpleeshop-welcome-email`
- **View order-confirmation-email logs**: `docker logs simpleeshop-order-confirmation-email`
- **Restart welcome-email**: `docker compose restart welcome-email`
- **Restart order-confirmation-email**: `docker compose restart order-confirmation-email`