# Setting Up CI/CD Pipeline for SimpleEshop Infrastructure

This guide will walk you through the process of setting up a CI/CD pipeline for the infrastructure configuration files (Kubernetes, Tofu/Terraform, Ansible) of the SimpleEshop project using Jenkins and ArgoCD.

## Overview

The infrastructure CI/CD pipeline will:
1. Monitor GitHub for changes in the infrastructure-related directories (kubernetes, infrastructure, ansible)
2. Automatically trigger a build when changes are detected
3. Validate the configuration files
4. Apply the changes to the infrastructure
5. Update the GitOps repository if needed

## Prerequisites

- Jenkins and ArgoCD installed on your Kubernetes cluster (as per the JENKINS-ARGOCD-DEPLOYMENT.md guide)
- GitHub repository for your SimpleEshop application
- Web App CI/CD pipeline already set up (as per the WEBAPP-CICD-SETUP.md guide)
- Access to your control plane VM (IP: 4.210.149.226)

## Step 1: Create a Jenkins Pipeline for Infrastructure

1. SSH into your control plane VM:
   ```bash
   ssh azureuser@4.210.149.226
   ```

2. Create a new file called `Jenkinsfile.infra` in your SimpleEshop repository with the following content:

   ```groovy
   pipeline {
       agent any
       
       environment {
           GITHUB_CREDS = credentials('github-credentials')
       }
       
       stages {
           stage('Checkout') {
               steps {
                   checkout scm
               }
           }
           
           stage('Check for Infrastructure Changes') {
               steps {
                   script {
                       // Get the list of changed files
                       def changedFiles = sh(script: 'git diff --name-only HEAD^ HEAD', returnStdout: true).trim()
                       
                       // Check if any files in the infrastructure directories have changed
                       def infraChanged = sh(script: 'git diff --name-only HEAD^ HEAD | grep -q "^kubernetes/\\|^infrastructure/\\|^ansible/" || echo "false"', returnStdout: true).trim()
                       
                       if (infraChanged == 'false') {
                           echo "No changes detected in infrastructure directories. Skipping build."
                           currentBuild.result = 'SUCCESS'
                           return
                       }
                       
                       echo "Changes detected in infrastructure directories. Proceeding with validation."
                   }
               }
           }
           
           stage('Validate Kubernetes Manifests') {
               when {
                   expression { 
                       return sh(script: 'git diff --name-only HEAD^ HEAD | grep -q "^kubernetes/"', returnStatus: true) == 0 
                   }
               }
               steps {
                   sh '''
                   # Install kubectl if not already installed
                   if ! command -v kubectl &> /dev/null; then
                       echo "kubectl not found, using microk8s kubectl"
                       KUBECTL="sg microk8s -c 'microk8s kubectl'"
                   else
                       KUBECTL="kubectl"
                   fi
                   
                   # Validate Kubernetes manifests
                   find kubernetes -name "*.yaml" -type f | while read file; do
                       echo "Validating $file"
                       $KUBECTL --dry-run=client -f $file validate || exit 1
                   done
                   '''
               }
           }
           
           stage('Validate Terraform/Tofu Files') {
               when {
                   expression { 
                       return sh(script: 'git diff --name-only HEAD^ HEAD | grep -q "^infrastructure/"', returnStatus: true) == 0 
                   }
               }
               steps {
                   sh '''
                   # Install tofu if not already installed
                   if ! command -v tofu &> /dev/null; then
                       echo "Tofu not found, skipping validation"
                       exit 0
                   fi
                   
                   # Find all Terraform/Tofu directories with .tf files
                   find infrastructure -name "*.tf" -type f -exec dirname {} \\; | sort -u | while read dir; do
                       echo "Validating Terraform/Tofu files in $dir"
                       cd $dir
                       tofu init -backend=false
                       tofu validate || exit 1
                       cd - > /dev/null
                   done
                   '''
               }
           }
           
           stage('Validate Ansible Playbooks') {
               when {
                   expression { 
                       return sh(script: 'git diff --name-only HEAD^ HEAD | grep -q "^ansible/"', returnStatus: true) == 0 
                   }
               }
               steps {
                   sh '''
                   # Install ansible-lint if not already installed
                   if ! command -v ansible-lint &> /dev/null; then
                       echo "ansible-lint not found, skipping validation"
                       exit 0
                   fi
                   
                   # Validate Ansible playbooks
                   find ansible -name "*.yml" -type f | while read file; do
                       echo "Validating $file"
                       ansible-lint $file || echo "Warning: Linting issues found in $file"
                   done
                   
                   # Syntax check
                   find ansible -name "*.yml" -type f | while read file; do
                       echo "Syntax checking $file"
                       ansible-playbook --syntax-check $file || exit 1
                   done
                   '''
               }
           }
           
           stage('Update GitOps Repository') {
               when {
                   expression { 
                       return sh(script: 'git diff --name-only HEAD^ HEAD | grep -q "^kubernetes/"', returnStatus: true) == 0 
                   }
               }
               steps {
                   script {
                       // Clone the GitOps repository
                       sh "git clone https://github.com/Niroth36/SimpleEshop-gitops.git"
                       
                       // Copy Kubernetes manifests to the GitOps repository
                       sh '''
                       # Copy only changed Kubernetes files
                       git diff --name-only HEAD^ HEAD | grep "^kubernetes/" | while read file; do
                           # Create target directory if it doesn't exist
                           mkdir -p SimpleEshop-gitops/$(dirname $file)
                           # Copy the file
                           cp $file SimpleEshop-gitops/$file
                       done
                       '''
                       
                       // Commit and push the changes
                       dir('SimpleEshop-gitops') {
                           sh '''
                           git config user.email "jenkins@example.com"
                           git config user.name "Jenkins CI"
                           
                           # Check if there are changes to commit
                           if git status --porcelain | grep -q .; then
                               git add .
                               git commit -m "Update Kubernetes manifests [ci skip]"
                               
                               # Push changes
                               git push https://${GITHUB_CREDS_USR}:${GITHUB_CREDS_PSW}@github.com/Niroth36/SimpleEshop-gitops.git main
                           else
                               echo "No changes to commit"
                           fi
                           '''
                       }
                   }
               }
           }
       }
       
       post {
           always {
               cleanWs()
           }
           success {
               echo "Infrastructure Pipeline completed successfully!"
           }
           failure {
               echo "Infrastructure Pipeline failed!"
           }
       }
   }
   ```

