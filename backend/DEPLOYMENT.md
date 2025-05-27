# 3-Hour Microservices Deployment Guide

This guide will help you deploy a complete microservices system with CI/CD and monitoring in under 3 hours.

## Architecture Overview

- **Product Service** (MongoDB) - Port 8080
- **Inventory Service** (MySQL) - Port 8081  
- **Order Service** (MySQL) - Port 8082
- **CI/CD Pipeline** (GitHub Actions)
- **Monitoring** (Prometheus + Grafana)
- **Orchestration** (Kubernetes with microk8s)

## Prerequisites

- Ubuntu/Linux system
- Docker installed
- GitHub account
- Basic knowledge of Kubernetes

## 180-Minute Execution Checklist

### 00:00 – 00:15: Repository & Secrets Setup

1. **Fork this repository** to your GitHub account

2. **Set up GitHub Secrets** (Repository → Settings → Secrets):
   ```
   KUBECONFIG_B64: <base64-encoded kubeconfig>
   ```

### 00:15 – 00:35: MicroK8s Cluster Setup

```bash
# Install microk8s
sudo snap install microk8s --classic --channel=1.29/stable

# Add user to microk8s group
sudo usermod -a -G microk8s $USER && newgrp microk8s

# Enable required addons
microk8s enable dns registry ingress prometheus

# Wait for cluster to be ready
microk8s status --wait-ready

# Export kubeconfig and encode for GitHub secrets
microk8s config > ~/.kube/config
base64 -w0 ~/.kube/config
```

Copy the base64 output and add it as `KUBECONFIG_B64` secret in GitHub.

### 00:35 – 01:05: Build & Push Images

```bash
# Clone your forked repository
git clone https://github.com/<your-username>/SpringBoot-Microservices-Order-Management-System.git
cd SpringBoot-Microservices-Order-Management-System

# Build all services
mvn clean package -DskipTests -pl product-service,inventory-service,order-service

# Build and push Docker images
docker build -t ghcr.io/<your-username>/product-service:dev product-service
docker build -t ghcr.io/<your-username>/inventory-service:dev inventory-service
docker build -t ghcr.io/<your-username>/order-service:dev order-service

# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u <your-username> --password-stdin

# Push images
docker push ghcr.io/<your-username>/product-service:dev
docker push ghcr.io/<your-username>/inventory-service:dev
docker push ghcr.io/<your-username>/order-service:dev
```

### 01:05 – 01:25: Kubernetes Deployment

```bash
# Update image references in manifests
sed -i 's/ghcr.io\/hamlaoui/ghcr.io\/<your-username>/g' k8s/*.yaml

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

# Verify deployment
kubectl get pods,svc
```

### 01:25 – 01:40: Initial Testing

```bash
# Port forward to test services
kubectl port-forward svc/product-service 8080:8080 &
kubectl port-forward svc/inventory-service 8081:8081 &
kubectl port-forward svc/order-service 8082:8082 &

# Test health endpoints
curl http://localhost:8080/actuator/health
curl http://localhost:8081/actuator/health
curl http://localhost:8082/actuator/health

# Test Prometheus metrics
curl http://localhost:8080/actuator/prometheus
```

### 01:40 – 02:00: Grafana Dashboard Setup

```bash
# Port forward to Grafana
kubectl -n monitoring port-forward svc/prometheus-grafana 3000:80 &

# Access Grafana at http://localhost:3000
# Login: admin / prom-operator

# Import dashboards:
# - Dashboard ID 7362 (Kubernetes Pods)
# - Dashboard ID 4701 (Spring Boot JVM)
```

### 02:00 – 02:30: CI/CD Pipeline Testing

1. **Make a code change** and push to trigger the pipeline
2. **Monitor GitHub Actions** for build and deployment
3. **Verify automatic deployment** with:
   ```bash
   kubectl rollout status deployment/product-service
   kubectl rollout status deployment/inventory-service
   kubectl rollout status deployment/order-service
   ```

### 02:30 – 02:45: Load Testing & Auto-scaling

```bash
# Install hey for load testing
go install github.com/rakyll/hey@latest

# Generate load
hey -z 2m -c 20 http://localhost:8080/actuator/health

# Watch auto-scaling
kubectl get hpa -w
kubectl get pods -w
```

### 02:45 – 03:00: Documentation & Wrap-up

1. **Take screenshots** of:
   - GitHub Actions successful build
   - Grafana dashboards showing metrics
   - kubectl get pods showing scaled instances

2. **Update README.md** with your specific setup details

3. **Commit and push** final changes

## API Endpoints

### Product Service (Port 8080)
- `GET /api/products` - List all products
- `POST /api/products` - Create a product
- `GET /actuator/health` - Health check
- `GET /actuator/prometheus` - Metrics

### Inventory Service (Port 8081)
- `GET /api/inventory/{productId}` - Check inventory
- `GET /actuator/health` - Health check
- `GET /actuator/prometheus` - Metrics

### Order Service (Port 8082)
- `POST /api/orders` - Create an order
- `GET /actuator/health` - Health check
- `GET /actuator/prometheus` - Metrics

## Monitoring URLs

- **Grafana**: http://localhost:3000 (admin/prom-operator)
- **Prometheus**: http://localhost:9090

## Troubleshooting

### Common Issues

1. **Build failures**: Check Java version (should be 17)
2. **Image pull errors**: Verify GitHub Container Registry permissions
3. **Database connection issues**: Check if MongoDB/MySQL pods are running
4. **Metrics not showing**: Verify Prometheus annotations in pod specs

### Useful Commands

```bash
# Check pod logs
kubectl logs -f deployment/product-service

# Describe pod for troubleshooting
kubectl describe pod <pod-name>

# Check resource usage
kubectl top pods

# Scale manually
kubectl scale deployment product-service --replicas=3
```

## Success Criteria

✅ All three microservices deployed and healthy  
✅ CI/CD pipeline working (GitHub Actions green)  
✅ Monitoring dashboards showing live metrics  
✅ Auto-scaling working under load  
✅ All health endpoints responding  

## Next Steps

- Add integration tests
- Implement service mesh (Istio)
- Add distributed tracing (Jaeger)
- Implement blue-green deployments
- Add security scanning to CI/CD 