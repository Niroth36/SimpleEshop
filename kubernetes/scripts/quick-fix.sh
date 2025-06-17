#!/bin/bash
# kubernetes/scripts/quick-fix.sh

echo "🔧 Quick Fix for SimpleEshop Pods"
echo "================================="

echo "1️⃣  Checking current pod status..."
kubectl get pods -n simpleeshop -o wide

echo ""
echo "2️⃣  Restarting failed pods..."
kubectl rollout restart deployment/simpleeshop -n simpleeshop

echo ""
echo "3️⃣  Waiting for rollout..."
kubectl rollout status deployment/simpleeshop -n simpleeshop --timeout=300s

echo ""
echo "4️⃣  Final status:"
kubectl get pods -n simpleeshop -o wide

echo ""
echo "5️⃣  Testing connectivity..."
echo "Database connection test:"
kubectl exec -n simpleeshop deployment/postgres -- pg_isready -U techhub -d techgearhub

echo ""
echo "App pods logs:"
kubectl logs -n simpleeshop deployment/simpleeshop --tail=5