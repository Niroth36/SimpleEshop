#!/bin/bash

# cleanup-all.sh - Clean up all deployed applications
set -e

echo "🧹 Starting SimpleEshop Infrastructure Cleanup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Confirmation prompt
echo ""
print_warning "This will delete ALL SimpleEshop applications and data!"
print_warning "This action cannot be undone."
echo ""
read -p "Are you sure you want to continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    print_status "Cleanup cancelled."
    exit 0
fi

# Remove ArgoCD applications first (if they exist)
print_header "Removing ArgoCD Applications"
if kubectl get applications -n argocd &> /dev/null; then
    kubectl delete -f argocd/applications/ --ignore-not-found=true
    print_status "ArgoCD applications removed"
else
    print_warning "No ArgoCD applications found"
fi

# Remove ArgoCD (official installation)
print_header "Removing ArgoCD"
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --ignore-not-found=true
print_status "ArgoCD removed"

# Remove applications
print_header "Removing Applications"
kubectl delete -f applications/ --ignore-not-found=true
print_status "Applications removed"

# Remove Jenkins
print_header "Removing Jenkins"
kubectl delete -f jenkins/ --ignore-not-found=true
print_status "Jenkins removed"

# Remove database (this will delete data!)
print_header "Removing Database"
kubectl delete -f database/ --ignore-not-found=true
print_status "Database removed"

# Wait a bit for graceful shutdown
print_status "Waiting for graceful shutdown..."
sleep 10

# Remove namespaces (this will force delete any remaining resources)
print_header "Removing Namespaces"
kubectl delete namespace simpleeshop --ignore-not-found=true --timeout=60s
kubectl delete namespace jenkins --ignore-not-found=true --timeout=60s
kubectl delete namespace argocd --ignore-not-found=true --timeout=60s

# Force delete if still hanging
print_status "Force cleaning any stuck resources..."
kubectl delete namespace simpleeshop --force --grace-period=0 --ignore-not-found=true 2>/dev/null || true
kubectl delete namespace jenkins --force --grace-period=0 --ignore-not-found=true 2>/dev/null || true
kubectl delete namespace argocd --force --grace-period=0 --ignore-not-found=true 2>/dev/null || true

# Check for persistent volumes that might need manual cleanup
print_header "Checking for Persistent Volumes"
PVS=$(kubectl get pv --no-headers 2>/dev/null | grep -E "(simpleeshop|jenkins|argocd)" | awk '{print $1}' || echo "")
if [ ! -z "$PVS" ]; then
    print_warning "Found persistent volumes that may need manual cleanup:"
    kubectl get pv | grep -E "(simpleeshop|jenkins|argocd)" || true
    echo ""
    print_warning "To delete persistent volumes and lose all data permanently:"
    print_warning "kubectl delete pv $PVS"
else
    print_status "No persistent volumes found"
fi

# Final status
print_header "🧹 Cleanup Summary"
echo "Remaining namespaces:"
kubectl get namespaces | grep -E "(simpleeshop|jenkins|argocd)" && print_warning "Some namespaces still exist" || print_status "All application namespaces removed"

echo ""
print_status "Cleanup completed! 🎉"
print_warning "All applications (SimpleEshop, Jenkins, ArgoCD) have been removed"