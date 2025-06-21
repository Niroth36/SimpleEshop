# SimpleEshop Infrastructure Documentation

This document provides a comprehensive overview of all the technologies used in the SimpleEshop project, including infrastructure provisioning, configuration management, containerization, orchestration, CI/CD, and application components.

## Table of Contents

- [OpenTofu (formerly Terraform)](#opentofu-formerly-terraform)
- [Ansible](#ansible)
- [Kubernetes and MicroK8s](#kubernetes-and-microk8s)
- [Docker and Containerization](#docker-and-containerization)
- [Jenkins (CI)](#jenkins-ci)
- [ArgoCD (CD)](#argocd-cd)
- [Azure Cloud](#azure-cloud)
- [PostgreSQL](#postgresql)
- [Redis](#redis)
- [MinIO](#minio)
- [Mailpit](#mailpit)
- [Node.js](#nodejs)

## OpenTofu (formerly Terraform)

### Overview
OpenTofu is an open-source infrastructure as code (IaC) tool that allows you to define and provision infrastructure resources using a declarative configuration language. It was forked from Terraform and maintains compatibility with Terraform's HCL (HashiCorp Configuration Language).

### How It's Used in SimpleEshop
In this project, OpenTofu is used to provision the Azure infrastructure, including:
- Resource Group
- Virtual Network and Subnets
- Network Security Groups
- Public IPs
- Virtual Machines (Control Plane and Workers)
- Auto-shutdown schedules

### Key Files and Directories
- `infrastructure/azure/main.tf`: Main configuration file defining all Azure resources
- `infrastructure/azure/variables.tf`: Variable definitions
- `infrastructure/azure/outputs.tf`: Output definitions
- `infrastructure/azure/terraform.tfstate`: State file (should be stored in a remote backend in production)

### Usage Instructions
```bash
# Navigate to the infrastructure directory
cd infrastructure/azure

# Initialize OpenTofu
tofu init

# Plan the infrastructure changes
tofu plan -var-file=terraform.vars

# Apply the infrastructure changes
tofu apply -var-file=terraform.vars

# Destroy the infrastructure when no longer needed
tofu destroy -var-file=terraform.vars
```

## Ansible

### Overview
Ansible is an open-source automation tool that enables infrastructure as code. It uses a declarative language to describe system configurations and automates the provisioning, configuration management, and application deployment.

### How It's Used in SimpleEshop
Ansible is used to configure the virtual machines provisioned by OpenTofu, specifically:
- Installing and configuring MicroK8s on all nodes
- Setting up the Kubernetes control plane
- Joining worker nodes to the cluster
- Installing and configuring Jenkins and ArgoCD for CI/CD

### Key Files and Directories
- `ansible/playbooks/site.yml`: Main playbook that orchestrates all other playbooks
- `ansible/playbooks/microk8s/`: Playbooks for MicroK8s installation and configuration
- `ansible/playbooks/jenkins/`: Playbooks for Jenkins installation
- `ansible/playbooks/argocd/`: Playbooks for ArgoCD installation
- `ansible/inventories/`: Inventory files defining the hosts

### Usage Instructions
```bash
# Navigate to the ansible directory
cd ansible

# Run the main playbook
ansible-playbook playbooks/site.yml -i inventories/azure/hosts.yml

# Run specific playbooks
ansible-playbook playbooks/microk8s/clean-install.yml -i inventories/azure/hosts.yml
ansible-playbook playbooks/jenkins/install.yml -i inventories/azure/hosts.yml
ansible-playbook playbooks/argocd/install.yml -i inventories/azure/hosts.yml
```

## Kubernetes and MicroK8s

### Overview
Kubernetes is an open-source container orchestration platform that automates the deployment, scaling, and management of containerized applications. MicroK8s is a lightweight, production-ready Kubernetes distribution that can be installed on Linux systems.

### How It's Used in SimpleEshop
Kubernetes (via MicroK8s) is used to orchestrate the SimpleEshop application containers, providing:
- Deployment management
- Service discovery and load balancing
- Storage orchestration
- Self-healing capabilities
- Horizontal scaling

### Key Files and Directories
- `kubernetes/applications/`: Kubernetes manifests for the SimpleEshop application
- `kubernetes/database/`: Kubernetes manifests for the PostgreSQL database
- `kubernetes/namespaces/`: Namespace definitions
- `kubernetes/argocd/`: ArgoCD application manifests
- `kubernetes/scripts/`: Utility scripts for Kubernetes operations

### Usage Instructions
```bash
# Apply namespace
kubectl apply -f kubernetes/namespaces/simpleeshop-namespace.yaml

# Deploy the database
kubectl apply -f kubernetes/database/

# Deploy the application
kubectl apply -f kubernetes/applications/

# Check deployment status
kubectl get pods -n simpleeshop
kubectl get services -n simpleeshop
```

## Docker and Containerization

### Overview
Docker is a platform that enables developers to build, package, and distribute applications as containers. Containers are lightweight, portable, and self-sufficient units that include everything needed to run an application.

### How It's Used in SimpleEshop
Docker is used to containerize the SimpleEshop application and its dependencies, including:
- The main Node.js application
- PostgreSQL database
- Redis for session storage
- MinIO for object storage
- Email services
- Mailpit for email testing

### Key Files and Directories
- `Dockerfile`: Main Dockerfile for the SimpleEshop application
- `docker-compose.yml`: Defines the multi-container application for local development
- `web-app/server/email-services/*/Dockerfile.standalone`: Dockerfiles for the email services

### Usage Instructions
```bash
# Build and run the application using Docker Compose
docker-compose up -d

# Build the Docker image manually
docker build -t niroth36/simpleeshop:latest .

# Push the image to Docker Hub
docker push niroth36/simpleeshop:latest
```

## Jenkins (CI)

### Overview
Jenkins is an open-source automation server that enables developers to build, test, and deploy their applications. It supports the creation of pipelines as code using a Jenkinsfile.

### How It's Used in SimpleEshop
Jenkins is used for continuous integration, specifically:
- Building the Docker image
- Pushing the image to Docker Hub
- Updating the Kubernetes manifests in the GitOps repository

### Key Files and Directories
- `Jenkinsfile`: Defines the CI pipeline
- `ansible/playbooks/jenkins/install.yml`: Ansible playbook for installing Jenkins

### Usage Instructions
```bash
# Access Jenkins UI
http://<node-ip>:30080

# Configure Jenkins credentials
# - docker-hub-credentials (Username with password)
# - github-credentials (Username with password)

# Create a pipeline job that uses the Jenkinsfile from the repository
```

## ArgoCD (CD)

### Overview
ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes. It automates the deployment of applications to Kubernetes by monitoring changes to a Git repository.

### How It's Used in SimpleEshop
ArgoCD is used for continuous deployment, specifically:
- Monitoring the GitOps repository for changes
- Automatically syncing the Kubernetes manifests with the cluster
- Providing a UI for visualizing the deployment status

### Key Files and Directories
- `kubernetes/argocd/simpleeshop-application.yaml`: ArgoCD application manifest
- `ansible/playbooks/argocd/install.yml`: Ansible playbook for installing ArgoCD

### Usage Instructions
```bash
# Access ArgoCD UI
https://<node-ip>:<argocd-nodeport>

# Login with admin credentials
# Username: admin
# Password: <generated-password>

# Sync the application manually if needed
```

## Azure Cloud

### Overview
Microsoft Azure is a cloud computing platform that provides a wide range of services, including virtual machines, storage, databases, and networking.

### How It's Used in SimpleEshop
Azure is used as the cloud provider for hosting the SimpleEshop infrastructure, specifically:
- Virtual Machines for the Kubernetes nodes
- Virtual Network for secure communication
- Network Security Groups for firewall rules
- Public IPs for external access

### Key Files and Directories
- `infrastructure/azure/`: OpenTofu configuration for Azure resources

### Usage Instructions
```bash
# Login to Azure CLI
az login

# Set the subscription
az account set --subscription <subscription-id>

# Provision the infrastructure using OpenTofu
cd infrastructure/azure
tofu apply -var-file=terraform.vars
```

## PostgreSQL

### Overview
PostgreSQL is an open-source relational database management system that emphasizes extensibility and SQL compliance.

### How It's Used in SimpleEshop
PostgreSQL is used as the primary database for the SimpleEshop application, storing:
- User accounts
- Product information
- Order data
- Shopping cart contents

### Key Files and Directories
- `database/init.sql`: SQL script for initializing the database
- `database/postgresql.sql`: Additional PostgreSQL-specific SQL
- `kubernetes/database/`: Kubernetes manifests for PostgreSQL

### Usage Instructions
```bash
# Connect to the PostgreSQL database (local development)
docker exec -it simpleeshop-postgres psql -U techhub -d techgearhub

# Connect to the PostgreSQL database (Kubernetes)
kubectl exec -it <postgres-pod-name> -n simpleeshop -- psql -U techhub -d techgearhub
```

## Redis

### Overview
Redis is an open-source, in-memory data structure store that can be used as a database, cache, and message broker.

### How It's Used in SimpleEshop
Redis is used for session storage in the SimpleEshop application, providing:
- Fast, in-memory storage for user sessions
- Persistence for session data
- Improved performance for the application

### Key Files and Directories
- `docker-compose.yml`: Configuration for the Redis container

### Usage Instructions
```bash
# Connect to the Redis CLI (local development)
docker exec -it simpleeshop-redis redis-cli

# Check Redis status
docker exec -it simpleeshop-redis redis-cli ping
```

## MinIO

### Overview
MinIO is a high-performance, S3-compatible object storage system. It is designed for large-scale private cloud infrastructure.

### How It's Used in SimpleEshop
MinIO is used for object storage in the SimpleEshop application, specifically:
- Storing user registration data
- Storing order information
- Triggering event-driven email services

### Key Files and Directories
- `docker-compose.yml`: Configuration for the MinIO container

### Usage Instructions
```bash
# Access MinIO Console (local development)
http://localhost:9001

# Login with credentials
# Username: minioadmin
# Password: minioadmin
```

## Mailpit

### Overview
Mailpit is a small, fast, and simple email testing tool for developers. It acts as an SMTP server that captures all outgoing emails for testing purposes.

### How It's Used in SimpleEshop
Mailpit is used for email testing in the SimpleEshop application, capturing:
- Welcome emails sent to new users
- Order confirmation emails
- Any other transactional emails

### Key Files and Directories
- `docker-compose.yml`: Configuration for the Mailpit container
- `test-welcome-email.sh`: Script for testing welcome emails
- `test-order-confirmation-email.sh`: Script for testing order confirmation emails

### Usage Instructions
```bash
# Access Mailpit Web UI (local development)
http://localhost:8025

# Test welcome email
./test-welcome-email.sh

# Test order confirmation email
./test-order-confirmation-email.sh
```

## Node.js

### Overview
Node.js is an open-source, cross-platform JavaScript runtime environment that executes JavaScript code outside a web browser.

### How It's Used in SimpleEshop
Node.js is used as the backend runtime for the SimpleEshop application, providing:
- HTTP server for the web application
- API endpoints for the frontend
- Database connectivity
- Integration with other services (Redis, MinIO, etc.)

### Key Files and Directories
- `web-app/server/server.js`: Main server file
- `web-app/server/server_postgresql.js`: PostgreSQL-specific server file
- `web-app/server/email-services/`: Email service implementations
- `web-app/public/`: Frontend files (HTML, CSS, JavaScript)

### Usage Instructions
```bash
# Install dependencies
npm install

# Run the server locally
node web-app/server/server_postgresql.js

# Run with nodemon for development
npx nodemon web-app/server/server_postgresql.js
```

## Conclusion

The SimpleEshop project uses a modern, cloud-native architecture with a wide range of technologies for infrastructure provisioning, configuration management, containerization, orchestration, CI/CD, and application components. This document provides a comprehensive overview of these technologies and how they are used in the project.

For more information on the GitOps workflow used for deployment, see [GITOPS.md](GITOPS.md).