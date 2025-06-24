


# SimpleEshop - Docker Setup

A complete e-commerce application with Node.js, PostgreSQL, and Redis.

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- No other setup required!

### Email Testing with Mailpit
SimpleEshop uses Mailpit for email testing. When running locally with Docker Compose, you can access the Mailpit web interface at http://localhost:8025. 

In Kubernetes, Mailpit is deployed as part of the email services and can be accessed directly through any node in the cluster:

```
http://<control-plane-ip>:30025
```

Replace `<control-plane-ip>` with the IP address of your control plane node or any worker node in the cluster.

Alternatively, you can also use port-forwarding if direct access is not possible:

```bash
kubectl port-forward svc/mailpit-service -n simpleeshop 8025:8025
```

Then open http://localhost:8025 in your browser.

For detailed instructions on accessing Mailpit in Kubernetes, including troubleshooting tips and alternative access methods, see [MAILPIT-ACCESS.md](MAILPIT-ACCESS.md).

### GitOps Deployment
For production deployments, we use a GitOps workflow with Jenkins and ArgoCD. To publish your application, simply push your code to GitHub, and the CI/CD pipeline will automatically build, push, and deploy it. See [GITOPS.md](GITOPS.md) for detailed step-by-step instructions on how to publish and verify your deployment.

### Deployment Guide
For comprehensive step-by-step instructions on how to deploy the entire SimpleEshop infrastructure correctly, from provisioning cloud resources to deploying the application using GitOps, see [DEPLOYMENT.md](DEPLOYMENT.md).

### Infrastructure Documentation
For detailed information about all the technologies used in this project, including OpenTofu (formerly Terraform), Ansible, Kubernetes, Docker, and more, see [INFRASTRUCTURE.md](INFRASTRUCTURE.md).

### Run the Application

1. **Download the files:**
   ```bash
   # Clone the repository
   git clone https://github.com/<YOUR_GITHUB_USERNAME>/SimpleEshop.git
   cd SimpleEshop
   ```

2. **Start the application:**
   ```bash
   # Start all services (database, redis, web app)
   docker compose up -d
   ```

3. **Access the application:**
   - **Web App**: http://localhost:3000
   - **Database**: PostgreSQL on port 5432 (if needed)
   - **Redis**: Redis on port 6379 (if needed)

### 🔍 Check if Everything is Running

```bash
# Check container status
docker ps

# Check logs
docker compose logs app

# Test the application
curl http://localhost:3000
```

### 🛑 Stop the Application

```bash
# Stop all services
docker compose down

# Stop and remove data (complete cleanup)
docker compose down -v
```

### 🧪 Testing Locally

For comprehensive instructions on how to test SimpleEshop locally, see [LOCAL-TESTING.md](LOCAL-TESTING.md).

This guide covers:
- Setting up the local testing environment
- Running system health checks
- Component testing (email services, integration)
- Application testing (user registration, shopping cart, checkout)
- Database testing
- Troubleshooting common issues

You can run all tests with:
```bash
./run-all-tests.sh
```

## 🎯 Features

- ✅ **Complete PostgreSQL database** with sample products
- ✅ **Redis session storage**
- ✅ **User authentication** (register/login)
- ✅ **Shopping cart functionality**
- ✅ **Checkout process**
- ✅ **Automatic database initialization**
- ✅ **MinIO object storage** for user data
- ✅ **Standalone welcome-email service** for event-driven processing
- ✅ **Standalone order-confirmation-email service** for sending order invoices
- ✅ **Mailpit email testing** for all email notifications

## 🐛 Troubleshooting

### Application won't start
```bash
# Check logs
docker compose logs

# Restart services
docker compose restart
```

### Database connection issues
```bash
# Check database is healthy
docker compose ps
docker compose logs postgres
```

### Port conflicts
If you get port conflicts, edit `docker-compose.yml`:
```yaml
ports:
  - "3001:3000"  # Change 3000 to 3001 for the app
  - "5433:5432"  # Change 5432 to 5433 for database
```

## 📊 Default Data

The application starts with sample products:
- CPUs (Intel, AMD)
- RAM modules
- Storage devices
- Graphics cards

