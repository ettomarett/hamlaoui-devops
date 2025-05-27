#!/bin/bash

# 🔍 DEBUG MYSQL DEPLOYMENT SCRIPT
# Helps identify why MySQL deployment is stuck

echo "🔍 MYSQL DEPLOYMENT DEBUGGING"
echo "============================="
echo ""

echo "📋 1. POD STATUS:"
echo "=================="
microk8s kubectl get pods -o wide | grep -E "(NAME|mysql)"

echo ""
echo "🔧 2. DEPLOYMENT STATUS:"
echo "========================"
microk8s kubectl get deployment mysql -o wide 2>/dev/null || echo "❌ MySQL deployment not found"

echo ""
echo "💾 3. PERSISTENT VOLUME CLAIMS:"
echo "==============================="
microk8s kubectl get pvc | grep -E "(NAME|mysql)"

echo ""
echo "🔐 4. SECRETS:"
echo "=============="
microk8s kubectl get secrets | grep -E "(NAME|mysql)"

echo ""
echo "📊 5. STORAGE CLASS:"
echo "===================="
microk8s kubectl get storageclass

echo ""
echo "⚡ 6. RECENT EVENTS:"
echo "==================="
microk8s kubectl get events --sort-by='.lastTimestamp' | tail -10

echo ""
echo "📝 7. MYSQL POD LOGS (if exists):"
echo "=================================="
MYSQL_POD=$(microk8s kubectl get pods -l app=mysql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ ! -z "$MYSQL_POD" ]; then
    echo "Pod: $MYSQL_POD"
    echo "Logs:"
    microk8s kubectl logs $MYSQL_POD --tail=20 2>/dev/null || echo "❌ Cannot get logs"
    echo ""
    echo "Pod Description:"
    microk8s kubectl describe pod $MYSQL_POD | tail -20
else
    echo "❌ No MySQL pod found"
fi

echo ""
echo "🧠 8. NODE RESOURCES:"
echo "===================="
microk8s kubectl describe nodes | grep -A 5 "Allocated resources"

echo ""
echo "🎯 9. TROUBLESHOOTING SUGGESTIONS:"
echo "=================================="

# Check if PVC is stuck
PVC_STATUS=$(microk8s kubectl get pvc mysql-pvc -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PVC_STATUS" = "Pending" ]; then
    echo "🚨 ISSUE: PVC is stuck in Pending state"
    echo "💡 FIX: Enable storage addon:"
    echo "   microk8s enable storage"
    echo "   microk8s kubectl patch storageclass microk8s-hostpath -p '{\"metadata\": {\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"true\"}}}'"
elif [ "$PVC_STATUS" = "Bound" ]; then
    echo "✅ PVC is working fine"
else
    echo "❓ PVC status: $PVC_STATUS"
fi

# Check if pod exists but is failing
POD_STATUS=$(microk8s kubectl get pods -l app=mysql -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
if [ "$POD_STATUS" = "Pending" ]; then
    echo "🚨 ISSUE: Pod is stuck in Pending state"
    echo "💡 FIX: Check resource constraints or image pull issues"
elif [ "$POD_STATUS" = "Running" ]; then
    echo "✅ Pod is running"
elif [ "$POD_STATUS" = "CrashLoopBackOff" ] || [ "$POD_STATUS" = "Error" ]; then
    echo "🚨 ISSUE: Pod is crashing"
    echo "💡 FIX: Check logs and configuration"
else
    echo "❓ Pod status: $POD_STATUS"
fi

echo ""
echo "🔄 QUICK FIXES TO TRY:"
echo "======================"
echo "1. Restart deployment:"
echo "   microk8s kubectl rollout restart deployment/mysql"
echo ""
echo "2. Delete and recreate:"
echo "   microk8s kubectl delete deployment mysql"
echo "   microk8s kubectl apply -f k8s/mysql-production.yaml"
echo ""
echo "3. Use basic MySQL (if production fails):"
echo "   microk8s kubectl apply -f k8s/mysql.yaml"
echo ""
echo "4. Check available storage:"
echo "   df -h"
echo ""
echo "5. Restart MicroK8s:"
echo "   microk8s stop && microk8s start" 