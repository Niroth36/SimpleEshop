# Step-by-Step Guide to Deploy Jenkins and ArgoCD with Ansible

This guide provides detailed instructions for deploying Jenkins and ArgoCD to your Kubernetes cluster using Ansible. Follow these steps to set up a complete CI/CD pipeline for your SimpleEshop application.

## Prerequisites

Before you begin, ensure you have:

1. At least two Ubuntu VMs (one for control plane, one or more for workers)
2. SSH access to all VMs
3. Ansible installed on your local machine
4. Git installed on your local machine

## Step 1: Clone the Repository

```bash
git clone https://github.com/<YOUR_GITHUB_USERNAME>/SimpleEshop.git
cd SimpleEshop
```

## Step 2: Set Up Ansible Inventory

Create or modify the Ansible inventory file at `ansible/inventory/hosts.ini`:

```ini
[control_plane]
control-plane-vm ansible_host=<CONTROL_PLANE_IP> ansible_user=azureuser

[workers]
worker-1-vm ansible_host=<WORKER_1_IP> ansible_user=azureuser
worker-2-vm ansible_host=<WORKER_2_IP> ansible_user=azureuser

[microk8s_cluster:children]
control_plane
workers
```

Replace `<CONTROL_PLANE_IP>`, `<WORKER_1_IP>`, and `<WORKER_2_IP>` with the actual IP addresses of your VMs. Adjust `ansible_user` if your username is different.

## Step 3: Configure SSH Access

Ensure your SSH key is set up for passwordless access to all VMs:

```bash
# Generate SSH key if you don't have one
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# Copy SSH key to each VM
ssh-copy-id -i ~/.ssh/id_rsa.pub azureuser@<CONTROL_PLANE_IP>
ssh-copy-id -i ~/.ssh/id_rsa.pub azureuser@<WORKER_1_IP>
ssh-copy-id -i ~/.ssh/id_rsa.pub azureuser@<WORKER_2_IP>
```

## Step 4: Test Ansible Connectivity

Verify that Ansible can connect to all your VMs:

```bash
ansible all -i ansible/inventory/hosts.ini -m ping
```

You should see a success message for each VM.

## Step 5: Deploy MicroK8s Cluster

Run the site playbook to deploy the MicroK8s cluster:

```bash
cd ansible
ansible-playbook -i inventory/hosts.ini playbooks/site.yml
```

This playbook will:
1. Install MicroK8s on all nodes
2. Configure the control plane with necessary addons
3. Join worker nodes to the cluster
4. Install Jenkins and ArgoCD

## Step 6: Verify MicroK8s Cluster

After the playbook completes, verify that your MicroK8s cluster is running correctly:

```bash
# SSH into the control plane VM
ssh azureuser@<CONTROL_PLANE_IP>

# Check the status of the MicroK8s cluster
sg microk8s -c "microk8s status"

# List all nodes in the cluster
sg microk8s -c "microk8s kubectl get nodes"

# List all pods in all namespaces
sg microk8s -c "microk8s kubectl get pods -A"
```

## Step 7: Access Jenkins

Jenkins should now be running in your cluster. Access it using:

1. Open your web browser and navigate to: `http://<CONTROL_PLANE_IP>:30080`
2. To get the initial admin password, run:

```bash
# SSH into the control plane VM
ssh azureuser@<CONTROL_PLANE_IP>

# Get the Jenkins admin password
sg microk8s -c "microk8s kubectl exec -it \$(microk8s kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}') -n jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword"
```

3. Complete the Jenkins setup wizard:
   - Install suggested plugins
   - Create an admin user
   - Configure Jenkins URL

## Step 8: Configure Jenkins

After logging in to Jenkins:

1. Install additional plugins:
   - Go to "Manage Jenkins" > "Manage Plugins" > "Available"
   - Search for and install: Git, Docker, Pipeline, Credentials

2. Add credentials:
   - Go to "Manage Jenkins" > "Manage Credentials" > "Jenkins" > "Global credentials" > "Add Credentials"
   - Add Docker Hub credentials (Username with password)
   - Add GitHub credentials (Username with password)

