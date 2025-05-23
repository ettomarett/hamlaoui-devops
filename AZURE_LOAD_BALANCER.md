# ⚖️ Azure Load Balancer Integration Guide

## 🎯 Load Balancing Architecture Options

### Current Setup vs Production-Ready with Load Balancer

```
Current (Single VM):
Internet → VM Public IP → Ingress Controller → Services

Production with Load Balancer:
Internet → Azure Load Balancer → Multiple VMs → Ingress Controller → Services
```

## 🏗️ Azure Load Balancing Options

### 1. **Azure Load Balancer (Layer 4)**
- **Best for**: High performance, low latency
- **Protocol**: TCP/UDP
- **Use case**: Direct service access, database connections

### 2. **Azure Application Gateway (Layer 7)**
- **Best for**: Web applications, advanced routing
- **Features**: SSL termination, WAF, URL-based routing
- **Use case**: Public-facing microservices APIs

### 3. **Kubernetes LoadBalancer Service**
- **Best for**: Cloud-native integration
- **Auto-creates**: Azure Load Balancer for each service
- **Use case**: Exposing individual services

## 🚀 Implementation Options

### Option A: Azure Application Gateway (Recommended for Production)

#### 1. Create Application Gateway
```bash
# Create public IP for Application Gateway
az network public-ip create \
  --resource-group microservices-rg \
  --name appgw-ip \
  --allocation-method Static \
  --sku Standard

# Create Application Gateway subnet
az network vnet subnet create \
  --resource-group microservices-rg \
  --vnet-name microservices-vnet \
  --name appgw-subnet \
  --address-prefixes 10.1.2.0/24

# Create Application Gateway
az network application-gateway create \
  --resource-group microservices-rg \
  --name microservices-appgw \
  --location eastus \
  --capacity 2 \
  --sku Standard_v2 \
  --public-ip-address appgw-ip \
  --vnet-name microservices-vnet \
  --subnet appgw-subnet \
  --servers 10.1.1.4  # Your VM private IP
```

#### 2. Configure Backend Pools and Rules
```bash
# Get VM private IP
VM_PRIVATE_IP=$(az vm show -d \
  --resource-group microservices-rg \
  --name microservices-vm \
  --query privateIps -o tsv)

# Create backend pool for microservices
az network application-gateway address-pool create \
  --resource-group microservices-rg \
  --gateway-name microservices-appgw \
  --name microservices-pool \
  --servers $VM_PRIVATE_IP

# Create health probe for services
az network application-gateway probe create \
  --resource-group microservices-rg \
  --gateway-name microservices-appgw \
  --name health-probe \
  --protocol Http \
  --host-name-from-http-settings true \
  --path /actuator/health \
  --interval 30 \
  --threshold 3 \
  --timeout 30

# Create HTTP settings
az network application-gateway http-settings create \
  --resource-group microservices-rg \
  --gateway-name microservices-appgw \
  --name microservices-http-settings \
  --port 80 \
  --protocol Http \
  --cookie-based-affinity Disabled \
  --probe health-probe
```

#### 3. Configure URL-based Routing
```bash
# Create path-based rule for product service
az network application-gateway url-path-map create \
  --resource-group microservices-rg \
  --gateway-name microservices-appgw \
  --name path-map \
  --paths /product/* \
  --address-pool microservices-pool \
  --http-settings microservices-http-settings

# Add inventory service path
az network application-gateway url-path-map rule create \
  --resource-group microservices-rg \
  --gateway-name microservices-appgw \
  --path-map-name path-map \
  --name inventory-rule \
  --paths /inventory/* \
  --address-pool microservices-pool \
  --http-settings microservices-http-settings

# Add order service path
az network application-gateway url-path-map rule create \
  --resource-group microservices-rg \
  --gateway-name microservices-appgw \
  --path-map-name path-map \
  --name order-rule \
  --paths /order/* \
  --address-pool microservices-pool \
  --http-settings microservices-http-settings
```

### Option B: Multiple VMs with Azure Load Balancer

