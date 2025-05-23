# ☁️ Azure Deployment Guide - 3-Hour Microservices Setup

Deploy the complete microservices system on **Azure Virtual Machines** with Kubernetes in under 3 hours!

## 🎯 Azure Architecture Overview

```
Azure Resource Group
├── Virtual Machine (Ubuntu 22.04 LTS)
│   ├── MicroK8s Cluster
│   ├── 3 Microservices (Product, Inventory, Order)
│   ├── Databases (MongoDB, MySQL)
│   └── Monitoring (Prometheus, Grafana)
├── Network Security Group
├── Public IP Address
└── Virtual Network
```

## 📋 Prerequisites

- **Azure Account** with active subscription
- **Azure CLI** installed locally
- **SSH key pair** for VM access
- **Basic Linux/Kubernetes knowledge**

## 🚀 180-Minute Azure Execution Plan

### 00:00 – 00:20: Azure Infrastructure Setup

#### 1. Install Azure CLI (if not already installed)
```bash
# macOS
brew install azure-cli

# Windows (PowerShell)
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -ArgumentList '/I AzureCLI.msi /quiet'

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

#### 2. Login and Set Subscription
```bash
# Login to Azure
az login

# List subscriptions
az account list --output table

# Set your subscription
az account set --subscription "Your-Subscription-Name"
```

#### 3. Create Resource Group
```bash
# Create resource group in your preferred region
az group create \
  --name microservices-rg \
  --location eastus
```

#### 4. Create Virtual Network
```bash
# Create virtual network
az network vnet create \
  --resource-group microservices-rg \
  --name microservices-vnet \
  --address-prefix 10.1.0.0/16 \
  --subnet-name microservices-subnet \
  --subnet-prefix 10.1.1.0/24
```

#### 5. Create Network Security Group
```bash
# Create NSG
az network nsg create \
  --resource-group microservices-rg \
  --name microservices-nsg

# Allow SSH
az network nsg rule create \
  --resource-group microservices-rg \
  --nsg-name microservices-nsg \
  --name AllowSSH \
  --protocol tcp \
  --priority 1001 \
  --destination-port-range 22

# Allow HTTP/HTTPS
az network nsg rule create \
  --resource-group microservices-rg \
  --nsg-name microservices-nsg \
  --name AllowHTTP \
  --protocol tcp \
  --priority 1002 \
  --destination-port-range 80

az network nsg rule create \
  --resource-group microservices-rg \
  --nsg-name microservices-nsg \
  --name AllowHTTPS \
  --protocol tcp \
  --priority 1003 \
  --destination-port-range 443

# Allow Kubernetes API
az network nsg rule create \
  --resource-group microservices-rg \
  --nsg-name microservices-nsg \
  --name AllowK8sAPI \
  --protocol tcp \
  --priority 1004 \
  --destination-port-range 16443

# Allow application ports
az network nsg rule create \
  --resource-group microservices-rg \
  --nsg-name microservices-nsg \
  --name AllowApps \
  --protocol tcp \
  --priority 1005 \
  --destination-port-range 8080-8082

# Allow monitoring ports
az network nsg rule create \
  --resource-group microservices-rg \
  --nsg-name microservices-nsg \
  --name AllowMonitoring \
  --protocol tcp \
  --priority 1006 \
  --destination-port-range 3000,9090
```

### 00:20 – 00:35: Create and Configure VM

#### 1. Create Virtual Machine
```bash
# Create public IP
az network public-ip create \
  --resource-group microservices-rg \
  --name microservices-ip \
  --allocation-method Static \
  --sku Standard

# Create VM (Standard_D4s_v3 = 4 vCPUs, 16GB RAM)
az vm create \
  --resource-group microservices-rg \
  --name microservices-vm \
  --image Ubuntu2204 \
  --size Standard_D4s_v3 \
  --vnet-name microservices-vnet \
  --subnet microservices-subnet \
  --nsg microservices-nsg \
  --public-ip-address microservices-ip \
  --ssh-key-values ~/.ssh/id_rsa.pub \
  --admin-username azureuser
```

#### 2. Get VM Public IP
```bash
# Get the public IP address
VM_IP=$(az vm show -d \
  --resource-group microservices-rg \
  --name microservices-vm \
  --query publicIps -o tsv)

echo "VM Public IP: $VM_IP"
```

#### 3. SSH into VM and Update System
```bash
# SSH into the VM
ssh azureuser@$VM_IP

# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y curl wget git htop
```

### 00:35 – 00:50: Install and Configure MicroK8s

#### 1. Install MicroK8s
```bash
# Install microk8s
sudo snap install microk8s --classic --channel=1.29/stable

# Add user to microk8s group
sudo usermod -a -G microk8s $USER
sudo chown -R $USER ~/.kube

# Re-enter the group (or logout/login)
newgrp microk8s
```

#### 2. Enable Required Add-ons
```bash
# Enable DNS, registry, ingress, and Prometheus
microk8s enable dns registry ingress prometheus

# Wait for all services to be ready
microk8s status --wait-ready

