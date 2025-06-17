#!/bin/bash
# kubernetes/scripts/test-access.sh

echo "🌐 Testing SimpleEshop Access"
echo "============================="

echo "📊 Current deployment status:"
kubectl get pods,svc -n simpleeshop -o wide

echo ""
echo "🔗 Service endpoints:"
kubectl get endpoints -n simpleeshop

echo ""
echo "🌍 Testing access to each node:"

echo ""
echo "Control Plane (108.142.156.228:30000):"
curl -s -m 5 http://108.142.156.228:30000 | head -1 || echo "❌ Not accessible"

echo ""
echo "West Europe Worker (128.251.152.53:30000):"
curl -s -m 5 http://128.251.152.53:30000 | head -1 || echo "❌ Not accessible"

echo ""
echo "Sweden Worker (4.223.108.114:30000):"
curl -s -m 5 http://4.223.108.114:30000 | head -1 || echo "❌ Not accessible"

echo ""
echo "🏥 Health check from inside cluster:"
kubectl exec -n simpleeshop deployment/simpleeshop -- curl -s http://localhost:3000 | head -1 || echo "❌ Internal connectivity issue"