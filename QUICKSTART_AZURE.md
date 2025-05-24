# ⚡ Azure Quickstart - Production Microservices

**Deploy production-ready microservices to Azure in 30 minutes!**

## 🎯 Two-Command Setup

### **Option 1: Fresh Azure VM (Recommended for Learning)**

```bash
# 1. Create Azure VM
az vm create \
  --resource-group microservices-rg \
  --name microservices-vm \
  --image Ubuntu2204 \
  --size Standard_D4s_v3 \
  --admin-username azureuser \
  --generate-ssh-keys

# Open ports
az vm open-port --resource-group microservices-rg --name microservices-vm --port 22,80,443,8080-8082,3000,9090

# 2. SSH into VM and run setup
VM_IP=$(az vm show -d --resource-group microservices-rg --name microservices-vm --query publicIps -o tsv)
ssh azureuser@$VM_IP

# On the VM:
git clone https://github.com/your-username/SpringBoot-Microservices-Order-Management-System.git
cd SpringBoot-Microservices-Order-Management-System
chmod +x setup-vm.sh && ./setup-vm.sh
```

### **Option 2: Azure Kubernetes Service (Recommended for Production)**

```bash
# 1. Create AKS cluster
az aks create \
  --resource-group microservices-prod-rg \
  --name microservices-aks \
  --node-count 2 \
  --enable-autoscaler \
  --min-count 1 \
  --max-count 5

# 2. Deploy microservices
az aks get-credentials --resource-group microservices-prod-rg --name microservices-aks

git clone https://github.com/your-username/SpringBoot-Microservices-Order-Management-System.git
cd SpringBoot-Microservices-Order-Management-System

kubectl apply -f k8s/persistent-volumes.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/mysql-production.yaml
kubectl apply -f k8s/mongodb-production.yaml
kubectl apply -f k8s/backup-cronjobs.yaml
kubectl apply -f k8s/product-service.yaml
kubectl apply -f k8s/inventory-service.yaml
kubectl apply -f k8s/order-service.yaml
kubectl apply -f k8s/product-service-loadbalancer.yaml
```

## 🔍 Verify Your Deployment

```bash
# Check all services
kubectl get pods,pvc,secrets,cronjobs,svc

# Test health endpoints
EXTERNAL_IP=$(kubectl get service product-service-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "localhost")
curl http://$EXTERNAL_IP:8080/actuator/health
curl http://$EXTERNAL_IP:8081/actuator/health
curl http://$EXTERNAL_IP:8082/actuator/health
```

## ✅ What You Get

✅ **3 production-ready microservices** (Product, Inventory, Order)  
✅ **Persistent storage** (no data loss on restart)  
✅ **Encrypted secrets** (secure password storage)  
✅ **Automated backups** (daily MySQL & MongoDB backups)  
✅ **Auto-scaling** (HPA configured)  
✅ **Load balancer** (external access)  
✅ **Monitoring** (Prometheus + Grafana)

## 📊 Access Your Services

### VM Deployment:
- **Services**: `http://<VM-IP>:8080`, `http://<VM-IP>:8081`, `http://<VM-IP>:8082`
- **Grafana**: `http://<VM-IP>:3000` (admin/prom-operator)
- **Prometheus**: `http://<VM-IP>:9090`

### AKS Deployment:
- **Services**: `http://<EXTERNAL-IP>:8080`, `http://<EXTERNAL-IP>:8081`, `http://<EXTERNAL-IP>:8082`
- **Monitoring**: Port-forward or ingress setup required

## 💰 Cost Comparison

| Option | Monthly Cost | Features |
|--------|--------------|----------|
| **VM Setup** | ~$150 | Manual management, full control |
| **AKS Setup** | ~$140 | Managed, auto-scaling, enterprise |

## 🚀 Next Steps

1. **Test your APIs**: Create products, check inventory, place orders
2. **Monitor performance**: Import Grafana dashboards (7362, 4701)
3. **Scale testing**: Use `hey` or `ab` for load testing
4. **Customize**: Modify services, add features, deploy updates

## 📚 Detailed Guides

- **[FRESH_VM_SETUP.md](FRESH_VM_SETUP.md)** - Step-by-step VM setup
- **[AZURE_AKS_DEPLOYMENT.md](AZURE_AKS_DEPLOYMENT.md)** - Complete AKS guide
- **[PRODUCTION_DEPLOYMENT_GUIDE.md](PRODUCTION_DEPLOYMENT_GUIDE.md)** - Production features
- **[AZURE_LOAD_BALANCER.md](AZURE_LOAD_BALANCER.md)** - Load balancer options

**Your production-ready microservices await! 🎉** 