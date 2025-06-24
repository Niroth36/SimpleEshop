# Setting Up CI/CD Pipeline for SimpleEshop Web App

This comprehensive guide will walk you through the process of setting up a complete CI/CD pipeline for the SimpleEshop web application using Jenkins, GitHub, and ArgoCD.

## Overview

The CI/CD pipeline will:
1. Monitor GitHub for changes in the web-app directory
2. Automatically trigger a build when changes are detected
3. Build and test the web application
4. Push the Docker image to Docker Hub
5. Update the Kubernetes manifests in the GitOps repository
6. ArgoCD will then automatically deploy the updated application to the Kubernetes cluster

## Prerequisites

- Jenkins and ArgoCD installed on your Kubernetes cluster (as per the JENKINS-ARGOCD-DEPLOYMENT.md guide)
- GitHub repository for your SimpleEshop application
- Docker Hub account
- Access to your control plane VM

## Step 1: Create a Jenkins Pipeline for the Web App

1. SSH into your control plane VM:
   ```bash
   ssh azureuser@<YOUR_CONTROL_PLANE_IP>
   ```

2. Create a new file called `Jenkinsfile.webapp` in your SimpleEshop repository with the following content:

   ```groovy
   pipeline {
       agent any

       environment {
           DOCKER_HUB_CREDS = credentials('docker-hub-credentials')
           DOCKER_IMAGE = '<YOUR_DOCKERHUB_USERNAME>/simpleeshop'
           DOCKER_TAG = "${env.BUILD_NUMBER}"
       }

       stages {
           stage('Checkout') {
               steps {
                   checkout scm
               }
           }

           stage('Check for Web App Changes') {
               steps {
                   script {
                       // Get the list of changed files
                       def changedFiles = sh(script: 'git diff --name-only HEAD^ HEAD', returnStdout: true).trim()

                       // Check if any files in the web-app directory have changed
                       def webAppChanged = sh(script: 'git diff --name-only HEAD^ HEAD | grep -q "^web-app/" || echo "false"', returnStdout: true).trim()

                       if (webAppChanged == 'false') {
                           echo "No changes detected in web-app directory. Skipping build."
                           currentBuild.result = 'SUCCESS'
                           return
                       }

                       echo "Changes detected in web-app directory. Proceeding with build."
                   }
               }
           }

           stage('Install Dependencies') {
               steps {
                   dir('web-app/server') {
                       sh 'npm ci'
                   }
               }
           }

           stage('Lint') {
               steps {
                   dir('web-app/server') {
                       // Add linting if you have ESLint configured
                       sh 'echo "Linting would run here if configured"'
                   }
               }
           }

           stage('Test') {
               steps {
                   dir('web-app/server') {
                       // Run tests if you have them configured
                       sh 'echo "Tests would run here if configured"'

                       // Run the integration tests for email services
                       sh 'cd ../../ && ./test-integration.sh'
                   }
               }
           }

           stage('Build Docker Image') {
               steps {
                   sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                   sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
               }
           }

           stage('Push to Docker Hub') {
               steps {
                   sh "echo ${DOCKER_HUB_CREDS_PSW} | docker login -u ${DOCKER_HUB_CREDS_USR} --password-stdin"
                   sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                   sh "docker push ${DOCKER_IMAGE}:latest"
               }
           }

           stage('Update Kubernetes Manifests') {
               steps {
                   script {
                       // Clone the GitOps repository
                       sh "git clone https://github.com/<YOUR_GITHUB_USERNAME>/SimpleEshop-gitops.git"

                       // Update the image tags in the deployment manifests
                       dir('SimpleEshop-gitops') {
                           // Update main app image
                           sh "sed -i 's|image: ${DOCKER_IMAGE}:.*|image: ${DOCKER_IMAGE}:${DOCKER_TAG}|' kubernetes/applications/simpleeshop-deployment.yaml"

                           // Commit and push the changes
                           sh "git config user.email 'jenkins@example.com'"
                           sh "git config user.name 'Jenkins CI'"
                           sh "git add kubernetes/applications/simpleeshop-deployment.yaml"
                           sh "git commit -m 'Update web-app image tag to ${DOCKER_TAG}'"

                           withCredentials([usernamePassword(credentialsId: 'github-credentials', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
                               sh "git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/<YOUR_GITHUB_USERNAME>/SimpleEshop-gitops.git main"
                           }
                       }
                   }
               }
           }
       }

       post {
           always {
               sh "docker logout"
               cleanWs()
           }
           success {
               echo "Web App Pipeline completed successfully!"
           }
           failure {
               echo "Web App Pipeline failed!"
           }
       }
   }
   ```

3. Commit and push this file to your GitHub repository:
   ```bash
   git add Jenkinsfile.webapp
   git commit -m "Add web-app specific Jenkins pipeline"
   git push origin main
   ```

## Step 2: Set Up SSH Keys for Jenkins to Access GitHub

Follow these steps to set up SSH keys for Jenkins to securely access your GitHub repositories:

1. SSH into your control plane VM:
   ```bash
   ssh azureuser@<YOUR_CONTROL_PLANE_IP>
   ```

2. Generate an SSH key pair for the Jenkins user:
   ```bash
   # Get the Jenkins pod name
   JENKINS_POD=$(sg microk8s -c "microk8s kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}'")

   # Execute commands in the Jenkins container
   sg microk8s -c "microk8s kubectl exec -it $JENKINS_POD -n jenkins -- bash -c 'mkdir -p /var/jenkins_home/.ssh && ssh-keygen -t rsa -b 4096 -C \"jenkins@simpleeshop\" -f /var/jenkins_home/.ssh/id_rsa -N \"\" && cat /var/jenkins_home/.ssh/id_rsa.pub'"
   ```

