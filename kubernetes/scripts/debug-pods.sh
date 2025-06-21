#!/bin/bash

# debug-pods.sh - Debug pod issues and show detailed status
set -e

echo "🔍 SimpleEshop Infrastructure Debug Information"

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

# Check cluster connectivity
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi

# Cluster overview
print_header "Cluster Overview"
kubectl get nodes -o wide

print_header "Namespace Status"
kubectl get namespaces | grep -E "(simpleeshop|jenkins|argocd|default)"

# Pod status across all relevant namespaces
print_header "📊 Pod Status"
echo "All pods in simpleeshop, jenkins, and argocd namespaces:"
kubectl get pods -o wide -n simpleeshop 2>/dev/null || print_warning "simpleeshop namespace not found"
kubectl get pods -o wide -n jenkins 2>/dev/null || print_warning "jenkins namespace not found" 
kubectl get pods -o wide -n argocd 2>/dev/null || print_warning "argocd namespace not found"

# Services and endpoints
print_header "🌐 Services and Endpoints"
echo "SimpleEshop services:"
kubectl get svc -n simpleeshop 2>/dev/null || print_warning "simpleeshop namespace not found"

echo ""
echo "Jenkins services:"
kubectl get svc -n jenkins 2>/dev/null || print_warning "jenkins namespace not found"

echo ""
echo "ArgoCD services:"
kubectl get svc -n argocd 2>/dev/null || print_warning "argocd namespace not found"

# Persistent Volumes
print_header "💾 Storage Status"
echo "Persistent Volume Claims:"
kubectl get pvc -A | grep -E "(simpleeshop|jenkins)" || print_status "No PVCs found"

echo ""
echo "Persistent Volumes:"
kubectl get pv | grep -E "(simpleeshop|jenkins)" || print_status "No PVs found"

# Deployment status
print_header "🚀 Deployment Status"
echo "SimpleEshop deployments:"
kubectl get deployments -n simpleeshop 2>/dev/null || print_warning "simpleeshop namespace not found"

echo ""
echo "Jenkins deployments:"
kubectl get deployments -n jenkins 2>/dev/null || print_warning "jenkins namespace not found"

# Events (recent issues)
print_header "⚠️  Recent Events"
echo "Recent events in simpleeshop namespace:"
kubectl get events -n simpleeshop --sort-by='.lastTimestamp' | tail -10 2>/dev/null || print_warning "No events or namespace not found"

echo ""
echo "Recent events in jenkins namespace:"
kubectl get events -n jenkins --sort-by='.lastTimestamp' | tail -10 2>/dev/null || print_warning "No events or namespace not found"

# Check for failed pods and show logs
print_header "🚨 Failed Pods Analysis"
FAILED_PODS=$(kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded --no-headers 2>/dev/null | grep -E "(simpleeshop|jenkins)" || echo "")

if [ ! -z "$FAILED_PODS" ]; then
    print_warning "Found failed pods:"
    echo "$FAILED_PODS"
    echo ""
    
    # Show logs for failed pods
    while IFS= read -r line; do
        if [ ! -z "$line" ]; then
            NAMESPACE=$(echo $line | awk '{print $1}')
            POD_NAME=$(echo $line | awk '{print $2}')
            STATUS=$(echo $line | awk '{print $4}')
            
            print_warning "Logs for failed pod: $POD_NAME in namespace: $NAMESPACE (Status: $STATUS)"
            echo "--- Pod Description ---"
            kubectl describe pod $POD_NAME -n $NAMESPACE | tail -20
            echo ""
            echo "--- Pod Logs ---"
            kubectl logs $POD_NAME -n $NAMESPACE --tail=20 2>/dev/null || print_error "Could not get logs for $POD_NAME"
            echo ""
            echo "----------------------------------------"
        fi
    done <<< "$FAILED_PODS"
else
    print_status "No failed pods found"
fi

# Resource usage
print_header "📈 Resource Usage"
echo "Node resource usage:"
kubectl top nodes 2>/dev/null || print_warning "Metrics server not available"

echo ""
echo "Pod resource usage:"
kubectl top pods -A 2>/dev/null | grep -E "(simpleeshop|jenkins|argocd)" || print_warning "Metrics server not available or no pods found"

# Network policies (if any)
print_header "🌐 Network Policies"
kubectl get networkpolicies -A 2>/dev/null | grep -E "(simpleeshop|jenkins)" || print_status "No network policies found"

# ArgoCD Applications (if ArgoCD exists)
if kubectl get namespace argocd &> /dev/null; then
    print_header "🔄 ArgoCD Applications"
    kubectl get applications -n argocd 2>/dev/null || print_warning "No ArgoCD applications found"
fi

# Access URLs
print_header "🔗 Access URLs"
CONTROL_PLANE_IP=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' | sed 's|.*://||' | sed 's|:.*||')

echo "Application Access URLs:"
echo "  SimpleEshop:  http://$CONTROL_PLANE_IP:30000"
echo "  Jenkins:      http://$CONTROL_PLANE_IP:30080"
echo "  ArgoCD:       https://$CONTROL_PLANE_IP:30443"

# Quick connectivity tests
print_header "🧪 Quick Connectivity Tests"
echo "Testing SimpleEshop service connectivity:"
kubectl get endpoints simpleeshop-service -n simpleeshop 2>/dev/null || print_warning "SimpleEshop service not found"

echo ""
echo "Testing database connectivity:"
kubectl get endpoints postgres-service -n simpleeshop 2>/dev/null || print_warning "Database service not found"

print_status "Debug information collection complete! 🔍"