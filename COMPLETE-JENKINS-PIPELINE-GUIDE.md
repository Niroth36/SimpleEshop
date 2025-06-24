# Complete Guide to Setting Up a Jenkins Pipeline for SimpleEshop

This comprehensive guide walks you through the entire process of setting up a Jenkins pipeline for your SimpleEshop project, from creating the Jenkinsfile to configuring Jenkins and testing the pipeline.

## Table of Contents

1. [Understanding CI/CD Pipelines](#understanding-cicd-pipelines)
2. [Prerequisites](#prerequisites)
3. [Creating the Jenkinsfile](#creating-the-jenkinsfile)
4. [Setting Up Jenkins](#setting-up-jenkins)
5. [Configuring GitHub Integration](#configuring-github-integration)
6. [Setting Up Docker in Jenkins](#setting-up-docker-in-jenkins)
7. [Running and Testing the Pipeline](#running-and-testing-the-pipeline)
8. [Troubleshooting](#troubleshooting)
9. [Next Steps](#next-steps)

## Understanding CI/CD Pipelines

A CI/CD (Continuous Integration/Continuous Deployment) pipeline automates the process of building, testing, and deploying your application. For SimpleEshop, the pipeline will:

1. **Clone** your repository when changes are detected
2. **Build** your application
3. **Test** your code to ensure it works correctly
4. **Build** a Docker image
5. **Push** the Docker image to Docker Hub
6. **Update** the Kubernetes manifests in your GitOps repository
7. **Deploy** the application via ArgoCD (which monitors the GitOps repository)

## Prerequisites

Before you begin, ensure you have:

1. Jenkins installed and running (accessible at http://<YOUR_CONTROL_PLANE_IP>:30080)
2. Docker Hub account
3. GitHub repository for your SimpleEshop project
4. ArgoCD installed and configured (accessible at https://<YOUR_CONTROL_PLANE_IP>:30443)
5. Access to your control plane VM

## Creating the Jenkinsfile

The Jenkinsfile defines the pipeline stages and steps. If you don't already have a Jenkinsfile.webapp in your repository, create one with the following content:

1. SSH into your control plane VM:
   ```bash
   ssh azureuser@<YOUR_CONTROL_PLANE_IP>
   ```

2. Clone your repository if you haven't already:
   ```bash
   git clone https://github.com/<YOUR_GITHUB_USERNAME>/SimpleEshop.git
   cd SimpleEshop
   ```

3. Create a file named `Jenkinsfile.webapp` with the following content:
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

4. Commit and push the Jenkinsfile to your repository:
   ```bash
   git add Jenkinsfile.webapp
   git commit -m "Add Jenkins pipeline for web app"
   git push origin main
   ```

## Setting Up Jenkins

### Step 1: Configure Jenkins Credentials

1. Access Jenkins at http://<YOUR_CONTROL_PLANE_IP>:30080
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

### Step 2: Install Required Jenkins Plugins

1. Go to "Manage Jenkins" > "Manage Plugins" > "Available"
2. Search for and install the following plugins:
   - Git
   - Docker
   - Docker Pipeline
   - Pipeline
   - GitHub Integration
   - Credentials
   - Blue Ocean (optional, but provides a better UI for pipelines)
3. Click "Install without restart"
4. Check "Restart Jenkins when installation is complete and no jobs are running"

### Step 3: Create a Jenkins Pipeline Job

1. From the Jenkins dashboard, click "New Item"
2. Enter a name for your job (e.g., "SimpleEshop-WebApp")
3. Select "Pipeline" and click "OK"
4. In the configuration page:
   - Under "General", check "GitHub project" and enter your repository URL (e.g., https://github.com/<YOUR_GITHUB_USERNAME>/SimpleEshop)
   - Under "Build Triggers", check "GitHub hook trigger for GITScm polling"
   - Under "Pipeline", select "Pipeline script from SCM"
   - Select "Git" as the SCM
   - Enter your repository URL (e.g., https://github.com/<YOUR_GITHUB_USERNAME>/SimpleEshop.git)
   - Specify the branch (e.g., "main")
   - Set the Script Path to "Jenkinsfile.webapp"
   - Click "Save"

## Configuring GitHub Integration

### Step 1: Configure Jenkins for Webhook Access

1. Go to "Manage Jenkins" > "Configure System"
2. Scroll down to the "GitHub" section
3. Click "Advanced" and check "Specify another hook URL for GitHub configuration"
4. Set the Hook URL to `http://<YOUR_CONTROL_PLANE_IP>:30080/github-webhook/`
5. Click "Save"

### Step 2: Create a GitHub Webhook

1. Go to your GitHub repository (e.g., https://github.com/<YOUR_GITHUB_USERNAME>/SimpleEshop)
2. Click on "Settings" > "Webhooks" > "Add webhook"
3. Set the Payload URL to `http://<YOUR_CONTROL_PLANE_IP>:30080/github-webhook/`
4. Set the Content type to `application/json`
5. For "Which events would you like to trigger this webhook?", select "Just the push event"
6. Check "Active"
7. Click "Add webhook"

## Setting Up Docker in Jenkins

For detailed instructions on setting up Docker in Jenkins, refer to the [JENKINS-DOCKER-SETUP.md](JENKINS-DOCKER-SETUP.md) guide. Here's a summary of the steps:

1. Install Docker CLI in the Jenkins container
2. Create a persistent volume for the Docker socket
3. Update the Jenkins deployment to mount the Docker socket
4. Set correct permissions for Docker access
5. Verify Docker access
6. Install the Docker Pipeline plugin
7. Configure Docker Hub credentials

## Running and Testing the Pipeline

### Step 1: Run Your First Pipeline Build

1. Go to your Jenkins dashboard
2. Click on your pipeline job (e.g., "SimpleEshop-WebApp")
3. Click "Build Now"
4. Monitor the build progress by clicking on the build number and then "Console Output"

### Step 2: Verify the Pipeline Results

After the pipeline completes:

1. Check that the Docker image was pushed to Docker Hub:
   - Go to https://hub.docker.com/r/<YOUR_DOCKERHUB_USERNAME>/simpleeshop/tags
   - Verify that a new tag with the build number exists

2. Check that the GitOps repository was updated:
   - Go to https://github.com/<YOUR_GITHUB_USERNAME>/SimpleEshop-gitops
   - Check the commit history to see if a new commit was made by Jenkins

3. Verify the deployment in ArgoCD:
   - Access ArgoCD at https://<YOUR_CONTROL_PLANE_IP>:30443
   - Log in with the admin credentials
   - Check the SimpleEshop application status
   - Verify that it's synced and healthy

### Step 3: Test Automatic Triggering

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
5. Check your Jenkins pipeline to see if it was triggered automatically

## Troubleshooting

### Pipeline Not Triggering

1. **Check Webhook Delivery**: In GitHub, go to your repository > "Settings" > "Webhooks" > click on your webhook > "Recent Deliveries" to see if there are any failed deliveries and why they failed.

2. **Check Jenkins Logs**: Go to "Manage Jenkins" > "System Log" to check for any errors related to webhook processing.

3. **Firewall Issues**: Ensure that port 30080 is open on your control plane VM and that GitHub can reach your Jenkins server.

4. **URL Issues**: Make sure the webhook URL is correct and includes the trailing slash: `http://<YOUR_CONTROL_PLANE_IP>:30080/github-webhook/`

### Docker Build Issues

1. **Docker Not Installed**: Verify that Docker is installed in the Jenkins container.

2. **Permission Issues**: Ensure that the Jenkins user has permission to use Docker.

3. **Docker Hub Rate Limiting**: If you encounter Docker Hub rate limiting, ensure you've configured Docker Hub credentials in Jenkins.

### Git Push Issues

1. **Credentials Issues**: Verify that the GitHub credentials are correct.

2. **Repository Access**: Ensure that the GitHub user has write access to the GitOps repository.

## Next Steps

Once you have your web app pipeline working, consider:

1. **Setting up a separate pipeline for infrastructure changes**: Create a Jenkinsfile.infra to handle changes to Kubernetes manifests, Terraform/Tofu files, and Ansible playbooks.

2. **Implementing more comprehensive testing**: Add unit tests, integration tests, and end-to-end tests to your pipeline.

3. **Setting up notifications**: Configure Jenkins to send notifications (email, Slack, etc.) when builds succeed or fail.

4. **Implementing security scanning**: Add security scanning tools to your pipeline to identify vulnerabilities.

5. **Setting up monitoring**: Implement monitoring for your CI/CD pipeline to track build times, success rates, and other metrics.

## Conclusion

You have successfully set up a complete CI/CD pipeline for your SimpleEshop web application using Jenkins, GitHub, Docker, and ArgoCD. This pipeline automatically builds, tests, and deploys your application whenever changes are pushed to your GitHub repository.

This setup follows GitOps best practices, with Jenkins handling the CI part (building and testing) and ArgoCD handling the CD part (deployment to Kubernetes). The separation of concerns ensures that your deployment is always in sync with the desired state defined in your GitOps repository.

For more detailed information on specific aspects of the setup, refer to the following guides:
- [JENKINS-DOCKER-SETUP.md](JENKINS-DOCKER-SETUP.md): Detailed instructions for setting up Docker in Jenkins
- [JENKINS-SSH-SETUP.md](JENKINS-SSH-SETUP.md): Setting up SSH keys for Jenkins to access GitHub
- [GITHUB-WEBHOOK-SETUP.md](GITHUB-WEBHOOK-SETUP.md): Setting up GitHub webhooks to trigger Jenkins pipelines
- [WEBAPP-CICD-SETUP.md](WEBAPP-CICD-SETUP.md): Comprehensive guide for setting up the web app CI/CD pipeline