3. Copy the output (the public key) and add it to your GitHub account:
   - Go to GitHub > Settings > SSH and GPG keys
   - Click "New SSH key"
   - Give it a title (e.g., "Jenkins SimpleEshop")
   - Paste the public key
   - Click "Add SSH key"

4. Configure Jenkins to use SSH for Git:
   - Access Jenkins at http://<YOUR_CONTROL_PLANE_IP>:30080
   - Go to "Manage Jenkins" > "Manage Credentials" > "Jenkins" > "Global credentials" > "Add Credentials"
   - Select "SSH Username with private key" from the "Kind" dropdown
   - Set the ID to "github-ssh-key"
   - Set the Username to "git"
   - Select "Enter directly" for the Private Key option
   - Get the private key from the Jenkins container:
     ```bash
     sg microk8s -c "microk8s kubectl exec -it $JENKINS_POD -n jenkins -- cat /var/jenkins_home/.ssh/id_rsa"
     ```
   - Paste the private key
   - Click "OK" to save the credentials

5. Configure known hosts in the Jenkins container:
   ```bash
   sg microk8s -c "microk8s kubectl exec -it $JENKINS_POD -n jenkins -- bash -c 'ssh-keyscan github.com >> /var/jenkins_home/.ssh/known_hosts'"
   ```

6. Update your Jenkinsfile.webapp to use SSH instead of HTTPS (optional):
   ```groovy
   // Change this line:
   sh "git clone https://github.com/<YOUR_GITHUB_USERNAME>/SimpleEshop-gitops.git"

   // To this:
   sh "git clone git@github.com:<YOUR_GITHUB_USERNAME>/SimpleEshop-gitops.git"

   // And change this block:
   withCredentials([usernamePassword(credentialsId: 'github-credentials', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
       sh "git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/<YOUR_GITHUB_USERNAME>/SimpleEshop-gitops.git main"
   }

   // To this:
   sshagent(['github-ssh-key']) {
       sh "git push origin main"
   }
   ```

## Step 3: Create a Jenkins Job for the Web App Pipeline

1. Access Jenkins at http://<YOUR_CONTROL_PLANE_IP>:30080
2. Click "New Item"
3. Enter a name (e.g., "SimpleEshop-WebApp")
4. Select "Pipeline" and click "OK"
5. In the configuration page:
   - Under "General", check "GitHub project" and enter your repository URL (e.g., https://github.com/<YOUR_GITHUB_USERNAME>/SimpleEshop)
   - Under "Build Triggers", check "GitHub hook trigger for GITScm polling"
   - Under "Pipeline", select "Pipeline script from SCM"
   - Select "Git" as the SCM
   - Enter your repository URL (e.g., https://github.com/<YOUR_GITHUB_USERNAME>/SimpleEshop.git)
   - Specify the branch (e.g., "main")
   - Set the Script Path to "Jenkinsfile.webapp"
   - Click "Save"

## Step 4: Set Up GitHub Webhook

1. Go to your GitHub repository (e.g., https://github.com/<YOUR_GITHUB_USERNAME>/SimpleEshop)
2. Click on "Settings" > "Webhooks" > "Add webhook"
3. Set the Payload URL to `http://<YOUR_CONTROL_PLANE_IP>:30080/github-webhook/`
4. Set the Content type to `application/json`
5. For "Which events would you like to trigger this webhook?", select "Just the push event"
6. Check "Active"
7. Click "Add webhook"

## Step 5: Test the Pipeline

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

2. Go to your Jenkins dashboard and check if the pipeline was triggered
3. Monitor the pipeline execution to ensure it completes successfully

## Step 6: Verify the Deployment

After the pipeline completes successfully:

1. Access ArgoCD at https://<YOUR_CONTROL_PLANE_IP>:30443
2. Log in with the admin credentials
3. Check the SimpleEshop application status
4. Verify that it's synced and healthy
5. Access your application at http://<YOUR_CONTROL_PLANE_IP>:30000 to ensure it's working correctly

## Troubleshooting

### Jenkins Pipeline Issues

1. **Pipeline Not Triggering**: Check the GitHub webhook delivery status and Jenkins logs
2. **Build Failures**: Check the Jenkins console output for error messages
3. **Docker Build Issues**: Ensure Docker is installed and running on the Jenkins agent
4. **Git Push Issues**: Verify that the GitHub credentials are correct

### SSH Key Issues

1. **Permission Problems**: Ensure the SSH key files have the correct permissions
2. **Host Key Verification**: Add GitHub's host key to the known_hosts file
3. **Authentication Failures**: Verify that the public key is correctly added to GitHub

### Webhook Issues

1. **Delivery Failures**: Check the GitHub webhook delivery status for error messages
2. **Connectivity Issues**: Ensure that port 30080 is open on your control plane VM
3. **URL Problems**: Verify that the webhook URL is correct and includes the trailing slash

## Next Steps

Once you have the web-app pipeline working correctly, you can create a similar pipeline for the infrastructure configuration files:

1. Create a new Jenkinsfile.infra file
2. Create a new Jenkins job for the infrastructure pipeline
3. Configure it to monitor changes in the kubernetes, infrastructure, and ansible directories
4. Implement appropriate testing and deployment steps for infrastructure changes

## Conclusion

You have successfully set up a CI/CD pipeline for the SimpleEshop web application using Jenkins, GitHub, and ArgoCD. This pipeline automatically builds, tests, and deploys your application whenever changes are pushed to the web-app directory in your GitHub repository.

This setup follows GitOps best practices, with Jenkins handling the CI part (building and testing) and ArgoCD handling the CD part (deployment to Kubernetes). The separation of concerns ensures that your deployment is always in sync with the desired state defined in your GitOps repository.