# Check cluster status
microk8s kubectl get nodes
microk8s kubectl get pods --all-namespaces
```

#### 3. Configure kubectl
```bash
# Create .kube directory and config
mkdir -p ~/.kube
microk8s config > ~/.kube/config

# Set alias for easier kubectl usage
echo "alias kubectl='microk8s kubectl'" >> ~/.bashrc
source ~/.bashrc

# Test kubectl
kubectl get nodes
```

### 00:50 – 01:10: Deploy Application

#### 1. Clone Repository
```bash
# Clone the microservices repository
git clone https://github.com/your-username/SpringBoot-Microservices-Order-Management-System.git
cd SpringBoot-Microservices-Order-Management-System
```

#### 2. Update Image References for Azure Container Registry (Optional)
```bash
# If using Azure Container Registry instead of GitHub Container Registry
# Create ACR (optional)
az acr create \
  --resource-group microservices-rg \
  --name microservicesacr$(date +%s) \
  --sku Basic

# Get ACR login server
ACR_NAME=$(az acr list --resource-group microservices-rg --query '[0].name' -o tsv)
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer -o tsv)

# Update manifests to use ACR (if desired)
sed -i "s|ghcr.io/hamlaoui|${ACR_LOGIN_SERVER}|g" k8s/*.yaml
```

#### 3. Deploy Infrastructure
```bash
# Deploy databases first
kubectl apply -f k8s/mongodb.yaml
kubectl apply -f k8s/mysql.yaml

# Wait for databases to be ready
kubectl wait --for=condition=ready pod -l app=mongodb --timeout=300s
kubectl wait --for=condition=ready pod -l app=mysql --timeout=300s

# Deploy microservices
kubectl apply -f k8s/product-service.yaml
kubectl apply -f k8s/inventory-service.yaml
kubectl apply -f k8s/order-service.yaml

# Check deployment status
kubectl get pods,svc
```

### 01:10 – 01:30: Configure Access and Testing

#### 1. Port Forward Services (for testing)
```bash
# Port forward microservices (run in separate terminals or use screen/tmux)
kubectl port-forward svc/product-service 8080:8080 --address='0.0.0.0' &
kubectl port-forward svc/inventory-service 8081:8081 --address='0.0.0.0' &
kubectl port-forward svc/order-service 8082:8082 --address='0.0.0.0' &

# Port forward monitoring
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 --address='0.0.0.0' &
kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090 --address='0.0.0.0' &
```

#### 2. Test Services from Local Machine
```bash
# Test health endpoints (replace $VM_IP with your actual IP)
curl http://$VM_IP:8080/actuator/health
curl http://$VM_IP:8081/actuator/health
curl http://$VM_IP:8082/actuator/health

# Access Grafana dashboard
open http://$VM_IP:3000  # Username: admin, Password: prom-operator

# Access Prometheus
open http://$VM_IP:9090
```

### 01:30 – 02:00: Configure Ingress (Production Access)

#### 1. Create Ingress for External Access
```bash
# Create ingress configuration
cat << EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: microservices-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /\$2
spec:
  rules:
  - host: $VM_IP.nip.io
    http:
      paths:
      - path: /product(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: product-service
            port:
              number: 8080
      - path: /inventory(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: inventory-service
            port:
              number: 8081
      - path: /order(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: order-service
            port:
              number: 8082
EOF
```

#### 2. Test Ingress Access
```bash
# Test through ingress (using nip.io for DNS)
curl http://$VM_IP.nip.io/product/actuator/health
curl http://$VM_IP.nip.io/inventory/actuator/health
curl http://$VM_IP.nip.io/order/actuator/health
```

### 02:00 – 02:30: CI/CD with Azure DevOps (Alternative)

#### 1. Azure DevOps Setup (Optional Alternative to GitHub Actions)
```bash
# Install Azure DevOps CLI extension
az extension add --name azure-devops

# Create Azure DevOps project
az devops project create --name microservices-project

# Create service connection for ACR
az devops service-endpoint azurerm create \
  --azure-rm-service-principal-id <service-principal-id> \
  --azure-rm-subscription-id <subscription-id> \
  --azure-rm-tenant-id <tenant-id> \
  --name acr-connection
```

#### 2. Create Azure Pipelines YAML
Create `azure-pipelines.yml`:
```yaml
trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

variables:
  containerRegistry: 'microservicesacr.azurecr.io'
  imageRepository: 'microservices'
  dockerfilePath: '**/Dockerfile'
  tag: '$(Build.BuildId)'

stages:
- stage: Build
  displayName: Build and push stage
  jobs:
  - job: Build
    displayName: Build
    steps:
    - task: Maven@3
      displayName: 'Maven Package'
      inputs:
        mavenPomFile: 'pom.xml'
        goals: 'clean package -DskipTests'
        options: '-pl product-service,inventory-service,order-service'
    
    - task: Docker@2
      displayName: Build and push Product Service
      inputs:
        command: buildAndPush
        repository: $(imageRepository)/product-service
        dockerfile: product-service/Dockerfile
        containerRegistry: acr-connection
        tags: |
          $(tag)
          latest