#### 1. Create VM Scale Set
```bash
# Create VM Scale Set for high availability
az vmss create \
  --resource-group microservices-rg \
  --name microservices-vmss \
  --image Ubuntu2204 \
  --upgrade-policy-mode automatic \
  --instance-count 3 \
  --admin-username azureuser \
  --ssh-key-values ~/.ssh/id_rsa.pub \
  --vnet-name microservices-vnet \
  --subnet microservices-subnet \
  --load-balancer microservices-lb \
  --backend-pool-name microservices-pool \
  --vm-sku Standard_D2s_v3
```

#### 2. Configure Load Balancer Rules
```bash
# Create probe for health checks
az network lb probe create \
  --resource-group microservices-rg \
  --lb-name microservices-lb \
  --name health-probe \
  --protocol tcp \
  --port 8080

# Create load balancing rules
az network lb rule create \
  --resource-group microservices-rg \
  --lb-name microservices-lb \
  --name product-service-rule \
  --protocol tcp \
  --frontend-port 8080 \
  --backend-port 8080 \
  --frontend-ip-name LoadBalancerFrontEnd \
  --backend-pool-name microservices-pool \
  --probe-name health-probe

az network lb rule create \
  --resource-group microservices-rg \
  --lb-name microservices-lb \
  --name inventory-service-rule \
  --protocol tcp \
  --frontend-port 8081 \
  --backend-port 8081 \
  --frontend-ip-name LoadBalancerFrontEnd \
  --backend-pool-name microservices-pool \
  --probe-name health-probe

az network lb rule create \
  --resource-group microservices-rg \
  --lb-name microservices-lb \
  --name order-service-rule \
  --protocol tcp \
  --frontend-port 8082 \
  --backend-port 8082 \
  --frontend-ip-name LoadBalancerFrontEnd \
  --backend-pool-name microservices-pool \
  --probe-name health-probe
```

### Option C: Kubernetes LoadBalancer Services

#### 1. Update Service Manifests
```yaml
# Update k8s/product-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: product-service
  labels:
    app: product-service
spec:
  type: LoadBalancer  # Changed from ClusterIP
  ports:
  - port: 8080
    targetPort: 8080
    protocol: TCP
  selector:
    app: product-service
  loadBalancerSourceRanges:
  - 0.0.0.0/0  # Restrict this in production
```

#### 2. Deploy LoadBalancer Services
```bash
# Apply updated manifests
kubectl apply -f k8s/product-service.yaml
kubectl apply -f k8s/inventory-service.yaml
kubectl apply -f k8s/order-service.yaml

# Check external IPs (may take a few minutes)
kubectl get services

# Example output:
# NAME                TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)
# product-service     LoadBalancer   10.152.183.123   20.62.xxx.xxx    8080:32001/TCP
# inventory-service   LoadBalancer   10.152.183.124   20.62.xxx.yyy    8081:32002/TCP
# order-service       LoadBalancer   10.152.183.125   20.62.xxx.zzz    8082:32003/TCP
```

## 🔧 Advanced Load Balancer Configuration

### SSL/TLS Termination at Load Balancer
```bash
# Create SSL certificate (using Let's Encrypt)
az network application-gateway ssl-cert create \
  --resource-group microservices-rg \
  --gateway-name microservices-appgw \
  --name ssl-cert \
  --cert-file ./certificate.pfx \
  --cert-password "your-password"

# Create HTTPS listener
az network application-gateway http-listener create \
  --resource-group microservices-rg \
  --gateway-name microservices-appgw \
  --name https-listener \
  --frontend-port 443 \
  --protocol Https \
  --ssl-cert ssl-cert
```

### Web Application Firewall (WAF)
```bash
# Enable WAF on Application Gateway
az network application-gateway waf-config set \
  --resource-group microservices-rg \
  --gateway-name microservices-appgw \
  --enabled true \
  --firewall-mode Prevention \
  --rule-set-type OWASP \
  --rule-set-version 3.2
```

### Auto-scaling Integration
```bash
# Create auto-scale profile for VMSS
az monitor autoscale create \
  --resource-group microservices-rg \
  --resource microservices-vmss \
  --resource-type Microsoft.Compute/virtualMachineScaleSets \
  --name microservices-autoscale \
  --min-count 2 \
  --max-count 10 \
  --count 3

# Add scale-out rule
az monitor autoscale rule create \
  --resource-group microservices-rg \
  --autoscale-name microservices-autoscale \
  --condition "Percentage CPU > 70 avg 5m" \
  --scale out 2
```