You can register a new account and start shopping immediately!

## 🏗️ Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Web App   │◄──►│ PostgreSQL  │    │    Redis    │
│  (Node.js)  │    │ (Database)  │    │ (Sessions)  │
│  Port 3000  │    │  Port 5432  │    │  Port 6379  │
└──────┬──────┘    └─────────────┘    └─────────────┘
       │
       │           ┌─────────────┐    ┌─────────────┐
       │           │    MinIO    │───►│ Welcome-Email│
       └──────────►│  (Storage)  │    │  (Service)  │
                   │  Port 9002  │    │  Port 8080  │
                   └──────┬──────┘    └──────┬──────┘
                          │                  │
                          │                  │
                          │                  │
                          │                  │
                          │                  │
                          │                  │
                          │                  │
                          │                  ▼
                          │           ┌─────────────┐
                          │           │   Mailpit   │
                          │           │   (Email)   │
                          │           │  Port 8025  │
                          │           └─────────────┘
                          │                  ▲
                          │                  │
                          │                  │
                          │    ┌────────────────────────┐
                          └───►│ Order-Confirmation-Email│
                               │       (Service)        │
                               │       Port 8081        │
                               └────────────────────────┘
```

All services run in isolated Docker containers with persistent data storage. The architecture follows an event-driven approach:

1. When a user registers, their data is stored in PostgreSQL
2. The user data is also sent to MinIO as a JSON file
3. MinIO triggers the welcome-email service via bucket notifications
4. The welcome-email service sends a welcome email via Mailpit

Similarly, for order confirmations:
1. When a user submits an order, the order data is stored in PostgreSQL
2. The order data is also sent to MinIO as a JSON file
3. MinIO triggers the order-confirmation-email service via bucket notifications
4. The order-confirmation-email service sends an order confirmation email with order details via Mailpit

## 🚀 Welcome Email Service

SimpleEshop includes a standalone welcome-email service that listens for MinIO events and sends welcome emails to new users.

### Welcome Email Service

This service is triggered when a new user registers. It sends a welcome email to the user via Mailpit.

To test this service:
```bash
# Run the test script
./test-welcome-email.sh
```

The welcome email service:
1. Listens for bucket notifications from MinIO
2. When a new user registration JSON file is uploaded, it processes the event
3. Extracts the user's email address and username from the JSON file
4. Sends a welcome email to the user via Mailpit
5. Logs the success message with the recipient's email address

You can extend this service to include more sophisticated email templates or additional functionality.

### Integration Testing

To test the integration between MinIO, the welcome-email service, and Mailpit:
```bash
# Run the integration test script
./test-integration.sh
```

This test uploads a user registration JSON file to MinIO, which triggers the welcome-email service to send an email via Mailpit.

## 🧾 Order Confirmation Email Service

SimpleEshop includes a standalone order-confirmation-email service that listens for MinIO events and sends order confirmation emails to users when they submit an order.

### Order Confirmation Email Service

This service is triggered when a user submits an order. It sends an order confirmation email with order details to the user via Mailpit.

To test this service:
```bash
# Run the test script
./test-order-confirmation-email.sh
```

The order confirmation email service:
1. Listens for bucket notifications from MinIO
2. When a new order JSON file is uploaded, it processes the event
3. Extracts the order details including items, prices, quantities, and total
4. Generates a formatted email with a detailed order summary
5. Sends the order confirmation email to the user via Mailpit
6. Logs the success message with the recipient's email address and order ID

The email includes a nicely formatted table with the order items, quantities, prices, and subtotals, as well as the order total.

## 🚢 Kubernetes-Optimized Email Services

For Kubernetes deployments, the email services have been optimized with:

1. **Kubernetes Manifests**: Deployment, Service, and ConfigMap resources
2. **Health Checks**: HTTP endpoints for readiness and liveness probes
3. **Resource Management**: CPU and memory requests and limits
4. **Configuration**: Externalized in ConfigMaps
5. **CI/CD Integration**: Automated builds and deployments

See the [kubernetes/email-services](kubernetes/email-services) directory for the Kubernetes manifests and deployment instructions.
