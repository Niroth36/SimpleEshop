#!/bin/bash
# install-jenkins-tools.sh

echo "🔧 Installing Node.js and Docker in Jenkins container..."

JENKINS_POD=$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}')

kubectl exec -it $JENKINS_POD -n jenkins -- bash -c "
    # Update package manager
    apt-get update
    
    # Install Node.js 18
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
    
    # Install Docker
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable' > /etc/apt/sources.list.d/docker.list
    apt-get update
    apt-get install -y docker-ce-cli
    
    # Install Docker Buildx
    mkdir -p ~/.docker/cli-plugins/
    curl -SL https://github.com/docker/buildx/releases/latest/download/buildx-v0.11.2.linux-amd64 -o ~/.docker/cli-plugins/docker-buildx
    chmod +x ~/.docker/cli-plugins/docker-buildx
    
    # Verify installations
    echo '✅ Node.js version:'
    node --version
    echo '✅ npm version:'
    npm --version
    echo '✅ Docker version:'
    docker --version
    echo '✅ Docker buildx:'
    docker buildx version
    
    echo '🎉 All tools installed successfully!'
"

echo "✅ Jenkins tools installation complete!"