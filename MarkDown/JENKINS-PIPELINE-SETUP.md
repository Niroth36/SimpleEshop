# Setting Up a Jenkins Pipeline for SimpleEshop

This guide provides step-by-step instructions for setting up a Jenkins pipeline for your SimpleEshop project. The pipeline will automatically clone your repository, test your code, build a Docker image, and push it to Docker Hub.

## Prerequisites

Before you begin, ensure you have:

1. Jenkins installed and running (accessible at http://4.210.149.226:30080)
2. Docker Hub account
3. GitHub repository for your SimpleEshop project
4. The Jenkinsfile file in your repository (already provided)

## Step 1: Configure Jenkins Credentials

First, you need to set up the necessary credentials in Jenkins:

1. Access Jenkins at http://4.210.149.226:30080
2. Go to "Manage Jenkins" > "Manage Credentials" > "Jenkins" > "Global credentials" > "Add Credentials"
3. Add Docker Hub credentials:
   - Kind: Username with password
   - Scope: Global
   - Username: Your Docker Hub username
   - Password: Your Docker Hub password
   - ID: docker-hub-credentials
   - Description: Docker Hub Credentials
   - Click "OK"
4. Add GitHub credentials:
   - Kind: Username with password
   - Scope: Global
   - Username: Your GitHub username
   - Password: Your GitHub personal access token (with repo permissions)
   - ID: github-credentials
   - Description: GitHub Credentials
   - Click "OK"

## Step 2: Create a Jenkins Pipeline Job

Now, create a new pipeline job that will use your Jenkinsfile:

1. From the Jenkins dashboard, click "New Item"
2. Enter a name for your job (e.g., "SimpleEshop-WebApp")
3. Select "Pipeline" and click "OK"
4. In the configuration page:
   - Under "General", check "GitHub project" and enter your repository URL (e.g., https://github.com/Niroth36/SimpleEshop)
   - Under "Build Triggers", check "GitHub hook trigger for GITScm polling"
   - Under "Pipeline", select "Pipeline script from SCM"
   - Select "Git" as the SCM
   - Enter your repository URL (e.g., https://github.com/Niroth36/SimpleEshop.git)
   - Click "Add" next to Credentials and select your GitHub credentials from the dropdown
     - If you haven't added credentials yet, click "Add" > "Jenkins" and add your GitHub credentials
     - Use your GitHub username and personal access token (with repo permissions)
   - Specify the branch (e.g., "main")
   - Set the Script Path to "Jenkinsfile"
   - Click "Save"

> **Note**: If you encounter a "403 Write access to repository not granted" error, you need to ensure your GitHub credentials have the correct permissions. See the "Troubleshooting GitHub Authentication" section below for solutions.

## Step 3: Configure GitHub Webhook

To automatically trigger your pipeline when changes are pushed to GitHub:

1. Go to your GitHub repository (e.g., https://github.com/Niroth36/SimpleEshop)
2. Click on "Settings" > "Webhooks" > "Add webhook"
3. Set the Payload URL to `http://4.210.149.226:30080/github-webhook/`
4. Set the Content type to `application/json`
5. For "Which events would you like to trigger this webhook?", select "Just the push event"
6. Check "Active"
7. Click "Add webhook"

## Step 4: Install Required Jenkins Plugins

Ensure you have the necessary plugins installed:

1. Go to "Manage Jenkins" > "Manage Plugins" > "Available"
2. Search for and install the following plugins if they're not already installed:
   - Git
   - Docker
   - Docker Pipeline
   - Pipeline
   - GitHub Integration
   - Credentials
3. Click "Install without restart"
4. Check "Restart Jenkins when installation is complete and no jobs are running"

## Step 5: Configure Jenkins for Docker

To allow Jenkins to build and push Docker images:

1. SSH into your control plane VM:
   ```bash
   ssh azureuser@4.210.149.226
   ```

2. Get the Jenkins pod name:
   ```bash
   JENKINS_POD=$(sg microk8s -c "microk8s kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}'")
   ```

3. Install Docker in the Jenkins container:
   ```bash
   sg microk8s -c "microk8s kubectl exec -it $JENKINS_POD -n jenkins -- bash -c 'apt-get update && apt-get install -y docker.io'"
   ```

4. Configure Docker socket access:
   ```bash
   sg microk8s -c "microk8s kubectl exec -it $JENKINS_POD -n jenkins -- bash -c 'usermod -aG docker jenkins'"
   ```

## Step 6: Run Your First Pipeline Build

Now that everything is set up, you can run your first pipeline build:

1. Go to your Jenkins dashboard
2. Click on your pipeline job (e.g., "SimpleEshop-WebApp")
3. Click "Build Now"
4. Monitor the build progress by clicking on the build number and then "Console Output"

## Step 7: Verify the Pipeline Results

After the pipeline completes:

1. Check that the Docker image was pushed to Docker Hub:
   - Go to https://hub.docker.com/r/niroth36/simpleeshop/tags
   - Verify that a new tag with the build number exists

2. Check that the GitOps repository was updated:
   - Check the commit history of the main repository to see if a new commit was made by Jenkins to update the GitOps directory

3. Verify the deployment in ArgoCD:
   - Access ArgoCD at https://4.210.149.226:30443
   - Log in with the admin credentials
   - Check the SimpleEshop application status
   - Verify that it's synced and healthy

## Step 8: Make Changes to Trigger the Pipeline

To test the automatic triggering of the pipeline:

1. Make a change to a file in the web-app directory:
   ```bash
   # Edit a file in the web-app directory
   nano web-app/server/server_postgresql.js

   # Add a comment or make a small change

   # Commit and push the change
   git add web-app/server/server_postgresql.js
   git commit -m "Test web-app pipeline trigger"
   git push origin main
   ```

2. Go to your GitHub repository > "Settings" > "Webhooks"
3. Click on your webhook
4. Scroll down to "Recent Deliveries" to see if the webhook was delivered successfully
5. Check your Jenkins pipeline to see if it was triggered

## Troubleshooting

### Troubleshooting GitHub Authentication

If you encounter a "403 Write access to repository not granted" error when setting up your Jenkins pipeline, try these solutions:

#### Solution 1: Fix HTTPS Authentication

1. **Create a Personal Access Token (PAT) with the correct permissions**:
   - Go to GitHub > Settings > Developer settings > Personal access tokens > Tokens (classic)
   - Click "Generate new token" > "Generate new token (classic)"
   - Give your token a descriptive name
   - Select the following scopes:
     - `repo` (Full control of private repositories)
     - `admin:repo_hook` (if you're setting up webhooks)
   - Click "Generate token"
   - **IMPORTANT**: Copy the token immediately and store it securely. You won't be able to see it again!

2. **Configure the credentials in Jenkins**:
   - Go to Jenkins > Manage Jenkins > Manage Credentials > Jenkins > Global credentials > Add Credentials
   - Select "Username with password" from the Kind dropdown
   - Enter your GitHub username in the Username field
   - Enter your Personal Access Token in the Password field
   - Set the ID to "github-credentials"
   - Add a description (e.g., "GitHub Credentials")
   - Click "OK"

3. **Update your Jenkins pipeline job**:
   - Go to your pipeline job > Configure
   - Under "Pipeline" > "Definition" > "Pipeline script from SCM" > "SCM" > "Git"
   - Make sure your repository URL is correct (e.g., https://github.com/Niroth36/SimpleEshop.git)
   - Select your GitHub credentials from the Credentials dropdown
   - Click "Save"

#### Solution 2: Use SSH Authentication (More Secure)

For a more secure approach, you can use SSH keys instead of HTTPS:

1. **Generate SSH keys on the Jenkins server**:
   ```bash
   # SSH into your control plane VM
   ssh azureuser@4.210.149.226

   # Get the Jenkins pod name
   JENKINS_POD=$(sg microk8s -c "microk8s kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}'")

   # Generate SSH key pair in the Jenkins container
   sg microk8s -c "microk8s kubectl exec -it $JENKINS_POD -n jenkins -- bash -c 'mkdir -p /var/jenkins_home/.ssh && ssh-keygen -t rsa -b 4096 -C \"jenkins@simpleeshop\" -f /var/jenkins_home/.ssh/id_rsa -N \"\" && cat /var/jenkins_home/.ssh/id_rsa.pub'"
   ```

2. **Add the public key to GitHub**:
   - Copy the output of the last command (the public key)
   - Go to GitHub > Settings > SSH and GPG keys > New SSH key
   - Give the key a title (e.g., "Jenkins SimpleEshop")
   - Paste the public key
   - Click "Add SSH key"

3. **Configure Jenkins to use SSH**:
   - Go to Jenkins > Manage Jenkins > Manage Credentials > Jenkins > Global credentials > Add Credentials
   - Select "SSH Username with private key" from the Kind dropdown
   - Set the ID to "github-ssh-key"
   - Set the Username to "git"
   - Select "Enter directly" for the Private Key option
   - Get the private key from the Jenkins container:
     ```bash
     sg microk8s -c "microk8s kubectl exec -it $JENKINS_POD -n jenkins -- cat /var/jenkins_home/.ssh/id_rsa"
     ```
   - Paste the private key
   - Click "OK"

4. **Configure known hosts in Jenkins**:
   ```bash
   sg microk8s -c "microk8s kubectl exec -it $JENKINS_POD -n jenkins -- bash -c 'mkdir -p /var/jenkins_home/.ssh && ssh-keyscan github.com >> /var/jenkins_home/.ssh/known_hosts'"
   ```

5. **Update your Jenkins pipeline job to use SSH**:
   - Go to your pipeline job > Configure
   - Under "Pipeline" > "Definition" > "Pipeline script from SCM" > "SCM" > "Git"
   - Change the repository URL to the SSH format (e.g., git@github.com:Niroth36/SimpleEshop.git)
   - Select your SSH credentials from the Credentials dropdown
   - Click "Save"

6. **Update your Jenkinsfile to use SSH** (optional):
   - Open your Jenkinsfile
   - Change any HTTPS Git operations to use SSH:
     ```groovy
     // Change this:
     sh "git clone https://github.com/Niroth36/SimpleEshop.git"

     // To this:
     sh "git clone git@github.com:Niroth36/SimpleEshop.git"

     // And change this:
     withCredentials([usernamePassword(credentialsId: 'github-credentials', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
         sh "git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/Niroth36/SimpleEshop.git main"
     }

     // To this:
     sshagent(['github-ssh-key']) {
         sh "git push origin main"
     }
     ```

For more detailed instructions on setting up SSH authentication, see [JENKINS-SSH-SETUP.md](JENKINS-SSH-SETUP.md).

### Pipeline Not Triggering

1. **Check Webhook Delivery**: In GitHub, go to your repository > "Settings" > "Webhooks" > click on your webhook > "Recent Deliveries" to see if there are any failed deliveries and why they failed.

2. **Check Jenkins Logs**: Go to "Manage Jenkins" > "System Log" to check for any errors related to webhook processing.

3. **Firewall Issues**: Ensure that port 30080 is open on your control plane VM and that GitHub can reach your Jenkins server.

4. **URL Issues**: Make sure the webhook URL is correct and includes the trailing slash: `http://4.210.149.226:30080/github-webhook/`

### Docker Build Issues

1. **Docker Not Installed**: Verify that Docker is installed in the Jenkins container.

2. **Permission Issues**: Ensure that the Jenkins user has permission to use Docker.

3. **Docker Hub Rate Limiting**: If you encounter Docker Hub rate limiting, ensure you've configured Docker Hub credentials in Jenkins.

### Git Push Issues

1. **Credentials Issues**: Verify that the GitHub credentials are correct.

2. **Repository Access**: Ensure that the GitHub user has write access to the repository.

## Conclusion

You have successfully set up a Jenkins pipeline for your SimpleEshop web application. This pipeline automatically builds, tests, and deploys your application whenever changes are pushed to the web-app directory in your GitHub repository.

This setup follows GitOps best practices, with Jenkins handling the CI part (building and testing) and ArgoCD handling the CD part (deployment to Kubernetes). The separation of concerns ensures that your deployment is always in sync with the desired state defined in your GitOps directory.
