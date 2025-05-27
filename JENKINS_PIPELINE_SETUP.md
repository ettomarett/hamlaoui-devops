# 🚀 Jenkins Pipeline Setup & Configuration Guide

## 📊 Current Status: OPERATIONAL ✅

**Jenkins URL:** http://20.86.144.152:31080  
**Registry URL:** localhost:32000  
**Pipeline Status:** Ready for configuration

---

## 🏗️ Infrastructure Overview

### ✅ **Current Setup**
- **Jenkins Pod:** `jenkins-694c4f9587-kqz6b` (Running, 47h uptime)
- **Docker Registry:** `registry-6c9fcc695f-zqkzf` (Running, 2d23h uptime)
- **Existing Images:** product-service, inventory-service, order-service
- **Namespace:** ci-cd (dedicated CI/CD namespace)

### 🔧 **Pipeline Components**
- **Source:** GitHub repository (https://github.com/ettomarett/hamlaoui-devops)
- **Build Tool:** Maven 3.9.6
- **Container Registry:** localhost:32000
- **Deployment Target:** Kubernetes (MicroK8s)
- **Health Checks:** Spring Boot Actuator endpoints

---

## 🎯 Jenkins Pipeline Configuration

### 📋 **Pipeline Stages Overview**
1. **🚀 Pipeline Start** - Initialization and checkout
2. **🔧 Setup Build Environment** - Maven installation and verification
3. **📦 Build Microservices** - Parallel Maven builds
4. **🧪 Run Tests** - Parallel test execution
5. **🐳 Build Docker Images** - Parallel image creation
6. **📤 Push to Registry** - Image registry upload
7. **☸️ Deploy to Kubernetes** - Rolling deployment
8. **🔍 Health Check & Verification** - Service validation

### 🔄 **Pipeline Flow**
```
GitHub Webhook → Jenkins → Maven Build → Docker Build → Registry Push → K8s Deploy → Health Check
```

---

## 🛠️ Step-by-Step Setup

### 1. **Access Jenkins Dashboard**
```bash
# Open in browser
http://20.86.144.152:31080

# Or check status
curl -s http://20.86.144.152:31080 | grep "Jenkins"
```

### 2. **Create New Pipeline Job**
1. Click "New Item"
2. Enter name: `e-commerce-microservices-pipeline`
3. Select "Pipeline"
4. Click "OK"

### 3. **Configure Pipeline**
```groovy
// Pipeline Configuration
Pipeline script from SCM:
- SCM: Git
- Repository URL: https://github.com/ettomarett/hamlaoui-devops.git
- Branch: */main
- Script Path: backend/Jenkinsfile
```

### 4. **Environment Variables**
```bash
DOCKER_REGISTRY=localhost:32000
KUBECONFIG=/var/jenkins_home/.kube/config
GIT_REPO=https://github.com/ettomarett/hamlaoui-devops.git
PROJECT_DIR=hamlaoui-devops
MAVEN_HOME=/opt/maven
```

---

## 🔧 Pipeline Features

### ✅ **Implemented Features**
- **Parallel Builds** - All 3 microservices build simultaneously
- **Automated Testing** - Maven test execution for each service
- **Docker Image Building** - Containerization with build numbers
- **Registry Management** - Automatic push to local registry
- **Kubernetes Deployment** - Rolling updates with health checks
- **Health Verification** - Comprehensive service validation
- **Error Handling** - Graceful failure management

### 🎯 **Build Artifacts**
```bash
# JAR Files
product-service/target/product-service-*.jar
inventory-service/target/inventory-service-*.jar
order-service/target/order-service-*.jar

# Docker Images
localhost:32000/product-service:${BUILD_NUMBER}
localhost:32000/inventory-service:${BUILD_NUMBER}
localhost:32000/order-service:${BUILD_NUMBER}
```

---

## 🚀 Manual Pipeline Execution

### 🔄 **Trigger Build**
```bash
# Via Jenkins UI
1. Go to http://20.86.144.152:31080
2. Click on pipeline job
3. Click "Build Now"

# Via API (if configured)
curl -X POST http://20.86.144.152:31080/job/e-commerce-microservices-pipeline/build
```

### 📊 **Monitor Build Progress**
```bash
# Check Jenkins pod logs
kubectl logs -n ci-cd jenkins-694c4f9587-kqz6b -f

# Check build status
curl -s http://20.86.144.152:31080/job/e-commerce-microservices-pipeline/lastBuild/api/json
```

---

## 🧪 Pipeline Testing

### 🔍 **Pre-Build Verification**
```bash
# Check Jenkins accessibility
curl -s http://20.86.144.152:31080 | grep "Jenkins"

# Verify registry
curl -s http://localhost:32000/v2/_catalog

# Check Kubernetes access
kubectl get pods -n ci-cd
kubectl get pods -n default | grep -E "(product|inventory|order)"
```

### 🎯 **Build Validation**
```bash
# After build completion, verify:

# 1. New images in registry
curl -s http://localhost:32000/v2/product-service/tags/list
curl -s http://localhost:32000/v2/inventory-service/tags/list
curl -s http://localhost:32000/v2/order-service/tags/list

# 2. Updated deployments
kubectl get deployments -o wide

# 3. Service health
curl http://20.86.144.152:31309/actuator/health
curl http://20.86.144.152:31081/actuator/health
curl http://20.86.144.152:31004/actuator/health
```

---

## 🔧 Troubleshooting

### ⚠️ **Common Issues**

#### **1. Maven Build Failures**
```bash
# Check Maven installation
kubectl exec -n ci-cd jenkins-694c4f9587-kqz6b -- /opt/maven/bin/mvn -version

# Verify Java version
kubectl exec -n ci-cd jenkins-694c4f9587-kqz6b -- java -version
```

#### **2. Docker Build Issues**
```bash
# Check Docker daemon
kubectl exec -n ci-cd jenkins-694c4f9587-kqz6b -- docker version

# Verify Dockerfile exists
ls -la backend/product-service/Dockerfile
ls -la backend/inventory-service/Dockerfile
ls -la backend/order-service/Dockerfile
```

#### **3. Registry Push Problems**
```bash
# Test registry connectivity
kubectl exec -n ci-cd jenkins-694c4f9587-kqz6b -- curl -s http://localhost:32000/v2/_catalog

# Check registry pod
kubectl get pods -n container-registry
```

#### **4. Kubernetes Deployment Failures**
```bash
# Check kubectl access
kubectl exec -n ci-cd jenkins-694c4f9587-kqz6b -- /snap/microk8s/current/kubectl get pods

# Verify deployment manifests
ls -la backend/k8s/
```

---

## 🎯 Pipeline Optimization

### 🚀 **Performance Improvements**
1. **Parallel Execution** - Already implemented for builds and tests
2. **Maven Caching** - Local repository configured
3. **Docker Layer Caching** - Optimize Dockerfiles
4. **Resource Limits** - Configure Jenkins pod resources

### 📊 **Monitoring Integration**
```bash
# Add pipeline metrics to Prometheus
# Configure Grafana dashboard for build metrics
# Set up AlertManager for build failures
```

### 🔄 **Advanced Features**
- **Blue-Green Deployments** - Zero-downtime updates
- **Canary Releases** - Gradual rollouts
- **Automated Rollbacks** - Failure recovery
- **Multi-environment** - Dev/Staging/Prod pipelines

---

## 📋 Pipeline Execution Checklist

### ✅ **Pre-Build Checklist**
- [ ] Jenkins pod is running
- [ ] Docker registry is accessible
- [ ] GitHub repository is accessible
- [ ] Kubernetes cluster is healthy
- [ ] Maven dependencies are cached

### ✅ **Build Execution**
- [ ] Source code checkout successful
- [ ] Maven builds complete for all services
- [ ] Unit tests pass (or acceptable failure rate)
- [ ] Docker images built successfully
- [ ] Images pushed to registry
- [ ] Kubernetes deployments updated
- [ ] Health checks pass

### ✅ **Post-Build Verification**
- [ ] All services are running
- [ ] Health endpoints return 200
- [ ] Frontend can access APIs
- [ ] No error logs in pods
- [ ] Monitoring shows healthy metrics

---

## 🌐 Access Points

### 🔗 **Jenkins Dashboard**
```bash
# Main Dashboard
http://20.86.144.152:31080

# Pipeline Job
http://20.86.144.152:31080/job/e-commerce-microservices-pipeline/

# Build History
http://20.86.144.152:31080/job/e-commerce-microservices-pipeline/builds
```

### 📊 **Registry Management**
```bash
# Registry API
curl http://localhost:32000/v2/_catalog

# Image Tags
curl http://localhost:32000/v2/product-service/tags/list
```

### ☸️ **Kubernetes Resources**
```bash
# Jenkins Namespace
kubectl get all -n ci-cd

# Application Namespace
kubectl get all -n default | grep -E "(product|inventory|order)"
```

---

## 🎉 **Pipeline Success Metrics**

### 📊 **Current KPIs**
- **Build Time:** ~5-10 minutes (estimated)
- **Success Rate:** To be measured
- **Deployment Time:** ~2-3 minutes
- **Health Check Time:** ~30 seconds

### 🎯 **Target KPIs**
- **Build Time:** < 5 minutes
- **Success Rate:** > 95%
- **Deployment Time:** < 2 minutes
- **Health Check Time:** < 15 seconds

---

## 🏆 **Next Steps**

### 🔥 **Immediate Actions**
1. **Configure Pipeline Job** in Jenkins UI
2. **Test Manual Build** execution
3. **Verify Health Checks** post-deployment
4. **Set up Build Notifications** (email/Slack)

### 📈 **Future Enhancements**
1. **Webhook Integration** for automatic builds
2. **Quality Gates** with SonarQube
3. **Security Scanning** with Trivy
4. **Performance Testing** integration

---

*Pipeline Configuration Guide*  
*Last Updated: May 27, 2025*  
*Status: ✅ READY FOR SETUP* 