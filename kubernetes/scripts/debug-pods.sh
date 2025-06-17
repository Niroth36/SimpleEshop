#!/bin/bash
# kubernetes/scripts/debug-pods.sh

echo "🔍 Debugging SimpleEshop Pods"
echo "============================="

echo "📊 Pod Status:"
kubectl get pods -n simpleeshop -o wide

echo ""
echo "📋 Pod Details:"
for pod in $(kubectl get pods -n simpleeshop -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
    echo ""
    echo "━━━ Pod: $pod ━━━"
    echo "📄 Description:"
    kubectl describe pod $pod -n simpleeshop | tail -20
    
    echo ""
    echo "📜 Logs:"
    kubectl logs $pod -n simpleeshop --tail=20 || echo "No logs available"
    echo ""
done

echo ""
echo "🔗 Services:"
kubectl get svc -n simpleeshop

echo ""
echo "🗂️  ConfigMaps:"
kubectl get configmap -n simpleeshop

echo ""
echo "💾 PersistentVolumes:"
kubectl get pv,pvc -n simpleeshop

echo ""
echo "🌐 Nodes and Resources:"
kubectl top nodes || echo "Metrics not available"