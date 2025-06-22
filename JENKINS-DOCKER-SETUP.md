# Setting Up Docker in Jenkins for SimpleEshop CI/CD

This guide provides detailed instructions for setting up Docker in your Jenkins container to enable building and pushing Docker images as part of your CI/CD pipeline.

## Overview

For Jenkins to build and push Docker images, it needs access to the Docker daemon. In a Kubernetes environment, there are several approaches to achieve this:

1. **Docker-in-Docker (DinD)**: Running a Docker daemon inside the Jenkins container
2. **Docker Socket Mounting**: Mounting the host's Docker socket into the Jenkins container
3. **Kaniko**: Using Kaniko to build Docker images without requiring Docker daemon access

This guide will focus on the Docker Socket Mounting approach, which is simpler to set up and works well for most use cases.

## Step 1: Install Docker CLI in the Jenkins Container

First, you need to install the Docker CLI in the Jenkins container:

```bash
# SSH into your control plane VM
ssh azureuser@4.210.149.226

# Get the Jenkins pod name
JENKINS_POD=$(sg microk8s -c "microk8s kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}'")

# Install Docker CLI in the Jenkins container
sg microk8s -c "microk8s kubectl exec -it $JENKINS_POD -n jenkins -- bash -c 'apt-get update && apt-get install -y docker.io curl apt-transport-https ca-certificates software-properties-common'"
```

## Step 2: Create a Persistent Volume for Docker Socket

Create a persistent volume that will be used to mount the Docker socket:

```bash
# Create a PV and PVC for the Docker socket
cat <<EOF | sg microk8s -c "microk8s kubectl apply -f -"
apiVersion: v1
kind: PersistentVolume
metadata:
  name: docker-socket-pv
  namespace: jenkins
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /var/run/docker.sock
  persistentVolumeReclaimPolicy: Retain
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: docker-socket-pvc
  namespace: jenkins
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF
```

## Step 3: Update the Jenkins Deployment

Now, update the Jenkins deployment to mount the Docker socket:

```bash
# Update the Jenkins deployment
cat <<EOF | sg microk8s -c "microk8s kubectl apply -f -"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins
  namespace: jenkins
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      containers:
      - name: jenkins
        image: jenkins/jenkins:lts
        ports:
        - containerPort: 8080
          name: http
        - containerPort: 50000
          name: jnlp
        volumeMounts:
        - name: jenkins-home
          mountPath: /var/jenkins_home
        - name: docker-socket
          mountPath: /var/run/docker.sock
        env:
        - name: JAVA_OPTS
          value: "-Djenkins.install.runSetupWizard=false"
      volumes:
      - name: jenkins-home
        persistentVolumeClaim:
          claimName: jenkins-pvc
      - name: docker-socket
        persistentVolumeClaim:
          claimName: docker-socket-pvc
EOF
```

## Step 4: Set Correct Permissions

The Jenkins user needs to be in the Docker group to access the Docker socket:

```bash
# Get the Docker group ID on the host
DOCKER_GID=$(ssh azureuser@4.210.149.226 "getent group docker | cut -d: -f3")

# Add the Jenkins user to the Docker group in the container
sg microk8s -c "microk8s kubectl exec -it $JENKINS_POD -n jenkins -- bash -c 'groupadd -g $DOCKER_GID docker && usermod -aG docker jenkins'"

# Restart the Jenkins pod to apply the changes
sg microk8s -c "microk8s kubectl delete pod $JENKINS_POD -n jenkins"
```

## Step 5: Verify Docker Access

After the Jenkins pod restarts, verify that Jenkins can access Docker:

```bash
# Get the new Jenkins pod name
JENKINS_POD=$(sg microk8s -c "microk8s kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}'")

# Verify Docker access
sg microk8s -c "microk8s kubectl exec -it $JENKINS_POD -n jenkins -- bash -c 'su jenkins -c \"docker ps\"'"
```

If the command returns a list of running containers (or an empty list), Docker is working correctly.

