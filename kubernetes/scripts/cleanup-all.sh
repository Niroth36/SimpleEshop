#!/bin/bash
# kubernetes/scripts/cleanup-all.sh - Improved version

set -e

echo "🧹 Cleaning up SimpleEshop deployment..."
echo "========================================"

# Function to force delete stuck resources
force_cleanup() {
    echo "🔨 Force cleaning stuck resources..."
    
    # Delete pods with force
    kubectl delete pods --all -n simpleeshop --force --grace-period=0 --ignore-not-found=true
    
    # Delete deployments with force
    kubectl delete deployments --all -n simpleeshop --force --grace-period=0 --ignore-not-found=true
    
    # Delete services
    kubectl delete services --all -n simpleeshop --ignore-not-found=true
    
    # Delete configmaps
    kubectl delete configmaps --all -n simpleeshop --ignore-not-found=true
    
    # Delete PVCs (this might take time)
    kubectl delete pvc --all -n simpleeshop --ignore-not-found=true
    
    # Remove finalizers from namespace if stuck
    kubectl patch namespace simpleeshop -p '{"metadata":{"finalizers":[]}}' --type=merge --ignore-not-found=true
    
    # Force delete namespace
    kubectl delete namespace simpleeshop --force --grace-period=0 --ignore-not-found=true
}

echo "1️⃣  Checking current resources..."
kubectl get all -n simpleeshop --ignore-not-found=true || echo "Namespace doesn't exist or is inaccessible"

echo ""
echo "2️⃣  Graceful deletion of application components..."
kubectl delete -f ../applications/ --ignore-not-found=true --timeout=30s || echo "Graceful app deletion failed, will force"

echo ""
echo "3️⃣  Graceful deletion of database components..."
kubectl delete -f ../database/ --ignore-not-found=true --timeout=30s || echo "Graceful DB deletion failed, will force"

echo ""
echo "4️⃣  Graceful deletion of namespace..."
kubectl delete -f ../namespaces/ --ignore-not-found=true --timeout=30s || echo "Graceful namespace deletion failed, will force"

echo ""
echo "5️⃣  Waiting for graceful cleanup..."
sleep 15

# Check if namespace still exists
if kubectl get namespace simpleeshop >/dev/null 2>&1; then
    echo ""
    echo "⚠️  Namespace still exists, checking status..."
    kubectl get namespace simpleeshop -o yaml | grep -A5 -B5 phase || true
    
    echo ""
    echo "6️⃣  Force cleanup required..."
    force_cleanup
    
    echo ""
    echo "7️⃣  Final wait for cleanup..."
    sleep 10
else
    echo "✅ Graceful cleanup successful!"
fi

echo ""
echo "8️⃣  Verification..."
if kubectl get namespace simpleeshop >/dev/null 2>&1; then
    echo "❌ Namespace still exists - manual intervention required"
    echo "Run: kubectl get namespace simpleeshop -o yaml"
    echo "Then: kubectl patch namespace simpleeshop -p '{\"metadata\":{\"finalizers\":[]}}' --type=merge"
    echo "Finally: kubectl delete namespace simpleeshop --force --grace-period=0"
    exit 1
else
    echo "✅ Complete cleanup successful!"
fi

echo ""
echo "📊 Remaining resources check:"
kubectl get all -A | grep simpleeshop || echo "✅ No SimpleEshop resources found"

echo ""
echo "🔍 Available namespaces:"
kubectl get namespaces

echo ""
echo "🎉 Ready for fresh deployment!"