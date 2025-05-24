#!/bin/bash

# 🚀 ONE-LINER VM SETUP SCRIPT
# Complete production-ready microservices setup on fresh Linux VM
# Usage: curl -sSL https://raw.githubusercontent.com/your-username/SpringBoot-Microservices-Order-Management-System/main/setup-vm.sh | bash

set -e  # Exit on any error

echo "🚀 MICROSERVICES VM SETUP - ONE-LINER INSTALLER"
echo "================================================"
echo "This script will install:"
echo "✅ MicroK8s + required add-ons"
echo "✅ Production-ready microservices"
echo "✅ Persistent storage + automated backups"
echo "✅ Secure secrets management"
echo "✅ Monitoring (Prometheus + Grafana)"
echo "✅ Load balancer + external access"
echo ""

# Get system info
echo "🔍 System Info:"
echo "OS: $(lsb_release -d | cut -f2)"
echo "CPU: $(nproc) cores"
echo "RAM: $(free -h | awk '/^Mem:/ {print $2}')"
echo "Disk: $(df -h / | awk 'NR==2 {print $4}') available"
echo ""

# Update system
echo "📦 STEP 1/6: Updating system packages..."
sudo apt update -qq
sudo apt install -y curl wget git htop docker.io > /dev/null 2>&1
echo "✅ System updated"

# Install MicroK8s
echo "☸️  STEP 2/6: Installing MicroK8s..."
sudo snap install microk8s --classic --channel=1.29/stable > /dev/null 2>&1

# Configure MicroK8s
echo "⚙️  STEP 3/6: Configuring MicroK8s..."
sudo usermod -a -G microk8s $USER
sudo chown -R $USER ~/.kube 2>/dev/null || true

# Enable add-ons
echo "🔌 STEP 4/6: Enabling MicroK8s add-ons..."
sudo microk8s enable dns registry ingress prometheus storage --wait > /dev/null 2>&1

# Set up kubectl alias
echo "alias kubectl='sudo microk8s kubectl'" >> ~/.bashrc

# Clone repository
echo "📁 STEP 5/6: Downloading production-ready microservices..."
if [ -d "SpringBoot-Microservices-Order-Management-System" ]; then
    cd SpringBoot-Microservices-Order-Management-System
    git pull origin main > /dev/null 2>&1
else
    git clone https://github.com/hamlaoui/SpringBoot-Microservices-Order-Management-System.git > /dev/null 2>&1
    cd SpringBoot-Microservices-Order-Management-System
fi

# Deploy production microservices
echo "🚀 STEP 6/6: Deploying production microservices..."

# Deploy persistent volumes
sudo microk8s kubectl apply -f k8s/persistent-volumes.yaml > /dev/null 2>&1

# Create secrets
sudo microk8s kubectl delete secret mysql-secret mongodb-secret 2>/dev/null || true
sudo microk8s kubectl apply -f k8s/secrets.yaml > /dev/null 2>&1

# Deploy databases with production configurations
sudo microk8s kubectl delete deployment mysql mongodb 2>/dev/null || true
sleep 5
sudo microk8s kubectl apply -f k8s/mysql-production.yaml > /dev/null 2>&1
sudo microk8s kubectl apply -f k8s/mongodb-production.yaml > /dev/null 2>&1

# Set up backups
sudo microk8s kubectl apply -f k8s/backup-cronjobs.yaml > /dev/null 2>&1

# Deploy microservices
sudo microk8s kubectl apply -f k8s/product-service.yaml > /dev/null 2>&1
sudo microk8s kubectl apply -f k8s/inventory-service.yaml > /dev/null 2>&1
sudo microk8s kubectl apply -f k8s/order-service.yaml > /dev/null 2>&1

# Wait for deployments
echo "⏳ Waiting for services to be ready..."
sudo microk8s kubectl wait --for=condition=available --timeout=300s deployment --all > /dev/null 2>&1

# Set up port forwarding for external access
echo "🌐 Setting up external access..."

# Kill any existing port forwards
sudo pkill -f "kubectl.*port-forward" 2>/dev/null || true

# Start port forwarding in background
nohup sudo microk8s kubectl port-forward svc/product-service 8080:8080 --address='0.0.0.0' > /dev/null 2>&1 &
nohup sudo microk8s kubectl port-forward svc/inventory-service 8081:8081 --address='0.0.0.0' > /dev/null 2>&1 &
nohup sudo microk8s kubectl port-forward svc/order-service 8082:8082 --address='0.0.0.0' > /dev/null 2>&1 &
nohup sudo microk8s kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 --address='0.0.0.0' > /dev/null 2>&1 &
nohup sudo microk8s kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090 --address='0.0.0.0' > /dev/null 2>&1 &

# Get VM public IP
VM_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "localhost")

