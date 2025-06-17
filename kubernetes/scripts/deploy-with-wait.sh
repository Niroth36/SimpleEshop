#!/bin/bash  
# kubernetes/scripts/deploy-with-wait.sh - Deploy with proper waiting

set -e

echo "🚀 Deploying SimpleEshop with Proper Waiting"
echo "============================================="

# Check if namespace exists and is terminating
if kubectl get namespace simpleeshop >/dev/null 2>&1; then
    NS_STATUS=$(kubectl get namespace simpleeshop -o jsonpath='{.status.phase}' 2>/dev/null || echo "unknown")
    if [ "$NS_STATUS" = "Terminating" ]; then
        echo "⚠️  Namespace is terminating. Waiting for cleanup..."
        ./wait-for-cleanup.sh
    fi
fi

echo "📡 Checking cluster connectivity..."
kubectl get nodes -o wide

echo ""
echo "1️⃣  Creating namespace..."
kubectl apply -f ../namespaces/
kubectl wait --for=condition=Ready namespace/simpleeshop --timeout=60s

echo ""
echo "2️⃣  Deploying database components..."
kubectl apply -f ../database/

echo ""
echo "3️⃣  Waiting for database to be ready..."
echo "   This may take a few minutes..."
kubectl wait --for=condition=ready pod -l app=postgres -n simpleeshop --timeout=300s

echo ""
echo "4️⃣  Deploying application components..."
kubectl apply -f ../applications/

echo ""
echo "5️⃣  Waiting for application to be ready..."
echo "   This may take a few minutes..."
kubectl wait --for=condition=ready pod -l app=simpleeshop -n simpleeshop --timeout=300s

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Final Status:"
kubectl get all -n simpleeshop -o wide

echo ""
echo "🌐 Access URLs:"
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│                     SimpleEshop Access                     │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│ Control Plane:     http://108.142.156.228:30000            │"
echo "│ West Europe:       http://128.251.152.53:30000             │"
echo "│ Sweden Central:    http://4.223.108.114:30000              │"
echo "└─────────────────────────────────────────────────────────────┘"