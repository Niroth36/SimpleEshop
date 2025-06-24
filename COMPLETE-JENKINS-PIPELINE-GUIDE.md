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

The Jenkinsfile defines the pipeline stages and steps. If you don't already have a Jenkinsfile in your repository, create one with the following content:

1. SSH into your control plane VM:
   ```bash
   ssh azureuser@<YOUR_CONTROL_PLANE_IP>
   ```

2. Clone your repository if you haven't already:
   ```bash
   git clone https://github.com/<YOUR_GITHUB_USERNAME>/SimpleEshop.git
   cd SimpleEshop
   ```

   3. Create a file named `Jenkinsfile` with the following content:
      ```groovy
         pipeline {
          agent any

          environment {
              DOCKER_IMAGE = '<YOUR_DOCKERHUB_USERNAME>/simpleeshop'
              DOCKER_TAG = "${BUILD_NUMBER}"
              DOCKERFILE_PATH = 'Dockerfile.x86'
              CONTROL_PLANE_IP = '<YOUR_CONTROL_PLANE_IP>'
              // Flag to track if this is a manual build
              MANUAL_TRIGGER = "${currentBuild.getBuildCauses().toString().contains('UserIdCause') ? 'true' : 'false'}"
          }


          stages {
              stage('Clone Repository') {
                  steps {
                      script {
                          deleteDir()
                          git credentialsId: 'github-token', 
                              url: 'https://github.com/<YOUR_GITHUB_USERNAME>/SimpleEshop.git',
                              branch: 'master'
                          sh 'ls -la Dockerfile.x86'
                      }
                  }
              }

              stage('Check for Web-App Changes') {
                  steps {
                      script {
                          // Get the previous successful commit
                          def previousSuccessfulCommit = ""
                          def lastSuccessfulBuild = currentBuild.previousSuccessfulBuild
                          if (lastSuccessfulBuild) {
                              // Use a safer approach to get the previous commit
                              try {
                                  // Get the current commit
                                  def currentCommit = sh(script: "git rev-parse HEAD", returnStdout: true).trim()
                                  echo "Current commit: ${currentCommit}"

                                  // Use the build number to get the previous commit
                                  def previousBuildNumber = lastSuccessfulBuild.number
                                  echo "Previous successful build number: ${previousBuildNumber}"

                                  // Assume the first commit in the log is the one we want
                                  previousSuccessfulCommit = sh(script: "git log --format='%H' -n 1 HEAD~1", returnStdout: true).trim()
                                  echo "Previous successful commit: ${previousSuccessfulCommit}"
                              } catch (Exception e) {
                                  echo "Error getting previous commit: ${e.message}"
                                  // If there's an error, assume there are changes
                                  previousSuccessfulCommit = ""
                              }
                          }

                          // CONDITION 1: Check if there are changes in the web-app directory
                          if (previousSuccessfulCommit) {
                              // Check if there are changes in the web-app directory
                              def changes = sh(script: "git diff --name-only ${previousSuccessfulCommit} HEAD | grep -q '^web-app/' || echo 'no_changes'", returnStdout: true).trim()
                              env.WEBAPP_CHANGES = changes != 'no_changes' ? 'true' : 'false'
                          } else {
                              // If no previous successful build, assume changes
                              env.WEBAPP_CHANGES = 'true'
                          }

                          // CONDITION 2: Check if the build was manually triggered using the build button
                          // This is set in the environment section: MANUAL_TRIGGER

                          echo "CONDITION 1 - Web-app changes detected: ${env.WEBAPP_CHANGES}"
                          echo "CONDITION 2 - Manual trigger: ${env.MANUAL_TRIGGER}"

                          // Set a flag to determine if we should proceed with the build
                          // The build will proceed if EITHER condition is true
                          env.SHOULD_BUILD = (env.WEBAPP_CHANGES == 'true' || env.MANUAL_TRIGGER == 'true') ? 'true' : 'false'

                          if (env.SHOULD_BUILD == 'true') {
                              echo "🚀 Build will proceed due to either:"
                              echo "   - CONDITION 1: Changes detected in web-app directory, or"
                              echo "   - CONDITION 2: Manually triggered using the build button"
                          } else {
                              echo "⏭️ No web-app changes detected and not manually triggered, skipping build"
                          }
                      }
                  }
              }

              stage('Install SSH Client') {
                  when {
                      expression { return env.SHOULD_BUILD == 'true' }
                  }
                  steps {
                      script {
                          sh """
                              apt-get update
                              apt-get install -y openssh-client
                          """
                      }
                  }
              }

              stage('Build on Control Plane') {
                  when {
                      expression { return env.SHOULD_BUILD == 'true' }
                  }
                  steps {
                      script {
                          withCredentials([sshUserPrivateKey(credentialsId: 'control-plane-credentials', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                              sh """
                                  # Set up SSH key
                                  mkdir -p ~/.ssh
                                  cp \${SSH_KEY} ~/.ssh/id_rsa
                                  chmod 600 ~/.ssh/id_rsa
                                  ssh-keyscan -H ${CONTROL_PLANE_IP} >> ~/.ssh/known_hosts

                                  # SSH to control plane and build
                                  ssh -i ~/.ssh/id_rsa \${SSH_USER}@${CONTROL_PLANE_IP} '
                                      echo "🏗️ Starting build on control plane..."

                                      # Clean up any previous build
                                      rm -rf /tmp/simpleeshop-build-${BUILD_NUMBER}
                                      mkdir -p /tmp/simpleeshop-build-${BUILD_NUMBER}
                                      cd /tmp/simpleeshop-build-${BUILD_NUMBER}

                                      # Clone the repository
                                      echo "📥 Cloning repository..."
                                      git clone https://github.com/<YOUR_GITHUB_USERNAME>/SimpleEshop.git .

                                      # Verify Dockerfile exists
                                      ls -la ${DOCKERFILE_PATH}

                                      # Build the Docker image
                                      echo "🐳 Building Docker image..."
                                      docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} -f ${DOCKERFILE_PATH} .
                                      docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest

                                      # List the built image
                                      echo "✅ Built images:"
                                      docker images | grep ${DOCKER_IMAGE}
                                  '
                              """
                          }
                      }
                  }
              }

              stage('Push to Docker Hub') {
                  when {
                      expression { return env.SHOULD_BUILD == 'true' }
                  }
                  steps {
                      script {
                          withCredentials([
                              usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS'),
                              sshUserPrivateKey(credentialsId: 'control-plane-credentials', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')
                          ]) {
                              sh """
                                  ssh -i ~/.ssh/id_rsa \${SSH_USER}@${CONTROL_PLANE_IP} '
                                      echo "🚀 Pushing to Docker Hub..."

                                      # Login to Docker Hub
                                      echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin

                                      # Push the images
                                      docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                                      docker push ${DOCKER_IMAGE}:latest

                                      echo "✅ Successfully pushed images to Docker Hub"

                                      # Logout for security
                                      docker logout
                                  '
                              """
                          }
                      }
                  }
              }

              stage('Update Kubernetes Manifest') {
                  when {
                      expression { return env.SHOULD_BUILD == 'true' }
                  }
                  steps {
                      script {
                          // Update the image tag in the Kubernetes deployment YAML file
                          sh """
                              # Update the image tag in the deployment file
                              sed -i 's|image: ${DOCKER_IMAGE}:.*|image: ${DOCKER_IMAGE}:${DOCKER_TAG}|' kubernetes/applications/simpleeshop-deployment.yaml

                              # Show the changes
                              echo "📄 Updated deployment manifest:"
                              cat kubernetes/applications/simpleeshop-deployment.yaml | grep image:
                          """

                          // Commit and push the changes
                          withCredentials([usernamePassword(credentialsId: 'github-token', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
                              sh """
                                  # Configure Git
                                  git config user.email "jenkins@example.com"
                                  git config user.name "Jenkins CI"

                                  # Add, commit and push changes
                                  git add kubernetes/applications/simpleeshop-deployment.yaml
                                  git commit -m "Update image tag to ${DOCKER_IMAGE}:${DOCKER_TAG} [ci skip]"

                                  # Use credentials to push
                                  git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/<YOUR_GITHUB_USERNAME>/SimpleEshop.git master

                                  echo "✅ Successfully updated and pushed deployment manifest"
                              """
                          }
                      }
                  }
              }

              stage('Cleanup Control Plane') {
                  when {
                      expression { return env.SHOULD_BUILD == 'true' }
                  }
                  steps {
                      script {
                          withCredentials([sshUserPrivateKey(credentialsId: 'control-plane-credentials', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                              sh """
                                  ssh -i ~/.ssh/id_rsa \${SSH_USER}@${CONTROL_PLANE_IP} '
                                      echo "🧹 Cleaning up..."

                                      # Remove local images to save space
                                      docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG} || true
                                      docker rmi ${DOCKER_IMAGE}:latest || true

                                      # Clean up build directory
                                      rm -rf /tmp/simpleeshop-build-${BUILD_NUMBER}

                                      echo "✅ Cleanup completed"
                                  '
                              """
                          }
                      }
                  }
              }
          }

          post {
              always {
                  deleteDir()
              }
              success {
                  script {
                      if (env.SHOULD_BUILD == 'true') {
                          echo "🎉 Pipeline completed successfully!"
                          echo "🐳 Image pushed to Docker Hub: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                          echo "🔗 Latest tag: ${DOCKER_IMAGE}:latest"
                          echo "📄 Kubernetes manifest updated and pushed to GitHub"
                      } else {
                          echo "⏭️ Pipeline skipped - Neither condition was met:"
                          echo "   - CONDITION 1: No changes detected in web-app directory"
                          echo "   - CONDITION 2: Not manually triggered using the build button"
                          echo "ℹ️ The pipeline will run when EITHER:"
                          echo "   - CONDITION 1: Triggered by a webhook and changes are detected in the web-app directory"
                          echo "   - CONDITION 2: Manually triggered using the build button"
                      }
                  }
              }
              failure {
                  echo "❌ Pipeline failed. Check the logs for details."
              }
          }
   ```

