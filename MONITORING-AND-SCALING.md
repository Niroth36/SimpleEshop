# Monitoring and Scaling for SimpleEshop

This document describes the monitoring and scaling solution implemented for the SimpleEshop application.

## Overview

The monitoring and scaling solution consists of the following components:

1. **Application Metrics**: The SimpleEshop application exposes metrics using the Prometheus client library
2. **Prometheus**: Collects and stores metrics from the SimpleEshop application
3. **Prometheus Adapter**: Exposes Prometheus metrics as Kubernetes custom metrics
4. **Horizontal Pod Autoscaler (HPA)**: Scales the SimpleEshop application based on metrics

## Metrics

The SimpleEshop application exposes the following metrics:

1. **HTTP Request Rate**: The number of HTTP requests per second
2. **HTTP Response Time**: The duration of HTTP requests in milliseconds

These metrics are collected by Prometheus and used by the HPA to scale the application.

## Implementation Details

### Application Metrics

The SimpleEshop application has been modified to expose metrics using the Prometheus client library. The following changes were made:

1. Added the `prom-client` dependency to `package.json`
2. Initialized Prometheus metrics in `server_postgresql.js`
3. Added middleware to track HTTP request metrics
4. Added a `/metrics` endpoint to expose the metrics to Prometheus

### Prometheus

Prometheus is deployed as a Kubernetes deployment with the following configuration:

1. A ConfigMap containing the Prometheus configuration
2. A Deployment running the Prometheus server
3. A Service exposing Prometheus on port 30090

Prometheus is configured to scrape metrics from the SimpleEshop application using Kubernetes service discovery.

### Prometheus Adapter

The Prometheus Adapter is deployed as a Kubernetes deployment with the following configuration:

1. A ConfigMap containing the adapter configuration
2. A Deployment running the Prometheus Adapter
3. A Service exposing the adapter

The adapter is configured to expose the HTTP request rate metric as a Kubernetes custom metric.

### Horizontal Pod Autoscaler

The HPA is configured to scale the SimpleEshop application based on the following metrics:

1. **CPU Utilization**: Scales up when CPU utilization exceeds 50%
2. **HTTP Request Rate**: Scales up when the request rate exceeds 10 requests per second

The HPA will scale the application between 1 and 10 replicas based on these metrics.

## Deployment

To deploy the monitoring and scaling solution, run the following commands:

```bash
# Deploy Prometheus
kubectl apply -k kubernetes/prometheus/

# Deploy Prometheus Adapter
kubectl apply -k kubernetes/prometheus-adapter/

# Deploy HPA
kubectl apply -f kubernetes/applications/simpleeshop-hpa.yaml
```

Alternatively, you can use the `deploy-all.sh` script to deploy the entire SimpleEshop infrastructure, including the monitoring and scaling solution:

```bash
./kubernetes/scripts/deploy-all.sh
```

## Accessing the Monitoring Tools

### Prometheus

Prometheus is exposed as a NodePort service on port 30090. You can access it at:

```
http://<node-ip>:30090
```

### Grafana

Grafana is exposed as a NodePort service on port 30030. You can access it at:

```
http://<node-ip>:30030
```

Default credentials:
- Username: admin
- Password: admin

## Testing the Scaling

You can test the scaling by generating load on the SimpleEshop application:

```bash
# Install hey (a load testing tool)
go get -u github.com/rakyll/hey

# Generate load
hey -n 1000 -c 100 http://<node-ip>:30000/
```

Then check the HPA status:

```bash
kubectl get hpa -n simpleeshop
```

You should see the HPA scaling the application based on the metrics.

## Conclusion

This monitoring and scaling solution provides automatic scaling for the SimpleEshop application based on CPU utilization and HTTP request rate. It ensures that the application can handle varying loads efficiently, scaling up during high traffic periods and scaling down during low traffic periods to save resources.