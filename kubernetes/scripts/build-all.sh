#!/bin/bash

# build-all.sh - Build and deploy all services
set -e

echo "🚀 Starting SimpleEshop Infrastructure Build..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_warning "kubectl is not installed or not in PATH. Will only build Docker images."
    KUBECTL_AVAILABLE=false
else
    KUBECTL_AVAILABLE=true
fi

# Build SimpleEshop main application
print_header "Building SimpleEshop Application"
docker build -t niroth36/simpleeshop:latest -f ../../Dockerfile ../../
print_status "SimpleEshop application built successfully"

# Build Welcome Email Service
print_header "Building Welcome Email Service"
cd ../../web-app/server/email-services/welcome-email
docker build -t niroth36/welcome-email:latest -f Dockerfile.k8s .
print_status "Welcome Email Service built successfully"

# Build Order Confirmation Email Service
print_header "Building Order Confirmation Email Service"
cd ../order-confirmation-email
docker build -t niroth36/order-confirmation-email:latest -f Dockerfile.k8s .
print_status "Order Confirmation Email Service built successfully"

# Return to the scripts directory
cd ../../../../kubernetes/scripts

# Push images to Docker Hub if credentials are available
if [ -n "$DOCKER_USERNAME" ] && [ -n "$DOCKER_PASSWORD" ]; then
    print_header "Pushing Images to Docker Hub"
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    
    docker push niroth36/simpleeshop:latest
    docker push niroth36/welcome-email:latest
    docker push niroth36/order-confirmation-email:latest
    
    print_status "Images pushed to Docker Hub"
else
    print_warning "Docker Hub credentials not found. Skipping push."
    print_warning "Set DOCKER_USERNAME and DOCKER_PASSWORD environment variables to enable pushing."
fi

# Deploy to Kubernetes if kubectl is available
if [ "$KUBECTL_AVAILABLE" = true ]; then
    print_header "Deploying to Kubernetes"
    
    # Run the deploy script
    ./deploy-all.sh
    
    print_status "Deployment completed"
else
    print_warning "kubectl not available. Skipping deployment to Kubernetes."
    print_warning "Run ./deploy-all.sh manually to deploy to Kubernetes."
fi

print_header "🎉 Build Summary"
echo "SimpleEshop Application: niroth36/simpleeshop:latest"
echo "Welcome Email Service: niroth36/welcome-email:latest"
echo "Order Confirmation Email Service: niroth36/order-confirmation-email:latest"

if [ "$KUBECTL_AVAILABLE" = true ]; then
    echo ""
    echo "Services deployed to Kubernetes"
else
    echo ""
    echo "Services built but not deployed to Kubernetes"
fi

echo ""
print_status "Build completed successfully! 🎉"