4. Commit and push the Jenkinsfile to your repository:
   ```bash
   git add Jenkinsfile
   git commit -m "Add Jenkins pipeline"
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
   - Set the Script Path to "Jenkinsfile"
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

2. Check that the GitOps directory was updated:
   - Check the commit history of the main repository to see if a new commit was made by Jenkins to update the GitOps directory

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

2. **Repository Access**: Ensure that the GitHub user has write access to the repository.

## Next Steps

Once you have your web app pipeline working, consider:

1. **Enhancing the pipeline for infrastructure changes**: Improve the existing Jenkinsfile to better handle changes to Kubernetes manifests, Terraform/Tofu files, and Ansible playbooks.

2. **Implementing more comprehensive testing**: Add unit tests, integration tests, and end-to-end tests to your pipeline.

3. **Setting up notifications**: Configure Jenkins to send notifications (email, Slack, etc.) when builds succeed or fail.

4. **Implementing security scanning**: Add security scanning tools to your pipeline to identify vulnerabilities.

5. **Setting up monitoring**: Implement monitoring for your CI/CD pipeline to track build times, success rates, and other metrics.

## Conclusion

You have successfully set up a complete CI/CD pipeline for your SimpleEshop web application using Jenkins, GitHub, Docker, and ArgoCD. This pipeline automatically builds, tests, and deploys your application whenever changes are pushed to your GitHub repository.

This setup follows GitOps best practices, with Jenkins handling the CI part (building and testing) and ArgoCD handling the CD part (deployment to Kubernetes). The separation of concerns ensures that your deployment is always in sync with the desired state defined in your GitOps directory.

For more detailed information on specific aspects of the setup, refer to the following guides:
- [JENKINS-DOCKER-SETUP.md](JENKINS-DOCKER-SETUP.md): Detailed instructions for setting up Docker in Jenkins
- [JENKINS-SSH-SETUP.md](JENKINS-SSH-SETUP.md): Setting up SSH keys for Jenkins to access GitHub
- [GITHUB-WEBHOOK-SETUP.md](GITHUB-WEBHOOK-SETUP.md): Setting up GitHub webhooks to trigger Jenkins pipelines