- stage: Deploy
  displayName: Deploy stage
  dependsOn: Build
  jobs:
  - deployment: Deploy
    displayName: Deploy
    environment: 'production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: KubernetesManifest@0
            displayName: Deploy to Kubernetes cluster
            inputs:
              action: deploy
              manifests: |
                k8s/product-service.yaml
                k8s/inventory-service.yaml
                k8s/order-service.yaml
```

### 02:30 – 02:45: Load Testing and Monitoring

#### 1. Install Load Testing Tools
```bash
# Install hey for load testing
wget https://github.com/rakyll/hey/releases/download/v0.1.4/hey_linux_amd64
chmod +x hey_linux_amd64
sudo mv hey_linux_amd64 /usr/local/bin/hey

# Generate load
hey -z 2m -c 20 http://$VM_IP:8080/actuator/health

# Watch auto-scaling
kubectl get hpa -w
```

#### 2. Configure Grafana Dashboards
```bash
# Access Grafana and import dashboards:
# Dashboard 7362 - Kubernetes Pods
# Dashboard 4701 - Spring Boot JVM

# Or use Grafana API to import automatically
curl -X POST \
  http://admin:prom-operator@$VM_IP:3000/api/dashboards/import \
  -H 'Content-Type: application/json' \
  -d '{"dashboard": {"id": 7362}}'
```

### 02:45 – 03:00: Backup and Documentation

#### 1. Create VM Snapshot
```bash
# Stop the VM (optional, for consistent snapshot)
az vm deallocate --resource-group microservices-rg --name microservices-vm

# Create disk snapshot
az snapshot create \
  --resource-group microservices-rg \
  --name microservices-vm-snapshot \
  --source-disk microservices-vm_OsDisk_1_<disk-id>

# Start VM again
az vm start --resource-group microservices-rg --name microservices-vm
```

#### 2. Document Access Information
```bash
# Create access documentation
cat << EOF > AZURE_ACCESS_INFO.md
# Azure Microservices Access Information

## VM Details
- **Resource Group**: microservices-rg
- **VM Name**: microservices-vm
- **Public IP**: $VM_IP
- **SSH Access**: ssh azureuser@$VM_IP

## Application URLs
- **Product Service**: http://$VM_IP.nip.io/product/actuator/health
- **Inventory Service**: http://$VM_IP.nip.io/inventory/actuator/health
- **Order Service**: http://$VM_IP.nip.io/order/actuator/health

## Monitoring URLs
- **Grafana**: http://$VM_IP:3000 (admin/prom-operator)
- **Prometheus**: http://$VM_IP:9090

## Kubernetes Access
- SSH into VM: ssh azureuser@$VM_IP
- kubectl get pods
- kubectl get svc
- kubectl logs -f deployment/product-service

## Azure Resources
- Resource Group: microservices-rg
- Region: eastus
- VM Size: Standard_D4s_v3 (4 vCPU, 16GB RAM)
EOF
```

## 💰 Azure Cost Optimization

### Estimated Monthly Costs
- **Standard_D4s_v3 VM**: ~$140/month
- **Public IP**: ~$3/month
- **Storage**: ~$10/month
- **Total**: ~$153/month

### Cost Saving Tips
```bash
# Auto-shutdown VM during non-business hours
az vm auto-shutdown \
  --resource-group microservices-rg \
  --name microservices-vm \
  --time 1800 \
  --email your-email@domain.com

# Use Azure Spot VMs for development (up to 90% discount)
az vm create \
  --resource-group microservices-rg \
  --name microservices-spot-vm \
  --priority Spot \
  --max-price 0.05 \
  --eviction-policy Deallocate \
  # ... other parameters
```

## 🔧 Troubleshooting

### Common Azure Issues

#### 1. VM Creation Fails
```bash
# Check quotas
az vm list-usage --location eastus --output table

# Try different VM size
az vm list-sizes --location eastus --output table
```

#### 2. Network Connectivity Issues
```bash
# Check NSG rules
az network nsg rule list --resource-group microservices-rg --nsg-name microservices-nsg --output table

# Test connectivity
az network watcher test-connectivity \
  --resource-group microservices-rg \
  --source-resource microservices-vm \
  --dest-address google.com \
  --dest-port 80
```

#### 3. Kubernetes Issues
```bash
# Check microk8s status
microk8s status
microk8s inspect

# Reset microk8s if needed
microk8s reset
sudo snap remove microk8s
sudo snap install microk8s --classic
```

## 🎯 Success Criteria

✅ **Azure VM running Ubuntu 22.04**  
✅ **MicroK8s cluster operational**  
✅ **All 3 microservices deployed and healthy**  
✅ **Monitoring with Prometheus and Grafana**  
✅ **External access via Ingress**  
✅ **Auto-scaling configured and tested**  

## 🚀 Next Steps

1. **Set up custom domain** instead of nip.io
2. **Configure SSL/TLS certificates** with Let's Encrypt
3. **Implement Azure Monitor integration**
4. **Set up Azure Backup for persistent data**
5. **Create ARM templates** for infrastructure as code
6. **Configure Azure Key Vault** for secrets management

**Your Azure microservices setup is complete! 🎉** 