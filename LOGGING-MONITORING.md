# Logging and Monitoring Setup for SimpleEshop

This document describes the logging and monitoring solution implemented for SimpleEshop, which provides centralized logging and metrics collection for better observability of the application.

## Overview

The solution consists of the following components:

1. **Simple Console Logger** - A lightweight logging utility for Node.js applications
2. **Loki** - A log aggregation system for collecting and querying logs
3. **Prometheus** - A monitoring system and time series database
4. **Grafana** - A visualization and analytics platform

## Logging with Simple Console Logger

A lightweight console-based logger is used for structured logging in the application. It provides multiple log levels (error, warn, info, http, debug) and outputs logs to the console with consistent formatting.

### How it works

- Logs are written to the console (stdout/stderr)
- Each log entry includes a timestamp and log level
- Log entries are formatted consistently for easy parsing by log aggregation tools like Loki
- Log levels are respected based on the environment (development vs. production)

### Log Levels

- **error** - Critical errors that require immediate attention
- **warn** - Warning conditions that should be addressed
- **info** - Informational messages about normal operation
- **http** - HTTP request/response logs
- **debug** - Detailed debugging information (only in development)

### Implementation Details

The logger is implemented in `web-app/server/utils/logger.js` with the following features:

- **Environment-based log levels**: In development, all logs are shown (debug level). In production, only info level and above are shown.
- **Timestamp formatting**: All logs include a timestamp in ISO format.
- **Console output**: Logs are sent to the console using the appropriate methods (console.error, console.warn, console.info, etc.).
- **Simple interface**: The logger provides a clean, simple interface that's easy to use throughout the application.

### Integration in the Application

The logger is integrated throughout the application:

1. **Main Server**: The logger is imported in `server.js` and used for server startup, database connections, and API endpoint logging.
2. **Email Services**: Both welcome-email and order-confirmation-email services use the logger with a fallback mechanism:
   - They try to import the logger from `../../utils/logger`
   - If the import fails (e.g., when running as standalone services), they fall back to a simple console-based logger

### Deployment Across Services

The logger is deployed across all services in the SimpleEshop application:

1. **Main Application**: The logger is directly integrated into the main server.
2. **Microservices**: Each microservice (welcome-email, order-confirmation-email) uses the same logger interface.
3. **Kubernetes Deployment**: When deployed in Kubernetes, logs are written to stdout/stderr, which are collected by Promtail and sent to Loki for centralized log aggregation.

### Log Storage and Management

Logs are written to stdout/stderr, which is the recommended approach for containerized applications:

- In Docker containers, logs are captured by the Docker logging driver
- In Kubernetes, logs are captured by the container runtime and accessible via `kubectl logs`
- For centralized logging, Promtail collects logs from all pods and sends them to Loki