## 📊 Load Balancer Monitoring

### Health Check Configuration
```yaml
# Enhanced health check for Kubernetes
apiVersion: v1
kind: Service
metadata:
  name: product-service
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: "/actuator/health"
    service.beta.kubernetes.io/azure-load-balancer-health-probe-protocol: "http"
    service.beta.kubernetes.io/azure-load-balancer-health-probe-port: "8080"
    service.beta.kubernetes.io/azure-load-balancer-health-probe-interval: "5"
    service.beta.kubernetes.io/azure-load-balancer-health-probe-num-of-probe: "2"
spec:
  type: LoadBalancer
  # ... rest of service config
```

### Monitoring Metrics
```bash
# Monitor Application Gateway metrics
az monitor metrics list \
  --resource /subscriptions/{subscription-id}/resourceGroups/microservices-rg/providers/Microsoft.Network/applicationGateways/microservices-appgw \
  --metric ApplicationGatewayTotalTime,ApplicationGatewayResponseStatus \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z

# Monitor Load Balancer metrics
az monitor metrics list \
  --resource /subscriptions/{subscription-id}/resourceGroups/microservices-rg/providers/Microsoft.Network/loadBalancers/microservices-lb \
  --metric ByteCount,PacketCount,VipAvailability \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z
```

## 💰 Cost Comparison

| Load Balancer Type | Monthly Cost (approx.) | Features |
|-------------------|------------------------|----------|
| **Basic Load Balancer** | Free | Basic L4 load balancing |
| **Standard Load Balancer** | ~$18/month | Advanced L4, zone redundancy |
| **Application Gateway v2** | ~$35/month + data | L7 routing, WAF, SSL termination |
| **Application Gateway + WAF** | ~$50/month + data | Full security stack |

## 🎯 Recommended Architecture

### For Development/Testing
```
Internet → Single VM with Ingress Controller → Services
Cost: ~$140/month
```

### For Production (Recommended)
```
Internet → Application Gateway (with WAF) → VMSS (3 instances) → Services
Cost: ~$470/month (includes HA, security, auto-scaling)
```

### For High-Scale Production
```
Internet → Application Gateway → Multiple VMSS across zones → Services
Cost: ~$800/month+ (enterprise-grade availability)
```

## 🛠️ Implementation Steps for Your Current Setup

### Quick Win: Add LoadBalancer Services
```bash
# 1. Update your current services to LoadBalancer type
sed -i 's/type: ClusterIP/type: LoadBalancer/g' k8s/*.yaml

# 2. Apply changes
kubectl apply -f k8s/product-service.yaml
kubectl apply -f k8s/inventory-service.yaml
kubectl apply -f k8s/order-service.yaml

# 3. Get external IPs
kubectl get services --watch

# 4. Test external access
PRODUCT_IP=$(kubectl get service product-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$PRODUCT_IP:8080/actuator/health
```

### Full Production Setup
1. **Create Application Gateway** (follow Option A above)
2. **Set up SSL certificates** for HTTPS
3. **Configure WAF rules** for security
4. **Add monitoring** and alerting
5. **Test failover scenarios**

## 🚨 Security Considerations

```bash
# Restrict load balancer access to specific IPs
az network nsg rule create \
  --resource-group microservices-rg \
  --nsg-name microservices-nsg \
  --name AllowLoadBalancerOnly \
  --protocol tcp \
  --priority 900 \
  --source-address-prefixes AzureLoadBalancer \
  --destination-port-ranges 8080-8082

# Block direct VM access
az network nsg rule create \
  --resource-group microservices-rg \
  --nsg-name microservices-nsg \
  --name DenyDirectVMAccess \
  --protocol tcp \
  --priority 1000 \
  --access Deny \
  --source-address-prefixes Internet \
  --destination-port-ranges 8080-8082
```

**Would you like me to update the main Azure deployment guide to include one of these load balancer options by default?** 