3. Create a pipeline job:
   - Click "New Item"
   - Enter a name (e.g., "SimpleEshop")
   - Select "Pipeline" and click "OK"
   - In the configuration page, under "Pipeline", select "Pipeline script from SCM"
   - Select "Git" as the SCM
   - Enter your repository URL (e.g., https://github.com/<YOUR_GITHUB_USERNAME>/SimpleEshop.git)
   - Specify the branch (e.g., "main")
   - Set the Script Path to "Jenkinsfile"
   - Click "Save"

## Step 9: Access ArgoCD

ArgoCD should also be running in your cluster. Access it using:

1. Open your web browser and navigate to: `https://<CONTROL_PLANE_IP>:30443`
   - You may need to accept the self-signed certificate warning

2. Log in with:
   - Username: admin
   - Password: The password displayed in the Ansible playbook output

   If you didn't note the password, you can retrieve it with:

```bash
# SSH into the control plane VM
ssh azureuser@<CONTROL_PLANE_IP>

# Get the ArgoCD admin password
sg microk8s -c "microk8s kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
```

## Step 10: Configure ArgoCD

After logging in to ArgoCD:

1. The SimpleEshop application should be automatically configured
2. If not, create a new application:
   - Click "New App"
   - Set Name to "simpleeshop"
   - Set Project to "default"
   - Set Repository URL to "https://github.com/<YOUR_GITHUB_USERNAME>/SimpleEshop.git"
   - Set Path to "gitops"
   - Set Destination to "https://kubernetes.default.svc"
   - Set Namespace to "simpleeshop"
   - Enable "Auto-create Namespace"
   - Under Sync Policy, enable "Automated"
   - Click "Create"

## Step 11: Verify the Deployment

To verify that everything is working correctly:

1. Check that Jenkins can build and push the Docker image:
   - Go to your Jenkins pipeline
   - Click "Build Now"
   - Monitor the build progress and ensure it completes successfully

2. Check that ArgoCD can deploy the application:
   - Go to the ArgoCD dashboard
   - Click on the "simpleeshop" application
   - Verify that it's synced and healthy
   - If not, click "Sync" and monitor the progress

3. Access your deployed application:
   - Open your web browser and navigate to: `http://<CONTROL_PLANE_IP>:30000`
   - You should see the SimpleEshop application

## Troubleshooting

### Jenkins Issues

1. **Jenkins pod not starting:**
   ```bash
   sg microk8s -c "microk8s kubectl get pods -n jenkins"
   sg microk8s -c "microk8s kubectl describe pod <jenkins-pod-name> -n jenkins"
   sg microk8s -c "microk8s kubectl logs <jenkins-pod-name> -n jenkins"
   ```

2. **Jenkins service not accessible:**
   ```bash
   sg microk8s -c "microk8s kubectl get svc -n jenkins"
   sg microk8s -c "microk8s kubectl describe svc jenkins -n jenkins"
   ```

### ArgoCD Issues

1. **ArgoCD pod not starting:**
   ```bash
   sg microk8s -c "microk8s kubectl get pods -n argocd"
   sg microk8s -c "microk8s kubectl describe pod <argocd-server-pod-name> -n argocd"
   sg microk8s -c "microk8s kubectl logs <argocd-server-pod-name> -n argocd"
   ```

2. **ArgoCD service not accessible:**
   ```bash
   sg microk8s -c "microk8s kubectl get svc -n argocd"
   sg microk8s -c "microk8s kubectl describe svc argocd-server -n argocd"
   ```

3. **Application not syncing:**
   ```bash
   sg microk8s -c "microk8s kubectl get applications -n argocd"
   sg microk8s -c "microk8s kubectl describe application simpleeshop -n argocd"
   ```

## Common Issues and Solutions

1. **Firewall blocking access:**
   - Ensure that ports 30080 (Jenkins) and 30443 (ArgoCD) are open in your firewall

2. **Certificate issues with ArgoCD:**
   - ArgoCD uses a self-signed certificate by default
   - You can safely accept the certificate warning in your browser

3. **Repository not accessible:**
   - Ensure that your repository is public or that you've configured the proper credentials in ArgoCD

4. **Docker Hub rate limiting:**
   - If you encounter Docker Hub rate limiting, ensure you've configured Docker Hub credentials in Jenkins

## Conclusion

You have successfully deployed Jenkins and ArgoCD to your Kubernetes cluster using Ansible. You now have a complete CI/CD pipeline for your SimpleEshop application:

1. Jenkins handles the Continuous Integration (CI) part:
   - Building the Docker image
   - Pushing the image to Docker Hub
   - Updating the GitOps directory

2. ArgoCD handles the Continuous Deployment (CD) part:
   - Monitoring the GitOps directory for changes
   - Automatically deploying the application to the Kubernetes cluster

This GitOps workflow provides a robust and automated way to deploy your application, ensuring that your deployment is always in sync with the desired state defined in your GitOps directory.
