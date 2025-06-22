# Monitoring and Scaling for SimpleEshop

This directory contains Kubernetes manifests for deploying Prometheus to monitor the SimpleEshop application.

## Overview

The monitoring and scaling solution consists of the following components:

1. **Prometheus**: Collects and stores metrics from the SimpleEshop application
2. **Prometheus Adapter**: Exposes Prometheus metrics as Kubernetes custom metrics
3. **Horizontal Pod Autoscaler (HPA)**: Scales the SimpleEshop application based on metrics

## Metrics

The SimpleEshop application exposes the following metrics:

1. **HTTP Request Rate**: The number of HTTP requests per second
2. **HTTP Response Time**: The duration of HTTP requests in milliseconds

These metrics are collected by Prometheus and used by the HPA to scale the application.

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

## Accessing Prometheus

Prometheus is exposed as a NodePort service on port 30090. You can access it at:

```
http://<node-ip>:30090
```

## Scaling Configuration

The HPA is configured to scale the SimpleEshop application based on the following metrics:

1. **CPU Utilization**: Scales up when CPU utilization exceeds 50%
2. **HTTP Request Rate**: Scales up when the request rate exceeds 10 requests per second

The HPA will scale the application between 1 and 10 replicas based on these metrics.

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