This approach follows the [12-factor app methodology](https://12factor.net/logs), treating logs as event streams and allowing the execution environment to handle log routing, storage, and rotation.

#### Centralized Log Storage with Loki

Loki provides centralized log storage and querying capabilities:

1. **Collection**: Promtail runs as a DaemonSet in Kubernetes, collecting logs from all pods
2. **Storage**: Logs are stored in Loki with efficient indexing
3. **Querying**: Logs can be queried using LogQL through Grafana
4. **Retention**: Log retention policies can be configured in Loki

This setup eliminates the need for persistent volumes for logs in each pod, as all logs are centrally stored and accessible through Grafana.

### Security Considerations for Logging

When implementing logging, consider the following security aspects:

1. **Sensitive Data**: Ensure that sensitive data (passwords, tokens, personal information) is not logged.
2. **Log Rotation**: Implement log rotation to prevent logs from consuming all available disk space.
3. **Access Control**: Restrict access to log files to authorized personnel only.
4. **Log Integrity**: Consider using append-only logs to prevent tampering.
5. **Compliance**: Ensure logging practices comply with relevant regulations (GDPR, HIPAA, etc.).

## Monitoring with Prometheus and Grafana

Prometheus collects metrics from the application and stores them in a time series database. Grafana visualizes these metrics in dashboards.

### How Monitoring Works

1. **Metrics Collection**:
   - The application exposes metrics at the `/metrics` endpoint using the `prom-client` library
   - Prometheus scrapes these metrics at regular intervals (every 15 seconds by default)
   - Metrics are stored in Prometheus's time-series database

2. **Visualization**:
   - Grafana connects to Prometheus as a data source
   - Dashboards in Grafana query Prometheus data using PromQL
   - Visualizations are updated in real-time as new data is collected

3. **Integration Flow**:
   - Application code uses `metrics.js` utility to record metrics
   - Express middleware measures HTTP request durations
   - Circuit breaker updates its state metrics
   - Prometheus scrapes all metrics from the `/metrics` endpoint
   - Grafana displays the metrics in customizable dashboards

### Implementation Details

The metrics system is implemented in `web-app/server/utils/metrics.js` with the following components:

- **Registry**: A Prometheus registry that holds all metrics
- **Default Metrics**: System metrics like CPU and memory usage
- **Custom Metrics**: Application-specific metrics for HTTP requests, database queries, and circuit breakers
- **Middleware**: Express middleware to measure request durations
- **Helper Functions**: Functions to update metrics from different parts of the application

### Metrics Collected

- **HTTP Request Duration** - Duration of HTTP requests in seconds
- **HTTP Request Count** - Total number of HTTP requests
- **Database Query Duration** - Duration of database queries in seconds
- **Circuit Breaker State** - Current state of circuit breakers (closed, half-open, open)
- **Circuit Breaker Failures** - Total number of circuit breaker failures
- **Circuit Breaker Successes** - Total number of circuit breaker successes
- **System Metrics** - CPU, memory, and other system metrics

### Accessing Metrics

- Prometheus metrics are exposed at `/metrics` endpoint on the application
- Prometheus UI is available at `http://<prometheus-service>:9090`
- Grafana dashboards are available at `http://<grafana-service>:3000`

## Deployment

### Prerequisites

- Kubernetes cluster with SimpleEshop deployed
- kubectl configured to access the cluster

### Infrastructure Security Rules

If you're using Azure infrastructure as defined in the Terraform configuration, you need to add security rules for Prometheus and Loki in the worker_nsg:

```hcl
# Prometheus
security_rule {
  name                       = "Prometheus"
  priority                   = 1009
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "9090"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}

# Loki
security_rule {
  name                       = "Loki"
  priority                   = 1010
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "3100"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}
```

Add these rules to the `azurerm_network_security_group.worker_nsg` resource in `infrastructure/azure/main.tf`.

### Deploying Prometheus

```bash
kubectl apply -f kubernetes/prometheus/prometheus-configmap.yaml
kubectl apply -f kubernetes/prometheus/prometheus-pvc.yaml
kubectl apply -f kubernetes/prometheus/prometheus-deployment.yaml
kubectl apply -f kubernetes/prometheus/prometheus-service.yaml
```

### Deploying Loki (Log Aggregation)

```bash
# Deploy Loki
kubectl apply -f kubernetes/loki/loki-configmap.yaml
kubectl apply -f kubernetes/loki/loki-pvc.yaml
kubectl apply -f kubernetes/loki/loki-deployment.yaml
kubectl apply -f kubernetes/loki/loki-service.yaml

# Deploy Promtail (log collector)
kubectl apply -f kubernetes/promtail/promtail-configmap.yaml
kubectl apply -f kubernetes/promtail/promtail-daemonset.yaml
```

### Configuring Grafana

```bash
kubectl apply -f kubernetes/grafana/grafana-datasource-configmap.yaml
kubectl apply -f kubernetes/grafana/grafana-deployment.yaml
kubectl apply -f kubernetes/grafana/grafana-pvc.yaml
kubectl apply -f kubernetes/grafana/grafana-service.yaml
```

### Updating Application Dependencies

Make sure to install the required dependencies:

```bash
npm install prom-client --save
```

Note: The Simple Console Logger doesn't require any external dependencies as it uses the built-in `console` methods.

## Accessing the Dashboards

### Prometheus

```bash
kubectl port-forward svc/prometheus 9090:9090 -n simpleeshop
```

Then open http://localhost:9090 in your browser.

### Grafana

```bash
kubectl port-forward svc/grafana 3000:3000 -n simpleeshop
```

Then open http://localhost:3000 in your browser.

Default credentials:
- Username: admin
- Password: admin

## Creating Dashboards in Grafana

1. Log in to Grafana
2. Click on "Create your first dashboard"
3. Click on "Add new panel"
4. Select "Prometheus" as the data source
5. Use PromQL queries to visualize metrics, for example:
   - `http_request_duration_seconds_count` - Total number of HTTP requests
   - `http_request_duration_seconds_bucket` - HTTP request duration histogram
   - `circuit_breaker_state` - Current state of circuit breakers

## Troubleshooting

### Logs not appearing

- Check that your application is running and outputting logs to the console
- Verify that the Simple Console Logger is properly imported and used
- Ensure that Promtail is running and configured to collect logs from your pods

### Metrics not appearing in Prometheus

- Check if the `/metrics` endpoint is accessible
- Verify that Prometheus is running and configured to scrape the application
- Check Prometheus targets in the Prometheus UI

### Grafana not showing data

- Verify that Prometheus is configured as a data source in Grafana
- Check if Prometheus is returning data for the queries used in dashboards

## How to Access Logs

There are two ways to access logs in SimpleEshop:

1. **Command Line Access**: Direct access to log files and container logs
2. **Browser-Based Access**: Using Grafana and Loki for a centralized, searchable log viewer

### Browser-Based Log Viewing with Grafana and Loki

SimpleEshop includes a browser-based log viewing solution using Grafana and Loki, similar to commercial services like logz.io. This provides a centralized place to view, search, and analyze logs from all services.

#### Accessing the Log Viewer

1. Access Grafana in your browser:
   ```bash
   kubectl port-forward svc/grafana 3000:3000 -n simpleeshop
   ```
   Then open http://localhost:3000 in your browser.

2. Log in with the default credentials:
   - Username: admin
   - Password: admin

3. Navigate to "Explore" in the left sidebar

4. Select "Loki" as the data source in the dropdown at the top

5. Use LogQL queries to search and filter logs:
   - `{app="simpleeshop"}` - All logs from the SimpleEshop application
   - `{app="simpleeshop"} |= "error"` - All error logs
   - `{namespace="simpleeshop", container="welcome-email"}` - Logs from the welcome-email service

#### Creating a Log Dashboard

1. In Grafana, click on "+" in the left sidebar and select "Dashboard"
2. Click "Add new panel"
3. Select "Loki" as the data source
4. Enter a LogQL query like `{namespace="simpleeshop"}`
5. Switch from "Time series" to "Logs" visualization
6. Click "Apply" to add the panel to your dashboard
7. Save the dashboard with a name like "SimpleEshop Logs"

### Command Line Access

You can also access logs directly via command line in different environments:

#### Local Development Environment

When running the application locally, logs are written to both the console and to files in the `logs` directory:

```bash
# View logs in real-time in the console
npm start

# View log files
cat logs/combined.log    # All logs
cat logs/error.log       # Error logs only

# Follow logs in real-time
tail -f logs/combined.log
```

Example log output:
```
2023-11-15 14:23:45:123 info: Server running on http://0.0.0.0:3000
2023-11-15 14:23:45:125 info: Metrics available at http://0.0.0.0:3000/metrics
2023-11-15 14:24:12:456 info: Connected to MySQL database successfully
2023-11-15 14:25:33:789 error: Failed to send welcome email: Connection refused
```

#### Docker Environment

When running the application in Docker, logs are written inside the container:

```bash
# View logs from Docker container
docker logs simpleeshop-server

# Follow logs in real-time
docker logs -f simpleeshop-server

# If using docker-compose
docker-compose logs server
docker-compose logs -f server
```

You can also access the log files inside the container:

```bash
# Execute a shell in the container
docker exec -it simpleeshop-server bash

# View log files
cat /app/logs/combined.log
```

#### Kubernetes Environment

In Kubernetes, each pod has its own logs:

```bash
# List all pods in the simpleeshop namespace
kubectl get pods -n simpleeshop

# View logs for a specific pod
kubectl logs <pod-name> -n simpleeshop

# Follow logs in real-time
kubectl logs -f <pod-name> -n simpleeshop

# If there are multiple containers in the pod, specify the container
kubectl logs <pod-name> -c <container-name> -n simpleeshop
```

To access the log files inside the pod:

```bash
# Execute a shell in the pod
kubectl exec -it <pod-name> -n simpleeshop -- bash

# View log files
ls -la /app/logs
cat /app/logs/combined.log
cat /app/logs/error.log
```

For email service logs:

```bash
# Get email service pods
kubectl get pods -n simpleeshop -l app=welcome-email-service
kubectl get pods -n simpleeshop -l app=order-confirmation-email-service

# View logs for email services
kubectl logs <welcome-email-pod-name> -n simpleeshop
kubectl logs <order-confirmation-email-pod-name> -n simpleeshop
```

## Verification and Testing

After deploying the logging and monitoring setup, you should verify that everything is working correctly:

### Verifying Logging

1. **Check Log Files**:
   ```bash
   # Connect to your application pod
   kubectl exec -it <pod-name> -n simpleeshop -- bash

   # Check if log files exist
   ls -la /app/logs

   # View log content
   cat /app/logs/combined.log
   ```

2. **Generate Test Logs**:
   ```bash
   # Make some API requests to generate logs
   curl http://<app-url>/api/products
   ```

3. **Check for Log Rotation**:
   - If you've been running the application for a while, verify that log rotation is working by checking the log file sizes and dates.

### Verifying Monitoring

1. **Check Prometheus Targets**:
   - Access the Prometheus UI at http://<prometheus-url>:9090/targets
   - Verify that all targets are in the "UP" state

2. **Check Metrics Endpoint**:
   ```bash
   # Access the metrics endpoint directly
   curl http://<app-url>/metrics
   ```

3. **Test Grafana Dashboards**:
   - Log in to Grafana
   - Open your dashboards and verify that they're displaying data
   - Try changing the time range to ensure historical data is available

## Conclusion

This logging and monitoring setup provides comprehensive observability for SimpleEshop, allowing you to:

1. Track and analyze application logs through a browser-based interface
2. Monitor application performance metrics
3. Set up alerts for critical conditions
4. Visualize application health and performance
5. Search and filter logs across all services from a single interface

The implementation is complete and includes:
- Simple Console Logger for structured logging across all services
- Loki for log aggregation and querying
- Promtail for log collection from Kubernetes pods
- Prometheus for metrics collection
- Grafana for visualization of both logs and metrics
- Security considerations for both logging and monitoring
- Infrastructure updates for proper network access

This solution provides functionality similar to commercial services like logz.io, but using open-source components that you control. The browser-based log viewer in Grafana gives you a powerful interface to search, filter, and analyze logs from all your services in one place.

For more advanced configurations, refer to the official documentation:
- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)
- [Grafana Documentation](https://grafana.com/docs/)
- [12-Factor App - Logs](https://12factor.net/logs)
