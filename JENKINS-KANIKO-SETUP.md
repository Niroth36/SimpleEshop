# Setting Up Jenkins with Kaniko for Docker Image Building

This guide provides step-by-step instructions for configuring Jenkins to build Docker images using Kaniko and push them to Docker Hub after a commit.

## Overview

The SimpleEshop project uses Kaniko to build Docker images in a Kubernetes environment. Kaniko allows you to build Docker images inside a container without requiring Docker daemon access, which is more secure and works well in Kubernetes environments.

## Prerequisites

Before you begin, ensure you have:

1. Jenkins installed and running in your Kubernetes cluster (accessible at http://4.210.149.226:30080)
2. Docker Hub account
3. GitHub repository for your SimpleEshop project
4. Access to your Kubernetes cluster

## Step 1: Create Docker Hub Credentials Secret

First, you need to create a Kubernetes secret that contains your Docker Hub credentials. This secret will be used by Kaniko to authenticate with Docker Hub when pushing images.

1. Create a Docker Hub config.json file:

```bash
# SSH into your control plane VM
ssh azureuser@4.210.149.226

# Create a temporary directory
mkdir -p /tmp/docker-secret

# Create the config.json file with your Docker Hub credentials
cat > /tmp/docker-secret/config.json << EOF
{
  "auths": {
    "https://index.docker.io/v1/": {
      "auth": "$(echo -n YOUR_DOCKERHUB_USERNAME:YOUR_DOCKERHUB_PASSWORD | base64)"
    }
  }
}
EOF

# Replace YOUR_DOCKERHUB_USERNAME and YOUR_DOCKERHUB_PASSWORD with your actual Docker Hub credentials
```

2. Create a Kubernetes secret from the config.json file:

```bash
# Create the secret in the jenkins namespace
sg microk8s -c "microk8s kubectl create secret generic docker-hub-secret -n jenkins --from-file=.dockerconfigjson=/tmp/docker-secret/config.json --type=kubernetes.io/dockerconfigjson"

# Clean up the temporary file
rm -rf /tmp/docker-secret
```

## Step 2: Configure Jenkins to Use the Existing Jenkinsfile

Now, you need to configure Jenkins to use the existing Jenkinsfile in your repository:

1. Access Jenkins at http://4.210.149.226:30080
2. Click "New Item"
3. Enter a name for your job (e.g., "SimpleEshop")
4. Select "Pipeline" and click "OK"
5. In the configuration page:
   - Under "General", check "GitHub project" and enter your repository URL (e.g., https://github.com/Niroth36/SimpleEshop)
   - Under "Build Triggers", check "GitHub hook trigger for GITScm polling"
   - Under "Pipeline", select "Pipeline script"
   - In the "Script" text area, paste the following script:
     ```groovy
     node {
         // Checkout the repository
         checkout([
             $class: 'GitSCM',
             branches: [[name: '*/main']],
             doGenerateSubmoduleConfigurations: false,
             extensions: [],
             submoduleCfg: [],
             userRemoteConfigs: [[
                 url: 'https://github.com/Niroth36/SimpleEshop.git',
                 credentialsId: 'github-credentials'  // Use your GitHub credentials ID
             ]]
         ])

         // Load and execute the Jenkinsfile from the repository
         def jenkinsfile = load 'Jenkinsfile'
     }
     ```
   - Replace the repository URL and branch name with your own
   - Replace 'github-credentials' with your GitHub credentials ID
   - Click "Save"

Alternatively, if you prefer to use "Pipeline script from SCM", make sure your Git plugin is up to date and try the following:

1. Access Jenkins at http://4.210.149.226:30080
2. Click "New Item"
3. Enter a name for your job (e.g., "SimpleEshop")
4. Select "Pipeline" and click "OK"
5. In the configuration page:
   - Under "General", check "GitHub project" and enter your repository URL (e.g., https://github.com/Niroth36/SimpleEshop)
   - Under "Build Triggers", check "GitHub hook trigger for GITScm polling"
   - Under "Pipeline", select "Pipeline script from SCM"
   - Select "Git" as the SCM
   - Enter your repository URL (e.g., https://github.com/Niroth36/SimpleEshop.git)
   - Add your GitHub credentials if needed
   - Specify the branch (e.g., "main")
   - Set the Script Path to "Jenkinsfile" (not Jenkinsfile.webapp)
   - Under "Additional Behaviours", click "Add" and select "Check out to a sub-directory"
   - Set the "Local subdirectory for repo" to "repo"
   - Click "Save"

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
   - Pipeline
   - GitHub Integration
   - Kubernetes
   - Credentials
3. Click "Install without restart"
4. Check "Restart Jenkins when installation is complete and no jobs are running"

## Step 5: Run Your First Pipeline Build

Now that everything is set up, you can run your first pipeline build:

1. Go to your Jenkins dashboard
2. Click on your pipeline job (e.g., "SimpleEshop")
3. Click "Build Now"
4. Monitor the build progress by clicking on the build number and then "Console Output"

## Step 6: Verify the Pipeline Results

After the pipeline completes:

1. Check that the Docker image was pushed to Docker Hub:
   - Go to https://hub.docker.com/r/niroth36/simpleeshop/tags
   - Verify that a new tag with the build number exists

2. Check that the Kubernetes manifests were updated:
   - The pipeline should have updated the image tag in the Kubernetes deployment manifests

3. Verify the deployment:
   - Access your application to ensure it's running with the new image

## Troubleshooting

### Docker Hub Authentication Issues

If you encounter authentication issues with Docker Hub:

1. Verify that the docker-hub-secret was created correctly:
   ```bash
   sg microk8s -c "microk8s kubectl get secret docker-hub-secret -n jenkins -o yaml"
   ```

2. Check that the secret contains the correct Docker Hub credentials:
   ```bash
   sg microk8s -c "microk8s kubectl get secret docker-hub-secret -n jenkins -o jsonpath='{.data.\\.dockerconfigjson}' | base64 --decode"
   ```

3. If needed, recreate the secret with the correct credentials:
   ```bash
   sg microk8s -c "microk8s kubectl delete secret docker-hub-secret -n jenkins"
   # Then follow Step 1 again to create the secret
   ```

### Pipeline Not Triggering

1. **Check Webhook Delivery**: In GitHub, go to your repository > "Settings" > "Webhooks" > click on your webhook > "Recent Deliveries" to see if there are any failed deliveries and why they failed.

2. **Check Jenkins Logs**: Go to "Manage Jenkins" > "System Log" to check for any errors related to webhook processing.

3. **Firewall Issues**: Ensure that port 30080 is open on your control plane VM and that GitHub can reach your Jenkins server.

### Kaniko Build Issues

1. **Pod Creation Issues**: Check if the Kaniko pod is being created correctly:
   ```bash
   sg microk8s -c "microk8s kubectl get pods -n jenkins"
   ```

2. **Pod Logs**: Check the logs of the Kaniko container for any errors:
   ```bash
   sg microk8s -c "microk8s kubectl logs <pod-name> -c kaniko -n jenkins"
   ```

3. **Secret Mounting Issues**: Verify that the docker-hub-secret is being mounted correctly in the Kaniko container.

### Git Repository Issues

If you encounter errors like "not in a git directory" when running the pipeline, it could be due to how Jenkins is trying to access the Git repository. Here are some solutions:

1. **Use "Pipeline script" instead of "Pipeline script from SCM"**: This approach avoids the issue of Jenkins trying to access the Git repository before the pipeline starts by manually checking out the repository in the pipeline script. See the first option in Step 2 above.

   **This is the recommended solution for the error: "git config remote.origin.url https://github.com/Niroth36/SimpleEshop.git returned status code 128: fatal: not in a git directory"**

   To implement this solution:
   - Go to your Jenkins job
   - Click "Configure"
   - Under "Pipeline", change from "Pipeline script from SCM" to "Pipeline script"
   - Paste the script from Step 2 (the one that uses `checkout([...])`)
   - Click "Save"
   - Run the pipeline again

2. **Use "Pipeline script from SCM" with "Check out to a sub-directory"**: This approach adds the "Check out to a sub-directory" behavior, which might help with the Git repository initialization issue by checking out the repository to a specific subdirectory. See the second option in Step 2 above.

3. **Update the Git plugin**: Make sure your Git plugin is up to date. Go to "Manage Jenkins" > "Manage Plugins" > "Updates" and check if there are updates available for the Git plugin.

4. **Check Jenkins workspace permissions**: Ensure that the Jenkins user has the necessary permissions to create and modify Git repositories in the workspace directory.

5. **Clean the workspace**: If you've already tried running the pipeline and it failed, try cleaning the workspace:
   - Go to your Jenkins job
   - Click "Configure"
   - Under "Build Environment", check "Delete workspace before build starts"
   - Click "Save" and run the pipeline again

## Conclusion

You have successfully configured Jenkins to build Docker images using Kaniko and push them to Docker Hub after a commit. This setup provides a secure and efficient way to build and deploy your SimpleEshop application in a Kubernetes environment.

The pipeline will automatically:
1. Check for changes in the web-app directory
2. Install dependencies and run tests
3. Build a Docker image using Kaniko
4. Push the image to Docker Hub
5. Update the Kubernetes manifests with the new image tag

This setup follows GitOps best practices, with Jenkins handling the CI part (building and testing) and ArgoCD handling the CD part (deployment to Kubernetes).