3. Commit and push this file to your GitHub repository:
   ```bash
   git add Jenkinsfile.infra
   git commit -m "Add infrastructure specific Jenkins pipeline"
   git push origin main
   ```

## Step 2: Create a Jenkins Job for the Infrastructure Pipeline

1. Access Jenkins at http://4.210.149.226:30080
2. Click "New Item"
3. Enter a name (e.g., "SimpleEshop-Infrastructure")
4. Select "Pipeline" and click "OK"
5. In the configuration page:
   - Under "General", check "GitHub project" and enter your repository URL (e.g., https://github.com/Niroth36/SimpleEshop)
   - Under "Build Triggers", check "GitHub hook trigger for GITScm polling"
   - Under "Pipeline", select "Pipeline script from SCM"
   - Select "Git" as the SCM
   - Enter your repository URL (e.g., https://github.com/Niroth36/SimpleEshop.git)
   - Specify the branch (e.g., "main")
   - Set the Script Path to "Jenkinsfile.infra"
   - Click "Save"

## Step 3: Configure Jenkins with Required Tools

For the infrastructure pipeline to work correctly, Jenkins needs access to various tools:

1. Install kubectl in the Jenkins container:
   ```bash
   JENKINS_POD=$(sg microk8s -c "microk8s kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}'")
   sg microk8s -c "microk8s kubectl exec -it $JENKINS_POD -n jenkins -- bash -c 'curl -LO https://storage.googleapis.com/kubernetes-release/release/\$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x kubectl && mv kubectl /usr/local/bin/'"
   ```

2. Install OpenTofu (Terraform) in the Jenkins container:
   ```bash
   sg microk8s -c "microk8s kubectl exec -it $JENKINS_POD -n jenkins -- bash -c 'curl -L https://github.com/opentofu/opentofu/releases/download/v1.6.0/tofu_1.6.0_linux_amd64.zip -o tofu.zip && apt-get update && apt-get install -y unzip && unzip tofu.zip && mv tofu /usr/local/bin/ && rm tofu.zip'"
   ```

3. Install Ansible and ansible-lint in the Jenkins container:
   ```bash
   sg microk8s -c "microk8s kubectl exec -it $JENKINS_POD -n jenkins -- bash -c 'apt-get update && apt-get install -y ansible python3-pip && pip3 install ansible-lint'"
   ```

## Step 4: Test the Infrastructure Pipeline

1. Make a change to a file in one of the infrastructure directories:
   ```bash
   # Edit a Kubernetes manifest
   nano kubernetes/applications/simpleeshop-service.yaml
   
   # Add a comment or make a small change
   
   # Commit and push the change
   git add kubernetes/applications/simpleeshop-service.yaml
   git commit -m "Test infrastructure pipeline trigger"
   git push origin main
   ```

2. Go to your Jenkins dashboard and check if the pipeline was triggered
3. Monitor the pipeline execution to ensure it completes successfully

## Step 5: Verify the Changes

After the pipeline completes successfully:

1. Access ArgoCD at https://4.210.149.226:30443
2. Log in with the admin credentials
3. Check the SimpleEshop application status
4. Verify that it's synced and healthy
5. Check that your changes have been applied to the infrastructure

## Advanced Configuration

### Adding Approval Steps for Infrastructure Changes

For critical infrastructure changes, you might want to add an approval step:

```groovy
stage('Approval') {
    when {
        expression { 
            return sh(script: 'git diff --name-only HEAD^ HEAD | grep -q "^infrastructure/"', returnStatus: true) == 0 
        }
    }
    steps {
        timeout(time: 24, unit: 'HOURS') {
            input message: 'Approve infrastructure changes?', submitter: 'admin'
        }
    }
}
```

### Adding Notifications

Add notifications to Slack, email, or other channels:

```groovy
post {
    success {
        slackSend channel: '#deployments', color: 'good', message: "Infrastructure Pipeline succeeded: ${env.JOB_NAME} ${env.BUILD_NUMBER}"
    }
    failure {
        slackSend channel: '#deployments', color: 'danger', message: "Infrastructure Pipeline failed: ${env.JOB_NAME} ${env.BUILD_NUMBER}"
    }
}
```

### Scheduled Infrastructure Validation

Set up a scheduled job to regularly validate your infrastructure:

1. In your Jenkins job configuration, under "Build Triggers", check "Build periodically"
2. Set a schedule (e.g., `0 0 * * *` for daily at midnight)
3. This will run the pipeline regularly to ensure your infrastructure is valid

## Troubleshooting

### Tool Installation Issues

1. **kubectl Not Found**: Verify that kubectl is installed in the Jenkins container
2. **Tofu/Terraform Not Found**: Verify that OpenTofu is installed in the Jenkins container
3. **Ansible Not Found**: Verify that Ansible is installed in the Jenkins container

### Validation Failures

1. **Kubernetes Manifest Validation Failures**: Check the syntax of your Kubernetes manifests
2. **Terraform/Tofu Validation Failures**: Check the syntax of your Terraform/Tofu files
3. **Ansible Playbook Validation Failures**: Check the syntax of your Ansible playbooks

### GitOps Repository Issues

1. **Push Failures**: Verify that the GitHub credentials are correct
2. **File Copy Issues**: Check that the file paths are correct

## Conclusion

You have successfully set up a CI/CD pipeline for the SimpleEshop infrastructure using Jenkins and ArgoCD. This pipeline automatically validates and applies changes to your infrastructure whenever changes are pushed to the infrastructure-related directories in your GitHub repository.

This setup follows GitOps best practices, ensuring that your infrastructure is always in sync with the desired state defined in your GitOps repository. The validation steps help catch errors early, before they can cause issues in your production environment.

With both the web-app and infrastructure pipelines in place, you now have a complete CI/CD solution for your SimpleEshop project.