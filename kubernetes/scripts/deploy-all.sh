#!/bin/bash

set -e

echo "🚀 Deploying SimpleEshop to Multi-Region Kubernetes Cluster"
echo "============================================================"

# Check cluster connectivity
echo "📡 Checking cluster connectivity..."
kubectl get nodes -o wide

echo ""
echo "1️⃣  Creating namespace..."
kubectl apply -f ../namespaces/

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
echo "6️⃣  Deploying email services and Mailpit..."
kubectl apply -k ../email-services/

echo ""
echo "7️⃣  Waiting for email services to be ready..."
echo "   This may take a few minutes..."
kubectl wait --for=condition=ready pod -l app=welcome-email -n simpleeshop --timeout=300s
kubectl wait --for=condition=ready pod -l app=order-confirmation-email -n simpleeshop --timeout=300s
kubectl wait --for=condition=ready pod -l app=mailpit -n simpleeshop --timeout=300s

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Cluster Status:"
kubectl get nodes -o wide
echo ""
echo "📦 Pods Distribution:"
kubectl get pods -n simpleeshop -o wide
echo ""
echo "🔗 Services:"
kubectl get svc -n simpleeshop
echo ""
echo "🌐 Access URLs:"
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│                     SimpleEshop Access                      │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│ Control Plane:     http://108.142.156.228:30000             │"
echo "│ West Europe:       http://128.251.152.53:30000              │"
echo "│ Sweden Central:    http://4.223.108.114:30000               │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│ Mailpit UI:        kubectl port-forward svc/mailpit-service │"
echo "│                    -n simpleeshop 8025:8025                 │"
echo "│                    Then visit: http://localhost:8025        │"
echo "│                    (See MAILPIT-ACCESS.md for details)      │"
echo "└─────────────────────────────────────────────────────────────┘"
echo ""
echo "🔍 View real-time pods:"
echo "   kubectl get pods -n simpleeshop -o wide -w"
echo ""
echo "📜 View logs:"
echo "   kubectl logs -f deployment/simpleeshop -n simpleeshop"
echo ""
echo "🎉 Your multi-region SimpleEshop is now running!"