## Step 6: Install Docker Pipeline Plugin

To use Docker in your Jenkins pipelines, install the Docker Pipeline plugin:

1. Access Jenkins at http://4.210.149.226:30080
2. Go to "Manage Jenkins" > "Manage Plugins" > "Available"
3. Search for "Docker Pipeline"
4. Select the plugin and click "Install without restart"
5. Check "Restart Jenkins when installation is complete and no jobs are running"

## Step 7: Configure Docker Hub Credentials

Configure Docker Hub credentials in Jenkins to allow pushing images:

1. Go to "Manage Jenkins" > "Manage Credentials" > "Jenkins" > "Global credentials" > "Add Credentials"
2. Select "Username with password" from the "Kind" dropdown
3. Enter your Docker Hub username and password
4. Set the ID to "docker-hub-credentials" (this must match the ID used in your Jenkinsfile)
5. Add a description (e.g., "Docker Hub Credentials")
6. Click "OK"

## Step 8: Test Docker in a Pipeline

Create a simple test pipeline to verify that Docker is working correctly:

1. Go to your Jenkins dashboard
2. Click "New Item"
3. Enter a name (e.g., "Docker-Test")
4. Select "Pipeline" and click "OK"
5. In the Pipeline script field, enter:
   ```groovy
   pipeline {
       agent any
       
       stages {
           stage('Test Docker') {
               steps {
                   sh 'docker --version'
                   sh 'docker ps'
                   sh 'docker info'
               }
           }
       }
   }
   ```
6. Click "Save" and then "Build Now"
7. Check the console output to verify that Docker commands are working

## Troubleshooting

### Permission Denied

If you see "permission denied" errors when trying to access the Docker socket:

```bash
# Check the permissions on the Docker socket
ssh azureuser@4.210.149.226 "ls -la /var/run/docker.sock"

# If needed, change the permissions to allow the Jenkins user to access it
ssh azureuser@4.210.149.226 "sudo chmod 666 /var/run/docker.sock"
```

### Docker Socket Not Found

If the Docker socket is not found:

```bash
# Verify that Docker is running on the host
ssh azureuser@4.210.149.226 "systemctl status docker"

# If Docker is not running, start it
ssh azureuser@4.210.149.226 "sudo systemctl start docker"
```

### Docker Group Issues

If adding the Jenkins user to the Docker group doesn't work:

```bash
# Get the Jenkins user ID
JENKINS_UID=$(sg microk8s -c "microk8s kubectl exec -it $JENKINS_POD -n jenkins -- id -u jenkins")

# Create a custom entrypoint script that sets up Docker access
cat <<EOF > docker-entrypoint.sh
#!/bin/bash
set -e

# Add the jenkins user to the Docker group
groupadd -g $DOCKER_GID docker || true
usermod -aG docker jenkins

# Run the original entrypoint
exec /sbin/tini -- /usr/local/bin/jenkins.sh
EOF

# Create a ConfigMap with the entrypoint script
sg microk8s -c "microk8s kubectl create configmap jenkins-entrypoint --from-file=docker-entrypoint.sh -n jenkins"

# Update the Jenkins deployment to use the custom entrypoint
# (This would require modifying the deployment YAML to add the entrypoint)
```

## Alternative Approach: Using Kaniko

If you continue to have issues with Docker socket mounting, consider using Kaniko, which doesn't require Docker daemon access:

1. Install the Kaniko plugin in Jenkins
2. Modify your Jenkinsfile to use Kaniko for building Docker images
3. Configure Kubernetes pod templates for Kaniko

For more information on using Kaniko with Jenkins, refer to the [Kaniko documentation](https://github.com/GoogleContainerTools/kaniko).

## Conclusion

You have successfully set up Docker in your Jenkins container, allowing your CI/CD pipeline to build and push Docker images. This setup enables your SimpleEshop web application pipeline to automatically build and deploy changes whenever code is pushed to your GitHub repository.