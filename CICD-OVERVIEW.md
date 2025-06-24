# SimpleEshop CI/CD Overview

This document provides a high-level overview of the CI/CD setup for the SimpleEshop project, explaining how all the components work together to create a complete continuous integration and continuous deployment pipeline.

## Architecture Overview

The SimpleEshop CI/CD architecture follows GitOps principles, with separate pipelines for the web application and infrastructure components:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  GitHub     │     │   Jenkins   │     │  Docker Hub │
│  Repository │────►│   (CI)      │────►│  Registry   │
└─────────────┘     └──────┬──────┘     └─────────────┘
                           │                    ▲
                           │                    │
                           ▼                    │
                    ┌─────────────┐             │
                    │   GitOps    │             │
                    │  Directory   │            │
                    └──────┬──────┘             │
                           │                    │
                           │                    │
                           ▼                    │
                    ┌─────────────┐             │
                    │   ArgoCD    │             │
                    │    (CD)     │             │
                    └──────┬──────┘             │
                           │                    │
                           │                    │
                           ▼                    │
                    ┌─────────────┐             │
                    │ Kubernetes  │             │
                    │   Cluster   │─────────────┘
                    └─────────────┘
```

## Components

### 1. GitHub Repository

The main GitHub repository (https://github.com/<YOUR_GITHUB_USERNAME>/SimpleEshop) contains:
- Web application code (in the `web-app` directory)
- Infrastructure code (in the `kubernetes`, `infrastructure`, and `ansible` directories)
- CI/CD configuration (Jenkinsfile)

### 2. Jenkins

Jenkins handles the Continuous Integration (CI) part of the pipeline:
- Building and testing the application
- Building Docker images
- Pushing images to Docker Hub
- Updating the GitOps directory with new image tags or configuration changes

We have set up a Jenkins pipeline that handles both web application and infrastructure changes.

### 3. Docker Hub

Docker Hub serves as the container registry where the built Docker images are stored:
- Main application image: `<YOUR_DOCKERHUB_USERNAME>/simpleeshop`
- Welcome email service image: `<YOUR_DOCKERHUB_USERNAME>/welcome-email`
- Order confirmation email service image: `<YOUR_DOCKERHUB_USERNAME>/order-confirmation-email`

### 4. GitOps Directory

The GitOps directory in the main repository contains:
- Kubernetes manifests for deploying the application
- Configuration files for the application
- The desired state of the entire application

This directory is updated by the Jenkins pipeline when changes are made to the application.

### 5. ArgoCD

ArgoCD handles the Continuous Deployment (CD) part of the pipeline:
- Monitoring the GitOps directory for changes
- Automatically deploying changes to the Kubernetes cluster
- Ensuring the actual state of the cluster matches the desired state in the GitOps directory

## Workflow

### Web App Changes

1. Developer makes changes to files in the `web-app` directory
2. Developer commits and pushes changes to GitHub
3. GitHub webhook triggers the Jenkins pipeline
4. Jenkins checks out the code and verifies that changes were made to the `web-app` directory
5. Jenkins builds and tests the application
6. Jenkins builds a new Docker image and tags it with the build number
7. Jenkins pushes the Docker image to Docker Hub
8. Jenkins updates the image tag in the GitOps directory
9. ArgoCD detects the changes in the GitOps directory
10. ArgoCD automatically deploys the new version to the Kubernetes cluster

### Infrastructure Changes

1. Developer makes changes to files in the `kubernetes`, `infrastructure`, or `ansible` directories
2. Developer commits and pushes changes to GitHub
3. GitHub webhook triggers the Jenkins pipeline
4. Jenkins checks out the code and verifies that changes were made to infrastructure files
5. Jenkins validates the infrastructure files (Kubernetes manifests, Terraform/Tofu files, Ansible playbooks)
6. For Kubernetes changes, Jenkins updates the GitOps directory with the new manifests
7. ArgoCD detects the changes in the GitOps directory
8. ArgoCD automatically applies the new configuration to the Kubernetes cluster

## Access Points

- **Jenkins**: http://<YOUR_CONTROL_PLANE_IP>:30080
- **ArgoCD**: https://<YOUR_CONTROL_PLANE_IP>:30443
- **SimpleEshop Application**: http://<YOUR_CONTROL_PLANE_IP>:30000

## Documentation

Detailed documentation for each component of the CI/CD setup is available in the following files:

1. [COMPLETE-JENKINS-PIPELINE-GUIDE.md](COMPLETE-JENKINS-PIPELINE-GUIDE.md): Setting up the CI/CD pipeline
2. [JENKINS-SSH-SETUP.md](JENKINS-SSH-SETUP.md): Setting up SSH keys for Jenkins to access GitHub
3. [GITHUB-WEBHOOK-SETUP.md](GITHUB-WEBHOOK-SETUP.md): Setting up GitHub webhooks to trigger Jenkins pipelines
4. [JENKINS-ARGOCD-DEPLOYMENT.md](JENKINS-ARGOCD-DEPLOYMENT.md): Deploying Jenkins and ArgoCD to Kubernetes
5. [GITOPS.md](GITOPS.md): Overview of the GitOps workflow

## Security Considerations

1. **Credentials**: All sensitive credentials (Docker Hub, GitHub) are stored securely in Jenkins credentials
2. **SSH Keys**: SSH keys are used for secure authentication between Jenkins and GitHub
3. **Webhooks**: GitHub webhooks are configured to only trigger specific pipelines based on the changed files
4. **Approvals**: Critical infrastructure changes can be configured to require manual approval

## Best Practices

1. **Separate Pipelines**: Keep web app and infrastructure pipelines separate to avoid unnecessary builds
2. **Validation**: Always validate infrastructure files before applying changes
3. **GitOps**: Use GitOps principles to ensure that the desired state is always defined in code
4. **Automation**: Automate as much as possible to reduce manual errors
5. **Testing**: Include comprehensive testing in your pipelines
6. **Monitoring**: Monitor your pipelines and deployments for issues

## Next Steps

1. **Add More Tests**: Enhance the testing stages in both pipelines
2. **Implement Monitoring**: Add monitoring for the CI/CD pipelines and deployments
3. **Set Up Notifications**: Configure notifications for pipeline successes and failures
4. **Implement Canary Deployments**: Use ArgoCD to implement canary deployments for safer releases
5. **Add Security Scanning**: Integrate security scanning tools into the pipelines

## Conclusion

The SimpleEshop CI/CD setup provides a robust, automated workflow for building, testing, and deploying both the web application and infrastructure components. By following GitOps principles and separating concerns between different pipelines, the setup ensures that changes are properly validated and deployed in a consistent manner.

This setup can be further enhanced with additional testing, monitoring, and security features as the project evolves.
