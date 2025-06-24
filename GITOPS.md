# GitOps Workflow for SimpleEshop

This document describes the GitOps workflow for SimpleEshop using Jenkins for CI (Continuous Integration) and ArgoCD for CD (Continuous Deployment).

## Overview

The GitOps workflow consists of the following components:

1. **Source Code Repository**: Contains the application source code, Jenkinsfile, and GitOps directory
2. **Jenkins**: Builds the Docker image and updates the GitOps directory
3. **ArgoCD**: Deploys the application to the Kubernetes cluster based on the GitOps directory

## Architecture

```
┌─────────────────────────────┐     ┌─────────────┐
│  Source Code Repository     │     │  Docker Hub │
│  (with GitOps Directory)    │     │  Registry   │
└───────────┬─────────────────┘     └─────────────┘
            │                              ▲
            │                              │
            ▼                              │
    ┌───────────────┐                      │
    │   Jenkins     │                      │
    │   (CI)        │──────────────────────┘
    └───────┬───────┘
            │
            │
            ▼
    ┌───────────────┐
    │   ArgoCD      │
    │   (CD)        │
    └───────┬───────┘
            │
            │
            ▼
    ┌───────────────┐
    │  Kubernetes   │
    │   Cluster     │
    └───────────────┘
```

## Workflow

1. Developer pushes code to the source code repository
2. Jenkins pipeline is triggered and:
   - Builds the Docker image
   - Pushes the Docker image to Docker Hub
   - Updates the image tag in the GitOps directory
3. ArgoCD detects the changes in the GitOps directory
4. ArgoCD automatically syncs the changes to the Kubernetes cluster

## Setup

### Prerequisites

- Kubernetes cluster with MicroK8s
- Jenkins installed in the cluster
- ArgoCD installed in the cluster
- GitHub repository for the SimpleEshop application (which includes the GitOps directory)

### Jenkins Configuration

1. Access Jenkins at http://<control-plane-ip>:30080
2. Install the following plugins:
   - Git
   - Docker
   - Pipeline
   - Credentials
3. Add the following credentials:
   - docker-hub-credentials (Username with password)
   - github-credentials (Username with password)
4. Create a pipeline job that uses the Jenkinsfile from the repository

### ArgoCD Configuration

1. Access ArgoCD at https://<control-plane-ip>:30443
2. Login with the admin credentials
3. The SimpleEshop application should be automatically configured
4. If not, create a new application with the following settings:
   - Name: simpleeshop
   - Project: default
   - Repository URL: https://github.com/Niroth36/SimpleEshop.git
   - Path: gitops
   - Destination: https://kubernetes.default.svc
   - Namespace: simpleeshop
   - Sync Policy: Automated

## GitOps Directory Structure

The GitOps directory in the main repository has the following structure:

```
gitops/
├── apps/
│   ├── database/
│   │   └── manifests/
│   │       ├── postgres-deployment.yaml
│   │       ├── postgres-init-configmap.yaml
│   │       ├── postgres-init-job.yaml
│   │       ├── postgres-pvc.yaml
│   │       └── postgres-service.yaml
│   └── simpleeshop/
│       └── manifests/
│           ├── simpleeshop-configmap.yaml
│           ├── simpleeshop-deployment.yaml
│           └── simpleeshop-service.yaml
└── infrastructure/
    └── namespaces/
        └── simpleeshop-namespace.yaml
```

## CI/CD Pipeline

The CI/CD pipeline is defined in the Jenkinsfile and consists of the following stages:

1. **Checkout**: Checks out the source code from the repository
2. **Build Docker Image**: Builds the Docker image and tags it with the build number and latest
3. **Push to Docker Hub**: Pushes the Docker image to Docker Hub
4. **Update Kubernetes Manifests**: Updates the image tag in the GitOps directory

## Security Considerations

- Sensitive information like passwords should be stored in Kubernetes Secrets
- Jenkins credentials should be properly secured
- ArgoCD should use HTTPS for the repository
- Consider using private Docker repositories for production environments

## Troubleshooting

### Jenkins Pipeline Fails

1. Check the Jenkins logs for errors
2. Verify that the Docker Hub credentials are correct
3. Verify that the GitHub credentials are correct
4. Ensure that the Docker daemon is running on the Jenkins agent

### ArgoCD Sync Fails

1. Check the ArgoCD logs for errors
2. Verify that the repository is accessible
3. Ensure that the Kubernetes manifests are valid
4. Check the ArgoCD application status for specific error messages

## Publishing Your Application

To publish your SimpleEshop application using the GitOps workflow, follow these steps:

### 1. Push Your Code to GitHub

```bash
# Clone the repository if you haven't already
git clone https://github.com/Niroth36/SimpleEshop.git
cd SimpleEshop

# Make your changes to the application code

# Commit and push your changes
git add .
git commit -m "Your commit message"
git push origin main
```

### 2. Monitor the Jenkins Pipeline

1. Go to your Jenkins server at http://<control-plane-ip>:30080
2. Find your pipeline job and check that it's running
3. The pipeline will automatically:
   - Build a Docker image from your code
   - Tag it with the build number and 'latest'
   - Push the image to Docker Hub (niroth36/simpleeshop)
   - Update the deployment manifest in the GitOps directory

### 3. Verify the Deployment in ArgoCD

1. Access ArgoCD at https://<control-plane-ip>:30443
2. Login with the admin credentials
3. Find the SimpleEshop application
4. Verify that it's synced and healthy
5. If it's not automatically syncing, click the "Sync" button

### 4. Access Your Published Application

Once deployed, you can access your application at:
```
http://<worker-node-ip>:30000
```

### 5. Verify the Deployment in Kubernetes

```bash
# SSH into your control plane node
ssh -i ~/.ssh/azure_rsa azureuser@<control-plane-ip>

# Check the deployment status
sg microk8s -c "microk8s kubectl get pods -n simpleeshop"
sg microk8s -c "microk8s kubectl get services -n simpleeshop"
```

### 6. Publish a New Version

To publish a new version of your application:

1. Make changes to your code
2. Commit and push to GitHub
3. The Jenkins pipeline will automatically build and push a new Docker image
4. ArgoCD will detect the changes and deploy the new version

## Conclusion

This GitOps workflow provides a robust and automated way to deploy SimpleEshop to a Kubernetes cluster. By separating the CI and CD processes, it ensures that the deployment is always in sync with the desired state defined in the GitOps directory.
