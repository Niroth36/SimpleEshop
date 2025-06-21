# Email Services for Kubernetes

This directory contains Kubernetes manifests for deploying the email services used by SimpleEshop.

## Services

### Welcome Email Service

The Welcome Email Service listens for MinIO bucket notifications and sends welcome emails to new users when they register.

- **Deployment**: `welcome-email-deployment.yaml`
- **Service**: `welcome-email-service.yaml`
- **ConfigMap**: `welcome-email-configmap.yaml`

### Order Confirmation Email Service

The Order Confirmation Email Service listens for MinIO bucket notifications and sends order confirmation emails to users when they place an order.

- **Deployment**: `order-confirmation-email-deployment.yaml`
- **Service**: `order-confirmation-email-service.yaml`
- **ConfigMap**: `order-confirmation-email-configmap.yaml`

## Deployment

To deploy these services, apply the manifests in the following order:

```bash
# Create ConfigMaps first
kubectl apply -f welcome-email-configmap.yaml
kubectl apply -f order-confirmation-email-configmap.yaml

# Create Deployments
kubectl apply -f welcome-email-deployment.yaml
kubectl apply -f order-confirmation-email-deployment.yaml

# Create Services
kubectl apply -f welcome-email-service.yaml
kubectl apply -f order-confirmation-email-service.yaml
```

Or apply all at once using kustomize:

```bash
kubectl apply -k .
```

A `kustomization.yaml` file is provided for easier deployment with kustomize.

## Configuration

The email services are configured using ConfigMaps. The following environment variables can be configured:

- `MINIO_HOST`: The hostname of the MinIO service
- `MINIO_PORT`: The port of the MinIO service
- `MINIO_ACCESS_KEY`: The access key for MinIO
- `MINIO_SECRET_KEY`: The secret key for MinIO
- `SMTP_HOST`: The hostname of the SMTP server
- `SMTP_PORT`: The port of the SMTP server

## Kubernetes Integration

These services have been optimized for Kubernetes deployment with:

1. **Health Checks**: Both services expose HTTP endpoints for health checking
2. **Resource Limits**: CPU and memory limits are defined to prevent resource starvation
3. **ConfigMaps**: Configuration is externalized in ConfigMaps
4. **Services**: Kubernetes Services for service discovery
5. **Docker Images**: Optimized Docker images with proper health checks

## CI/CD Integration

The email services are integrated into the CI/CD pipeline:

1. Jenkins builds the Docker images using the `Dockerfile.k8s` files
2. Images are pushed to Docker Hub
3. ArgoCD deploys the services to the Kubernetes cluster

## Troubleshooting

If the services are not working correctly, check the following:

1. Verify that the pods are running:
   ```bash
   kubectl get pods -n simpleeshop -l tier=backend
   ```

2. Check the logs for errors:
   ```bash
   kubectl logs -n simpleeshop deployment/welcome-email
   kubectl logs -n simpleeshop deployment/order-confirmation-email
   ```

3. Verify that the services can connect to MinIO and the SMTP server:
   ```bash
   kubectl exec -it -n simpleeshop deployment/welcome-email -- wget -O- minio-service:9000
   kubectl exec -it -n simpleeshop deployment/welcome-email -- wget -O- mailpit-service:1025
   ```
