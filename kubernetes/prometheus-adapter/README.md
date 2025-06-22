# Prometheus Adapter for SimpleEshop

This directory contains Kubernetes manifests for deploying the Prometheus Adapter, which exposes Prometheus metrics as Kubernetes custom metrics.

## Overview

The Prometheus Adapter is a component that allows Kubernetes to use Prometheus metrics for scaling decisions. It converts Prometheus metrics into Kubernetes custom metrics, which can be used by the Horizontal Pod Autoscaler (HPA).

## Configuration

The Prometheus Adapter is configured to expose the following metrics:

1. **HTTP Request Rate**: The number of HTTP requests per second, exposed as `http_requests_per_second`

These metrics are used by the HPA to scale the SimpleEshop application.

## Deployment

To deploy the Prometheus Adapter, run the following command:

```bash
kubectl apply -k kubernetes/prometheus-adapter/
```

Alternatively, you can use the `deploy-all.sh` script to deploy the entire SimpleEshop infrastructure, including the Prometheus Adapter:

```bash
./kubernetes/scripts/deploy-all.sh
```

## Verifying the Installation

To verify that the Prometheus Adapter is working correctly, run the following command:

```bash
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1" | jq .
```

You should see a list of available metrics, including `http_requests_per_second`.

To check the value of a specific metric, run:

```bash
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/simpleeshop/services/simpleeshop-service/http_requests_per_second" | jq .
```

## Troubleshooting

If the Prometheus Adapter is not working correctly, check the logs:

```bash
kubectl logs -n simpleeshop -l app=prometheus-adapter
```

Common issues include:

1. **Prometheus not accessible**: Make sure Prometheus is running and accessible at the URL specified in the Prometheus Adapter deployment.
2. **Metrics not available**: Make sure the SimpleEshop application is exposing metrics and Prometheus is scraping them.
3. **Configuration errors**: Check the Prometheus Adapter configuration for syntax errors.