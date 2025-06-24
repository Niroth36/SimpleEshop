# SimpleEshop Deployment Guide

This document provides comprehensive step-by-step instructions on how to deploy the entire SimpleEshop infrastructure correctly, from provisioning cloud resources to deploying the application using GitOps.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Deployment Overview](#deployment-overview)
- [Step 1: Provision Cloud Infrastructure](#step-1-provision-cloud-infrastructure)
- [Step 2: Configure the Environment](#step-2-configure-the-environment)
- [Step 3: Set Up Kubernetes Cluster](#step-3-set-up-kubernetes-cluster)
- [Step 4: Install GitOps Tools](#step-4-install-gitops-tools)
- [Step 5: Deploy the Application](#step-5-deploy-the-application)
- [Step 6: Verify the Deployment](#step-6-verify-the-deployment)
- [Troubleshooting](#troubleshooting)
- [References](#references)

## Prerequisites

Before you begin, ensure you have the following:

- Azure account with sufficient permissions
- OpenTofu (or Terraform) installed locally
- Ansible installed locally
- Git installed locally
- SSH key pair for VM access
- Docker Hub account (for pushing images)
- GitHub account

## Deployment Overview

The deployment process follows these main steps:

1. Provision cloud infrastructure using OpenTofu/Terraform
2. Configure the environment using Ansible
3. Set up Kubernetes cluster with MicroK8s
4. Install GitOps tools (Jenkins and ArgoCD)
5. Deploy the application using GitOps
6. Verify the deployment

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Provision  │     │  Configure  │     │   Set Up    │     │   Install   │
│    Cloud    │────►│ Environment │────►│  Kubernetes │────►│   GitOps    │
│Infrastructure│     │ with Ansible│     │   Cluster   │     │    Tools    │
└─────────────┘     └─────────────┘     └─────────────┘     └──────┬──────┘
                                                                   │
                                                                   ▼
┌─────────────┐                                            ┌─────────────┐
│   Verify    │◄───────────────────────────────────────────│   Deploy    │
│ Deployment  │                                            │ Application  │
└─────────────┘                                            └─────────────┘
```

## Step 1: Provision Cloud Infrastructure

In this step, you'll use OpenTofu (or Terraform) to provision the necessary infrastructure in Azure.

### 1.1 Prepare Configuration

1. Clone the repository:
   ```bash
   git clone https://github.com/Niroth36/SimpleEshop.git
   cd SimpleEshop
   ```

2. Navigate to the infrastructure directory:
   ```bash
   cd infrastructure/azure
   ```

3. Create a `terraform.vars` file with your Azure credentials and configuration:
   ```bash
   # Create terraform.vars file
   cat > terraform.vars << EOF
   sub_id = "your-azure-subscription-id"
   resource_group_name = "simpleeshop-cloud-rg"
   location = "eastus"
   control_plane_vm_size = "Standard_D2s_v3"
   worker_vm_size = "Standard_D2s_v3"
   worker_count = 2
   ssh_public_key = "ssh-rsa AAAA..."
   email = "your-email@example.com"
   EOF
   ```

### 1.2 Initialize and Apply

1. Initialize OpenTofu:
   ```bash
   tofu init
   ```

2. Plan the infrastructure:
   ```bash
   tofu plan -var-file=terraform.vars
   ```

3. Apply the infrastructure:
   ```bash
   tofu apply -var-file=terraform.vars
   ```

4. Note the outputs, especially the IP addresses of the VMs:
   ```bash
   tofu output
   ```

### 1.3 Verify Infrastructure

1. Check that all VMs are running:
   ```bash
   az vm list -g simpleeshop-cloud-rg --show-details -o table
   ```

2. If any VMs are not running, start them:
   ```bash
   az vm start --resource-group simpleeshop-cloud-rg --name control-plane-vm
   az vm start --resource-group simpleeshop-cloud-rg --name worker-1-vm
   az vm start --resource-group simpleeshop-cloud-rg --name worker-2-vm
   ```

## Step 2: Configure the Environment

In this step, you'll use Ansible to configure the VMs and prepare them for Kubernetes.

### 2.1 Prepare Ansible Inventory

1. Navigate to the Ansible directory:
   ```bash
   cd ../../ansible
   ```

2. Update the inventory file if needed:
   ```bash
   # The inventory should be automatically created by OpenTofu
   # Check if it exists and has the correct IP addresses
   cat inventories/azure/hosts.yml
   ```

3. If you need to manually update the inventory, use this format:
   ```yaml
   all:
     children:
       microk8s_cluster:
         children:
           control_plane:
             hosts:
               control-plane-vm:
                 ansible_host: <control-plane-ip>
                 ansible_user: azureuser
                 ansible_ssh_private_key_file: ~/.ssh/azure_rsa
                 region: eastus
           workers:
             hosts:
               worker-1-vm:
                 ansible_host: <worker-1-ip>
                 ansible_user: azureuser
                 ansible_ssh_private_key_file: ~/.ssh/azure_rsa
                 region: eastus
               worker-2-vm:
                 ansible_host: <worker-2-ip>
                 ansible_user: azureuser
                 ansible_ssh_private_key_file: ~/.ssh/azure_rsa
                 region: eastus
   ```

### 2.2 Run Ansible Playbooks

1. Run the main playbook:
   ```bash
   ansible-playbook playbooks/site.yml -i inventories/azure/hosts.yml
   ```

   This playbook will:
   - Install MicroK8s on all nodes
   - Configure the control plane
   - Join worker nodes to the cluster
   - Install Jenkins and ArgoCD

2. If you encounter any errors, you can run specific playbooks individually:
   ```bash
   # Clean install MicroK8s on all nodes
   ansible-playbook playbooks/microk8s/clean-install.yml -i inventories/azure/hosts.yml

   # Configure control plane
   ansible-playbook playbooks/microk8s/control-plane.yml -i inventories/azure/hosts.yml

   # Join workers to cluster
   ansible-playbook playbooks/microk8s/workers.yml -i inventories/azure/hosts.yml

   # Install Jenkins
   ansible-playbook playbooks/jenkins/install.yml -i inventories/azure/hosts.yml

   # Install ArgoCD
   ansible-playbook playbooks/argocd/install.yml -i inventories/azure/hosts.yml
   ```

## Step 3: Set Up Kubernetes Cluster

The Ansible playbooks should have set up the Kubernetes cluster, but let's verify and perform any additional configuration.

### 3.1 Verify Cluster Status

1. SSH into the control plane node:
   ```bash
   ssh -i ~/.ssh/azure_rsa azureuser@<control-plane-ip>
   ```

2. Check the cluster status:
   ```bash
   sg microk8s -c "microk8s status"
   ```

3. Check the nodes:
   ```bash
   sg microk8s -c "microk8s kubectl get nodes -o wide"
   ```

### 3.2 Create Application Namespace

1. Create the SimpleEshop namespace:
   ```bash
   sg microk8s -c "microk8s kubectl create namespace simpleeshop"
   ```

### 3.3 Configure Storage

1. Ensure the storage addon is enabled:
   ```bash
   sg microk8s -c "microk8s enable storage"
   ```

## Step 4: Install GitOps Tools

The Ansible playbooks should have installed Jenkins and ArgoCD, but let's verify and perform any additional configuration.

### 4.1 Configure Jenkins

1. Get the Jenkins URL:
   ```bash
   echo "http://<control-plane-ip>:30080"
   ```

2. Get the Jenkins admin password:
   ```bash
   sg microk8s -c "microk8s kubectl exec -it \$(microk8s kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}') -n jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword"
   ```

3. Access Jenkins in your browser and complete the setup:
   - Install suggested plugins
   - Create an admin user
   - Configure Jenkins URL

4. Add the following credentials:
   - docker-hub-credentials (Username with password)
   - github-credentials (Username with password)

5. Create a pipeline job:
   - Name: simpleeshop
   - Pipeline from SCM
   - SCM: Git
   - Repository URL: https://github.com/Niroth36/SimpleEshop.git
   - Script Path: Jenkinsfile

### 4.2 Configure ArgoCD

1. Get the ArgoCD URL and port:
   ```bash
   sg microk8s -c "microk8s kubectl get svc argocd-server -n argocd -o jsonpath='{.spec.ports[0].nodePort}'"
   echo "https://<control-plane-ip>:<nodePort>"
   ```

2. Get the ArgoCD admin password:
   ```bash
   sg microk8s -c "microk8s kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
   ```

3. Access ArgoCD in your browser and login:
   - Username: admin
   - Password: <password-from-previous-step>

4. Verify the SimpleEshop application is configured:
   - Check that the application is listed
   - If not, create it manually using the settings from `kubernetes/argocd/simpleeshop-application.yaml`

## Step 5: Deploy the Application

Now you'll deploy the SimpleEshop application using the GitOps workflow.

### 5.1 Verify GitOps Directory

1. The SimpleEshop repository already contains a GitOps directory with all the necessary Kubernetes manifests:
   ```bash
   ls -la gitops
   ```

2. Verify the directory structure:
   ```bash
   ls -la gitops/apps
   ls -la gitops/infrastructure
   ```

3. The GitOps directory contains:
   - Application manifests in `gitops/apps/simpleeshop/manifests/`
   - Database manifests in `gitops/apps/database/manifests/`
   - Infrastructure manifests in `gitops/infrastructure/namespaces/`

### 5.2 Trigger the CI/CD Pipeline

1. Make a change to the SimpleEshop repository:
   ```bash
   cd ../SimpleEshop
   # Make a small change, e.g., update a comment
   git add .
   git commit -m "Trigger CI/CD pipeline"
   git push origin main
   ```

2. Monitor the Jenkins pipeline:
   - Go to Jenkins at http://<control-plane-ip>:30080
   - Check that the pipeline is running
   - Wait for it to complete

3. Monitor ArgoCD:
   - Go to ArgoCD at https://<control-plane-ip>:<nodePort>
   - Check that the application is syncing
   - Wait for it to complete

## Step 6: Verify the Deployment

Now let's verify that the application is deployed correctly.

### 6.1 Check Kubernetes Resources

1. SSH into the control plane node:
   ```bash
   ssh -i ~/.ssh/azure_rsa azureuser@<control-plane-ip>
   ```

2. Check the pods:
   ```bash
   sg microk8s -c "microk8s kubectl get pods -n simpleeshop"
   ```

3. Check the services:
   ```bash
   sg microk8s -c "microk8s kubectl get services -n simpleeshop"
   ```

### 6.2 Access the Application

1. Get the NodePort for the SimpleEshop service:
   ```bash
   sg microk8s -c "microk8s kubectl get svc simpleeshop-service -n simpleeshop -o jsonpath='{.spec.ports[0].nodePort}'"
   ```

2. Access the application in your browser:
   ```
   http://<worker-node-ip>:<nodePort>
   ```

3. Test the application functionality:
   - Register a new user
   - Browse products
   - Add items to cart
   - Complete checkout

## Troubleshooting

### Common Issues and Solutions

#### Infrastructure Provisioning Issues

- **Error: Azure subscription not found**
  - Ensure you're logged in to Azure CLI: `az login`
  - Verify your subscription ID: `az account list`

- **Error: Resource quota exceeded**
  - Request a quota increase or use smaller VM sizes

#### Ansible Issues

- **Error: SSH connection failed**
  - Verify the SSH key path in the inventory
  - Check that the VMs are running: `az vm list -g simpleeshop-cloud-rg --show-details -o table`
  - Ensure the NSG allows SSH: `az network nsg rule list -g simpleeshop-cloud-rg --nsg-name control-plane-nsg`

- **Error: MicroK8s installation failed**
  - Check system requirements: `ansible control_plane -m shell -a "free -m"`
  - Ensure snapd is working: `ansible control_plane -m shell -a "snap version"`

#### Kubernetes Issues

- **Error: Nodes not joining the cluster**
  - Check network connectivity between nodes
  - Verify the join command: `cat /tmp/microk8s_join_command`
  - Check firewall rules: `az network nsg rule list -g simpleeshop-cloud-rg --nsg-name control-plane-nsg`

- **Error: Pods stuck in Pending state**
  - Check for resource constraints: `sg microk8s -c "microk8s kubectl describe pod <pod-name> -n simpleeshop"`
  - Verify storage provisioner: `sg microk8s -c "microk8s kubectl get sc"`

#### GitOps Issues

- **Error: Jenkins pipeline fails**
  - Check Docker Hub credentials
  - Verify GitHub credentials
  - Ensure Docker is installed on the Jenkins agent

- **Error: ArgoCD sync fails**
  - Check the GitOps directory path in the repository
  - Verify the Kubernetes manifests
  - Check ArgoCD logs: `sg microk8s -c "microk8s kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server"`

#### Application Issues

- **Error: Application not accessible**
  - Check if pods are running: `sg microk8s -c "microk8s kubectl get pods -n simpleeshop"`
  - Verify the service: `sg microk8s -c "microk8s kubectl get svc -n simpleeshop"`
  - Check NSG rules for the NodePort: `az network nsg rule list -g simpleeshop-cloud-rg --nsg-name worker-nsg`

- **Error: Database connection issues**
  - Check database pods: `sg microk8s -c "microk8s kubectl get pods -n simpleeshop -l app=postgres"`
  - Verify database service: `sg microk8s -c "microk8s kubectl get svc postgres-service -n simpleeshop"`
  - Check application logs: `sg microk8s -c "microk8s kubectl logs -n simpleeshop -l app=simpleeshop"`

## References

- [INFRASTRUCTURE.md](INFRASTRUCTURE.md) - Detailed information about all technologies used
- [GITOPS.md](GITOPS.md) - Information about the GitOps workflow
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Ansible Documentation](https://docs.ansible.com/)
- [MicroK8s Documentation](https://microk8s.io/docs)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
