# SimpleEshop - Infrastructure and Deployment Guide

## Overview

SimpleEshop is a complete e-commerce application with a modern cloud-native infrastructure. This document provides a comprehensive guide to the infrastructure setup, deployment process, and the various services used in the project.

## Infrastructure Setup with Terraform (OpenTofu)

The infrastructure for SimpleEshop is provisioned using Terraform (OpenTofu) on Microsoft Azure. The setup includes:

### Virtual Machines
- **Control Plane VM**: Ubuntu 24.04 LTS server that hosts the Kubernetes control plane
- **Worker VM**: Ubuntu 24.04 LTS server that runs the application workloads

### Networking
- Virtual Network with separate subnets for control plane and worker nodes
- Network Security Groups with rules for:
  - SSH access
  - Kubernetes API
  - Application services (Jenkins, ArgoCD, MinIO, Grafana, etc.)
  - NodePort ranges for Kubernetes services

### Security
- SSH key-based authentication
- Firewall rules to restrict access to critical services
- Auto-shutdown schedule for cost optimization

## Deployment with Ansible

After provisioning the infrastructure with Terraform, Ansible is used to configure the VMs and deploy the Kubernetes cluster:

### System Configuration
- Update and upgrade system packages (`apt-get update` and `apt-get upgrade`)
- Install essential packages (curl, wget, git, vim, htop, net-tools, unzip, snapd)

### MicroK8s Installation
1. Install MicroK8s on all nodes using the snap package manager
2. Configure the control plane with necessary addons
3. Generate a join token for worker nodes
4. Join worker nodes to the cluster
5. Copy the `.kube/config` file to the local machine for cluster management

### Service Deployment
Ansible playbooks are used to deploy the following services to the Kubernetes cluster:
- Jenkins for CI/CD
- ArgoCD for GitOps-based deployments

## Kubernetes Cluster

The Kubernetes cluster is built using MicroK8s and consists of:
- One control plane node
- One worker node

### Deployed Services

#### Jenkins
- Deployed as a Kubernetes service with a NodePort for external access
- Configured with credentials for:
  - GitHub repository access
  - Docker Hub for image publishing
  - SSH access to the control plane VM
- Webhook integration with GitHub for automated builds
- Pipeline configured to:
  1. Clone the repository
  2. Check for changes in the web-app directory
  3. Build a Docker image on the control plane VM
  4. Push the image to Docker Hub
  5. Update the Kubernetes manifest with the new image tag
  6. Commit and push the changes to GitHub

#### ArgoCD
- Deployed as a Kubernetes service with a NodePort for external access
- Configured to monitor the GitHub repository for changes
- Automatically syncs and deploys application manifests from the repository
- Provides a web UI for visualizing and managing deployments

#### MinIO
- Object storage service for storing user data and order information
- Configured with webhooks to trigger email services when new objects are created
- Used for event-driven processing in the application

#### Grafana
- Monitoring and visualization platform
- Configured with data sources for:
  - Prometheus (metrics)
  - Loki (logs)
- Provides dashboards for monitoring application performance and health

#### Loki
- Log aggregation system
- Collects logs from all services in the cluster
- Integrated with Grafana for log visualization and analysis

#### Mailpit
- Email testing tool that captures all outgoing emails
- Provides a web UI for viewing and testing emails
- Used by the email services for sending notifications

## CI/CD Pipeline

The CI/CD pipeline for SimpleEshop is implemented using Jenkins and ArgoCD:

### Jenkins Pipeline
1. Triggered by GitHub webhook when changes are pushed to the repository
2. Checks if changes were made to the web-app directory
3. If changes are detected:
   - Builds a new Docker image
   - Pushes the image to Docker Hub
   - Updates the Kubernetes manifest with the new image tag
   - Commits and pushes the changes to GitHub

### ArgoCD Deployment
1. Monitors the GitHub repository for changes
2. Detects changes to the Kubernetes manifests
3. Automatically syncs and deploys the changes to the cluster
4. Provides a web UI for visualizing and managing deployments

## Accessing Services

All services are exposed through NodePorts and can be accessed using the control plane IP address:

- **Jenkins**: http://<control-plane-ip>:30080
- **ArgoCD**: https://<control-plane-ip>:30443
- **Grafana**: http://<control-plane-ip>:30030
- **MinIO Console**: http://<control-plane-ip>:30901
- **Mailpit**: http://<control-plane-ip>:30025
- **SimpleEshop Application**: http://<control-plane-ip>:30000

## Conclusion

SimpleEshop demonstrates a complete cloud-native infrastructure with automated provisioning, configuration, and deployment. The combination of Terraform, Ansible, Kubernetes, Jenkins, and ArgoCD provides a robust and scalable platform for running the e-commerce application.