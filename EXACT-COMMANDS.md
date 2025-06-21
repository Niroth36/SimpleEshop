# Exact Commands to Deploy Jenkins and ArgoCD

This guide provides the exact commands you need to run to deploy Jenkins and ArgoCD to your Kubernetes cluster using your specific VM IP addresses:

- Control Plane VM: 4.210.149.226
- Worker VM: 104.47.147.204

## Step 1: Ensure SSH Access to VMs

First, make sure you can SSH into both VMs:

```bash
# Test SSH access to control plane
ssh azureuser@4.210.149.226

# Test SSH access to worker
ssh azureuser@104.47.147.204
```

If you don't have SSH access set up yet, use these commands:

```bash
# Generate SSH key if you don't have one
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_rsa

# Copy SSH key to each VM
ssh-copy-id -i ~/.ssh/azure_rsa.pub azureuser@4.210.149.226
ssh-copy-id -i ~/.ssh/azure_rsa.pub azureuser@104.47.147.204
```

## Step 2: Clone the Repository

```bash
git clone https://github.com/Niroth36/SimpleEshop.git
cd SimpleEshop
```

## Step 3: Test Ansible Connectivity

```bash
cd ansible
ansible all -i inventories/azure/hosts.yml -m ping
```

You should see a success message for both VMs.

## Step 4: Deploy MicroK8s Cluster with Jenkins and ArgoCD

```bash
ansible-playbook -i inventories/azure/hosts.yml playbooks/site.yml
```

This single command will:
1. Install MicroK8s on both VMs
2. Configure the control plane with necessary addons
3. Join the worker node to the cluster
4. Install Jenkins
5. Install ArgoCD
6. Verify the deployment

## Step 5: Access Jenkins

Once the deployment is complete, access Jenkins at:

```
http://4.210.149.226:30080
```

To get the Jenkins admin password:

```bash
# SSH into the control plane VM
ssh azureuser@4.210.149.226

# Get the Jenkins admin password
sg microk8s -c "microk8s kubectl exec -it \$(microk8s kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}') -n jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword"
```

## Step 6: Access ArgoCD

Access ArgoCD at:

```
https://4.210.149.226:30443
```

Login with:
- Username: admin
- Password: Get the password with:

```bash
# SSH into the control plane VM
ssh azureuser@4.210.149.226

# Get the ArgoCD admin password
sg microk8s -c "microk8s kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
```

## Step 7: Verify the Deployment

SSH into the control plane VM and check the status:

```bash
# SSH into the control plane VM
ssh azureuser@4.210.149.226

# Check the status of the MicroK8s cluster
sg microk8s -c "microk8s status"

# List all nodes in the cluster
sg microk8s -c "microk8s kubectl get nodes"

# List all pods in all namespaces
sg microk8s -c "microk8s kubectl get pods -A"
```

## Troubleshooting

If you encounter any issues:

1. Check if the VMs are running and accessible via SSH
2. Verify that the Ansible inventory file has the correct IP addresses (already set in this case)
3. Check the Ansible logs for any errors during deployment
4. Ensure that ports 30080 (Jenkins) and 30443 (ArgoCD) are open in your firewall

For more detailed troubleshooting, refer to the JENKINS-ARGOCD-DEPLOYMENT.md file in the repository.