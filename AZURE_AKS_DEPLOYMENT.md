# ☁️ Azure Kubernetes Service (AKS) Deployment - Production Ready

## 🎯 Why AKS for Production?

**Azure Kubernetes Service (AKS)** is the managed Kubernetes solution that's perfect for your production microservices:

✅ **Managed control plane** (Azure handles Kubernetes master)  
✅ **Built-in Azure integrations** (Load Balancer, Storage, Monitor)  
✅ **Auto-scaling and auto-upgrades**  
✅ **Enterprise security and compliance**  
✅ **Cost-effective** (~$100-200/month vs $150+ for VM)

## 🚀 Quick AKS Production Deployment (30 minutes)

### Prerequisites
- Azure CLI installed and logged in
- kubectl installed
- Your production-ready microservices (already done! ✅)

### Step 1: Create AKS Cluster (10 minutes)

```bash
# Set variables
RESOURCE_GROUP="microservices-prod-rg"
CLUSTER_NAME="microservices-aks"
LOCATION="eastus"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create AKS cluster with auto-scaling
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --node-count 2 \
  --min-count 1 \
  --max-count 5 \
  --enable-autoscaler \
  --node-vm-size Standard_D2s_v3 \
  --enable-addons monitoring \
  --generate-ssh-keys \
  --attach-acr microservicesacr

# Get credentials
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
```

### Step 2: Configure Azure Storage Classes (5 minutes)

```bash
# Create storage classes for optimal performance
kubectl apply -f - << EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-premium-retain
provisioner: disk.csi.azure.com
parameters:
  storageaccounttype: Premium_LRS
  kind: Managed
reclaimPolicy: Retain
allowVolumeExpansion: true
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-standard-retain
provisioner: disk.csi.azure.com
parameters:
  storageaccounttype: Standard_LRS
  kind: Managed
reclaimPolicy: Retain
allowVolumeExpansion: true
EOF
```

### Step 3: Deploy Production-Ready Microservices (10 minutes)

```bash
# Update storage classes in persistent volumes for Azure
sed -i 's/# storageClassName: fast-ssd/storageClassName: managed-premium-retain/g' k8s/persistent-volumes.yaml
sed -i 's/# storageClassName: standard/storageClassName: managed-standard-retain/g' k8s/persistent-volumes.yaml

# Deploy with production fixes
kubectl apply -f k8s/persistent-volumes.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/mysql-production.yaml
kubectl apply -f k8s/mongodb-production.yaml
kubectl apply -f k8s/backup-cronjobs.yaml

# Deploy microservices
kubectl apply -f k8s/product-service.yaml
kubectl apply -f k8s/inventory-service.yaml
kubectl apply -f k8s/order-service.yaml

# Wait for everything to be ready
kubectl wait --for=condition=available --timeout=300s deployment --all
```

### Step 4: Set Up Load Balancer (5 minutes)

```bash
# Deploy Azure Load Balancer services (gets public IPs automatically!)
kubectl apply -f k8s/product-service-loadbalancer.yaml

# Or create ingress for path-based routing
kubectl apply -f - << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: microservices-ingress
  annotations:
    kubernetes.io/ingress.class: addon-http-application-routing
    nginx.ingress.kubernetes.io/rewrite-target: /\$2
spec:
  rules:
  - http:
      paths:
      - path: /api/products(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: product-service
            port:
              number: 8080
      - path: /api/inventory(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: inventory-service
            port:
              number: 8081
      - path: /api/orders(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: order-service
            port:
              number: 8082
EOF
```

## 🔍 Verification & Testing

```bash
# Check everything is running
kubectl get pods,pvc,secrets,cronjobs,svc

# Get external IPs
kubectl get services --selector="type in (LoadBalancer)"

# Test your APIs
EXTERNAL_IP=$(kubectl get service product-service-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$EXTERNAL_IP:8080/actuator/health

# Access monitoring
kubectl port-forward -n kube-system service/addon-http-application-routing-nginx-ingress 8080:80
# Then visit http://localhost:8080 for ingress
```

## 💰 Cost Comparison

| Solution | Monthly Cost | Features |
|----------|--------------|----------|
| **VM + MicroK8s** | ~$150 | Manual management, single VM |
| **AKS (2 nodes)** | ~$140 | Managed, auto-scaling, HA |
| **AKS + Premium Storage** | ~$180 | Enterprise performance |

## 🎯 Production Benefits with AKS

### 1. **Automatic Azure Integrations**
```bash
# Storage automatically provisioned
# Load balancers automatically created
# Monitoring automatically configured
# Backup integration with Azure Backup
```

### 2. **Enterprise Security**
```bash
# Azure Active Directory integration
# Pod security policies
# Network security groups
# Azure Key Vault integration for secrets
```

### 3. **Operational Excellence**
```bash
# Automatic Kubernetes upgrades
# Node auto-scaling based on demand
# Azure Monitor integration
# Log Analytics workspace
```

## 🔧 AKS-Specific Optimizations

### 1. Enable Azure Monitor for Containers
```bash
az aks enable-addons \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --addons monitoring
```

### 2. Configure Pod Identity for Azure Services
```bash
# Enable pod identity
az aks update \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --enable-pod-identity
```

### 3. Set up Azure Key Vault for Secrets
```bash
# Create Key Vault
az keyvault create \
  --name microservices-kv \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION

# Store secrets
az keyvault secret set --vault-name microservices-kv --name mysql-root-password --value "$(openssl rand -base64 32)"
az keyvault secret set --vault-name microservices-kv --name mongodb-root-password --value "$(openssl rand -base64 32)"
```

## 🚀 Quick Start Commands

```bash
# 1. Create AKS cluster
az aks create --resource-group microservices-prod-rg --name microservices-aks --node-count 2 --enable-autoscaler --min-count 1 --max-count 5

# 2. Get credentials
az aks get-credentials --resource-group microservices-prod-rg --name microservices-aks

# 3. Deploy production microservices
kubectl apply -f k8s/persistent-volumes.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/mysql-production.yaml
kubectl apply -f k8s/mongodb-production.yaml
kubectl apply -f k8s/backup-cronjobs.yaml
kubectl apply -f k8s/product-service.yaml
kubectl apply -f k8s/inventory-service.yaml
kubectl apply -f k8s/order-service.yaml

# 4. Set up load balancer
kubectl apply -f k8s/product-service-loadbalancer.yaml

# 5. Get external access
kubectl get services
```

## 🎉 Success! Your Production Microservices on AKS

After deployment, you'll have:

✅ **Managed Kubernetes** (Azure handles the complexity)  
✅ **Auto-scaling** (scales with demand)  
✅ **High Availability** (multi-node cluster)  
✅ **External Load Balancers** (automatic Azure LB)  
✅ **Persistent Storage** (Azure Disks)  
✅ **Automated Backups** (running daily)  
✅ **Enterprise Monitoring** (Azure Monitor)  
✅ **Production Security** (secrets, non-root containers)

**Your microservices are now running on enterprise-grade Azure infrastructure!** 🎯 