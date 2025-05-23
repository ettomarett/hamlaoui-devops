# 🚀 Quick Start Guide

Get the entire microservices system running in **under 10 minutes**!## 🌟 **NEW: Azure Deployment Option****Planning to use Azure VMs? Check out our comprehensive [Azure Deployment Guide](AZURE_DEPLOYMENT.md)** - Complete 3-hour setup with Azure CLI, VMs, and managed services! ☁️

## Option 1: Docker Compose (Fastest)

```bash
# Clone and start everything
git clone https://github.com/your-username/SpringBoot-Microservices-Order-Management-System.git
cd SpringBoot-Microservices-Order-Management-System

# Build services
mvn clean package -DskipTests -pl product-service,inventory-service,order-service

# Start everything with Docker Compose
docker-compose up -d

# Wait 2 minutes for services to start, then test
curl http://localhost:8080/actuator/health  # Product Service
curl http://localhost:8081/actuator/health  # Inventory Service  
curl http://localhost:8082/actuator/health  # Order Service

# Access monitoring
open http://localhost:3000  # Grafana (admin/admin)
open http://localhost:9090  # Prometheus
```

## Option 2: Kubernetes (Production-Like) 🏭**Note**: This uses production patterns (auto-scaling, health checks, resource limits) but isn't fully production-ready. See [PRODUCTION_READINESS.md](PRODUCTION_READINESS.md) for enterprise requirements.```bash# Prerequisites: kubectl and a K8s cluster# Deploy everythingkubectl apply -f k8s/

# Wait for pods to be ready
kubectl wait --for=condition=ready pod --all --timeout=300s

# Port forward to access services
kubectl port-forward svc/product-service 8080:8080 &
kubectl port-forward svc/inventory-service 8081:8081 &
kubectl port-forward svc/order-service 8082:8082 &

# Test services
curl http://localhost:8080/actuator/health
curl http://localhost:8081/actuator/health
curl http://localhost:8082/actuator/health
```

## Option 3: Local Development (No Docker)

```bash
# Prerequisites: Java 17, Maven, MongoDB, MySQL

# Build services
mvn clean package -DskipTests -pl product-service,inventory-service,order-service

# Start services (in separate terminals)
cd product-service && java -jar target/product-service-1.0-SNAPSHOT.jar &
cd inventory-service && java -jar target/inventory-service-1.0-SNAPSHOT.jar --server.port=8081 &
cd order-service && java -jar target/order-service-1.0-SNAPSHOT.jar --server.port=8082 &

# Test services
curl http://localhost:8080/actuator/health
curl http://localhost:8081/actuator/health
curl http://localhost:8082/actuator/health
```

## 🧪 Test the System

```bash
# Create a product
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Product", "description": "A test product", "price": 29.99}'

# Check inventory (replace {productId} with actual ID)
curl http://localhost:8081/api/inventory/{productId}

# Create an order
curl -X POST http://localhost:8082/api/orders \
  -H "Content-Type: application/json" \
  -d '{"productId": "{productId}", "quantity": 2}'
```

## 📊 Access Monitoring

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Service Health**: 
  - http://localhost:8080/actuator/health
  - http://localhost:8081/actuator/health
  - http://localhost:8082/actuator/health

## 🔧 Troubleshooting

### Services won't start?
```bash
# Check logs
docker-compose logs product-service
# or
kubectl logs deployment/product-service
```

### Database connection issues?
```bash
# Verify databases are running
docker-compose ps
# or
kubectl get pods
```

### Port conflicts?
```bash
# Check what's using the ports
netstat -tulpn | grep :8080
```

## 🎯 What's Next?

1. **Fork the repository** to your GitHub account
2. **Set up CI/CD** by adding `KUBECONFIG_B64` secret
3. **Push changes** to trigger automatic deployment
4. **Import Grafana dashboards** (7362, 4701)
5. **Load test** with `hey -z 2m -c 20 http://localhost:8080/actuator/health`

## 📚 More Information

- [Full Deployment Guide](DEPLOYMENT.md) - Complete 3-hour setup
- [Project Summary](PROJECT_SUMMARY.md) - What's included
- [Original README](README.md) - Project background

**Happy coding! 🎉** 