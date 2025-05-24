#!/bin/bash

# 🚀 AZURE MICROK8S DEPLOYMENT SCRIPT
# Deploy production-ready microservices to MicroK8s on Azure VM

set -e  # Exit on any error

echo "🚀 AZURE MICROK8S DEPLOYMENT"
echo "==========================="
echo "Deploying production-ready microservices to MicroK8s..."
echo ""

# Set up kubectl alias for MicroK8s
echo "🔧 Setting up kubectl alias..."
alias kubectl='microk8s kubectl'

# Check MicroK8s status
echo "🔍 Checking MicroK8s status..."
microk8s status

echo ""
echo "🔍 Checking cluster connectivity..."
microk8s kubectl cluster-info

echo ""
echo "📋 Current namespace status:"
microk8s kubectl get namespaces

echo ""
echo "🏗️  STEP 1: Creating persistent storage..."
echo "=========================================="

# Apply persistent volumes
microk8s kubectl apply -f k8s/persistent-volumes.yaml

echo "✅ Persistent volumes created"
echo ""

echo "🔐 STEP 2: Creating Kubernetes secrets..."
echo "=========================================="

# Delete existing secrets if they exist
microk8s kubectl delete secret mysql-secret 2>/dev/null || echo "mysql-secret not found (ok)"
microk8s kubectl delete secret mongodb-secret 2>/dev/null || echo "mongodb-secret not found (ok)"

# Apply secrets
microk8s kubectl apply -f k8s/secrets.yaml

echo "✅ Secrets created"
echo ""

echo "💾 STEP 3: Deploying production databases..."
echo "============================================"

# Deploy production-ready databases
microk8s kubectl apply -f k8s/mysql-production.yaml
microk8s kubectl apply -f k8s/mongodb-production.yaml

echo "✅ Database deployments created"
echo ""

echo "⏰ STEP 4: Setting up automated backups..."
echo "=========================================="

# Apply backup CronJobs
microk8s kubectl apply -f k8s/backup-cronjobs.yaml

echo "✅ Backup strategy configured"
echo ""

echo "🔍 STEP 5: Waiting for databases to be ready..."
echo "==============================================="

echo "Waiting for MySQL deployment..."
microk8s kubectl wait --for=condition=available --timeout=300s deployment/mysql

echo "Waiting for MongoDB deployment..."
microk8s kubectl wait --for=condition=available --timeout=300s deployment/mongodb

echo ""
echo "🚀 STEP 6: Deploying microservices..."
echo "====================================="

# Deploy the microservices
microk8s kubectl apply -f k8s/product-service.yaml
microk8s kubectl apply -f k8s/inventory-service.yaml
microk8s kubectl apply -f k8s/order-service.yaml

echo "✅ Microservices deployed"
echo ""

echo "⏳ Waiting for microservices to be ready..."
microk8s kubectl wait --for=condition=available --timeout=300s deployment/product-service
microk8s kubectl wait --for=condition=available --timeout=300s deployment/inventory-service
microk8s kubectl wait --for=condition=available --timeout=300s deployment/order-service

echo ""
echo "🌐 STEP 7: Setting up external access..."
echo "========================================"

# Apply load balancer for external access
microk8s kubectl apply -f k8s/product-service-loadbalancer.yaml

echo "✅ Load balancer configured"
echo ""

echo "🎯 STEP 8: Final verification..."
echo "================================"

echo "📊 All Deployments:"
microk8s kubectl get deployments

echo ""
echo "🌐 Services:"
microk8s kubectl get services

echo ""
echo "📋 Pods Status:"
microk8s kubectl get pods

echo ""
echo "💾 Storage:"
microk8s kubectl get pvc

echo ""
echo "⏰ Backup Jobs:"
microk8s kubectl get cronjobs

echo ""
echo "🎉 DEPLOYMENT COMPLETED!"
echo "========================"
echo ""
echo "✅ WHAT'S RUNNING:"
echo "  🗄️  Production databases with persistent storage"
echo "  🚀 3 business microservices"
echo "  🔐 Secure password management"
echo "  💾 Automated backup strategy"
echo "  📊 Prometheus metrics (via observability addon)"
echo "  📈 Grafana dashboards (via observability addon)"
echo ""
echo "🌐 ACCESS YOUR SERVICES:"
echo "========================"

# Get service URLs
echo "Getting service access information..."
microk8s kubectl get services -o wide

echo ""
echo "📊 MONITORING ACCESS:"
echo "===================="
echo "Grafana: http://$(curl -s ifconfig.me):3000"
echo "Prometheus: http://$(curl -s ifconfig.me):9090"
echo ""
echo "📝 Default Grafana credentials: admin/admin"
echo ""

echo "🔍 USEFUL COMMANDS:"
echo "==================="
echo "# Check pod status:"
echo "microk8s kubectl get pods"
echo ""
echo "# View logs:"
echo "microk8s kubectl logs -f deployment/product-service"
echo ""
echo "# Scale services:"
echo "microk8s kubectl scale deployment product-service --replicas=3"
echo ""
echo "# Access Grafana dashboard:"
echo "microk8s kubectl port-forward -n observability service/grafana 3000:3000"
echo ""

echo "🎯 DEPLOYMENT SUCCESS! Your production-ready microservices are now running!" 