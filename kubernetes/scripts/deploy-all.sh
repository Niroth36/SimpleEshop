#!/bin/bash

# deploy-all.sh - Deploy all applications in correct order
set -e

echo "🚀 Starting SimpleEshop Infrastructure Deployment..."

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

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check cluster connectivity
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    print_warning "Make sure your kubeconfig is set up correctly"
    exit 1
fi

# Get cluster info
print_header "Cluster Information"
kubectl get nodes -o wide

# Deploy namespaces first
print_header "Creating Namespaces"
kubectl apply -f namespaces/
print_status "Namespaces created"

# Deploy database (prerequisite for SimpleEshop)
print_header "Deploying Database"
kubectl apply -f database/
print_status "Database manifests applied"

# Wait for database to be ready
print_status "Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n simpleeshop
print_status "PostgreSQL is ready"

# Deploy applications
print_header "Deploying Applications"
kubectl apply -f applications/
print_status "Application manifests applied"

# Deploy Jenkins
print_header "Deploying Jenkins"
kubectl apply -f jenkins/
print_status "Jenkins manifests applied"

# Deploy ArgoCD using official manifests
print_header "Deploying ArgoCD"
print_status "Installing ArgoCD from official manifests..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

print_status "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

print_status "Configuring ArgoCD NodePort service..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort", "ports": [{"port": 443, "targetPort": 8080, "nodePort": 30443, "name": "https"}]}}'

print_status "ArgoCD deployed successfully!"

# Wait for applications to be ready
print_header "Waiting for Applications to be Ready"

print_status "Waiting for SimpleEshop..."
kubectl wait --for=condition=available --timeout=300s deployment/simpleeshop -n simpleeshop

print_status "Waiting for Jenkins..."
kubectl wait --for=condition=available --timeout=300s deployment/jenkins -n jenkins

# Apply ArgoCD applications (now that ArgoCD is running)
print_header "Deploying ArgoCD Applications"
kubectl apply -f argocd/applications/database-app.yaml
kubectl apply -f argocd/applications/jenkins-app.yaml  
kubectl apply -f argocd/applications/simpleeshop-app.yaml
print_status "ArgoCD applications configured"

# Display access information
print_header "🎉 Deployment Complete! Access Information"

# Get external IPs
CONTROL_PLANE_IP=$(kubectl get nodes -o jsonpath='{.items[?(@.metadata.labels.node-role\.kubernetes\.io/control-plane)].status.addresses[?(@.type=="ExternalIP")].address}' || echo "")
WORKER_IPS=$(kubectl get nodes -o jsonpath='{.items[?(@.metadata.labels.node-role\.kubernetes\.io/worker)].status.addresses[?(@.type=="ExternalIP")].address}' || echo "")

# If external IPs not available in node status, try to get from context
if [ -z "$CONTROL_PLANE_IP" ]; then
    # Extract from kubeconfig
    CONTROL_PLANE_IP=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' | sed 's|.*://||' | sed 's|:.*||')
fi

echo ""
echo "📱 Application URLs:"
echo "   SimpleEshop:  http://$CONTROL_PLANE_IP:30000"
echo "   Jenkins:      http://$CONTROL_PLANE_IP:30080"

if kubectl get namespace argocd &> /dev/null; then
    echo "   ArgoCD:       https://$CONTROL_PLANE_IP:30443"
fi

echo ""
echo "🔐 Credentials:"
echo "   ArgoCD:"
echo "     Username: admin"
echo "     Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d 2>/dev/null || echo 'Password not available - check ArgoCD logs')"

echo ""
echo "   Jenkins:"
echo "     Initial setup required. Get password with:"
echo "     kubectl exec -it \$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}') -n jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword"

echo ""
echo "📊 Quick Status Check:"
kubectl get pods -A | grep -E "(simpleeshop|jenkins|argocd)" | head -20

echo ""
print_status "Deployment completed successfully! 🎉"