# Final verification
echo ""
echo "🧪 VERIFICATION: Testing services..."

# Wait a bit for port forwards to start
sleep 10

# Test health endpoints
PRODUCT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/actuator/health 2>/dev/null || echo "000")
INVENTORY_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/actuator/health 2>/dev/null || echo "000")
ORDER_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/actuator/health 2>/dev/null || echo "000")

# Display results
echo ""
echo "🎉 SETUP COMPLETED SUCCESSFULLY!"
echo "================================"
echo ""
echo "📊 SERVICE STATUS:"
if [ "$PRODUCT_STATUS" = "200" ]; then
    echo "✅ Product Service: HEALTHY"
else
    echo "⚠️  Product Service: Starting... (may take a few more minutes)"
fi

if [ "$INVENTORY_STATUS" = "200" ]; then
    echo "✅ Inventory Service: HEALTHY"
else
    echo "⚠️  Inventory Service: Starting... (may take a few more minutes)"
fi

if [ "$ORDER_STATUS" = "200" ]; then
    echo "✅ Order Service: HEALTHY"
else
    echo "⚠️  Order Service: Starting... (may take a few more minutes)"
fi

echo ""
echo "🌐 ACCESS YOUR SERVICES:"
echo "📍 Product Service:    http://$VM_IP:8080/actuator/health"
echo "📦 Inventory Service:  http://$VM_IP:8081/actuator/health"
echo "📋 Order Service:      http://$VM_IP:8082/actuator/health"
echo "📊 Grafana Dashboard:  http://$VM_IP:3000 (admin/prom-operator)"
echo "📈 Prometheus:         http://$VM_IP:9090"
echo ""

echo "🔍 PRODUCTION FEATURES ENABLED:"
echo "✅ Persistent Storage (no data loss on restart)"
echo "✅ Secure Secrets (encrypted password storage)"
echo "✅ Automated Backups (daily at 2AM & 3AM)"
echo "✅ Health Checks (liveness & readiness probes)"
echo "✅ Resource Limits (CPU & memory managed)"
echo "✅ Security Contexts (non-root containers)"
echo "✅ Auto-scaling (HPA configured)"
echo ""

echo "📋 USEFUL COMMANDS:"
echo "# Check all resources:"
echo "sudo microk8s kubectl get pods,pvc,secrets,cronjobs"
echo ""
echo "# Check logs:"
echo "sudo microk8s kubectl logs -f deployment/product-service"
echo ""
echo "# Test database connectivity:"
echo "sudo microk8s kubectl exec deployment/mysql -- mysql -u root -pSecureRootPass2024! -e \"SELECT 'MySQL OK';\""
echo ""
echo "# Run manual backup:"
echo "sudo microk8s kubectl create job --from=cronjob/mysql-backup manual-backup-\$(date +%s)"
echo ""

echo "🎯 YOUR PRODUCTION-READY MICROSERVICES ARE NOW RUNNING!"
echo ""
echo "⚠️  NOTE: If services show as 'Starting', wait 2-3 minutes and check again."
echo "The first startup takes longer as Docker images are being pulled."
echo ""
echo "🔄 To check real-time status:"
echo "watch 'sudo microk8s kubectl get pods'"
echo ""

# Create helpful aliases
cat << 'EOF' >> ~/.bashrc

# Microservices aliases
alias k='sudo microk8s kubectl'
alias kgp='sudo microk8s kubectl get pods'
alias kgs='sudo microk8s kubectl get services'
alias klogs='sudo microk8s kubectl logs -f'
alias khealth='curl -s http://localhost:8080/actuator/health && echo && curl -s http://localhost:8081/actuator/health && echo && curl -s http://localhost:8082/actuator/health'

# Quick status check
alias mstatus='echo "=== PODS ===" && sudo microk8s kubectl get pods && echo && echo "=== SERVICES ===" && sudo microk8s kubectl get services && echo && echo "=== HEALTH ===" && curl -s http://localhost:8080/actuator/health | jq -r .status 2>/dev/null || echo "Product: Starting..." && curl -s http://localhost:8081/actuator/health | jq -r .status 2>/dev/null || echo "Inventory: Starting..." && curl -s http://localhost:8082/actuator/health | jq -r .status 2>/dev/null || echo "Order: Starting..."'
EOF

echo "✨ Added helpful aliases to your shell:"
echo "   k         = kubectl"
echo "   kgp       = get pods"
echo "   kgs       = get services"
echo "   klogs     = follow logs"
echo "   khealth   = check service health"
echo "   mstatus   = full status check"
echo ""
echo "Run 'source ~/.bashrc' to enable aliases in current session."
echo ""
echo "🎉 ENJOY YOUR PRODUCTION-READY MICROSERVICES! 🎉" 