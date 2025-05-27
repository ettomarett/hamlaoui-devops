# Jenkins Docker Container Setup Guide

## Overview
This guide explains how to set up a Jenkins Docker container with all required dependencies pre-installed for the e-commerce microservices CI/CD pipeline.

## Required Dependencies
- **Java 17** (OpenJDK)
- **Maven 3.9.6**
- **Docker CLI** (for building images)
- **kubectl** (for Kubernetes deployments)
- **curl** (for health checks)
- **git** (for source control)

## Option 1: Custom Jenkins Dockerfile

Create a custom Jenkins image with all dependencies:

```dockerfile
FROM jenkins/jenkins:lts

# Switch to root to install dependencies
USER root

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && apt-get install -y docker-ce-cli

# Install Maven 3.9.6
RUN wget https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz -O /tmp/maven.tar.gz
RUN tar -xzf /tmp/maven.tar.gz -C /opt/
RUN ln -s /opt/apache-maven-3.9.6 /opt/maven
RUN rm /tmp/maven.tar.gz

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
RUN install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Set environment variables
ENV MAVEN_HOME=/opt/maven
ENV PATH=$PATH:$MAVEN_HOME/bin:/usr/local/bin

# Create Maven repository directory
RUN mkdir -p /var/jenkins_home/.m2/repository
RUN chown -R jenkins:jenkins /var/jenkins_home/.m2

# Switch back to jenkins user
USER jenkins

# Install Jenkins plugins
RUN jenkins-plugin-cli --plugins \
    git \
    workflow-aggregator \
    docker-workflow \
    kubernetes \
    maven-plugin \
    junit \
    build-timeout \
    timestamper
```

## Option 2: Docker Compose with Custom Image

```yaml
version: '3.8'
services:
  jenkins:
    build:
      context: .
      dockerfile: Dockerfile.jenkins
    container_name: jenkins-custom
    ports:
      - "31080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=false
      - MAVEN_HOME=/opt/maven
    networks:
      - jenkins-network

volumes:
  jenkins_home:

networks:
  jenkins-network:
    driver: bridge
```

## Option 3: Update Existing Jenkins Container

If you already have Jenkins running, you can update it by:

### 1. Access Jenkins Container
```bash
# Find Jenkins container
docker ps | grep jenkins

# Access container shell
docker exec -it <jenkins-container-id> bash
```

### 2. Install Dependencies (as root)
```bash
# Switch to root
sudo su -

# Install Maven
wget https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz -O /tmp/maven.tar.gz
tar -xzf /tmp/maven.tar.gz -C /opt/
ln -s /opt/apache-maven-3.9.6 /opt/maven
rm /tmp/maven.tar.gz

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Docker CLI (if not present)
apt-get update
apt-get install -y docker-ce-cli

# Set permissions
chown -R jenkins:jenkins /var/jenkins_home/.m2
```

### 3. Update Environment Variables
Add to Jenkins global environment variables:
- `MAVEN_HOME`: `/opt/maven`
- `PATH`: `$PATH:/opt/maven/bin:/usr/local/bin`

## Option 4: Kubernetes Jenkins Deployment

Update your Jenkins deployment to use a custom image:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins
  namespace: ci-cd
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      containers:
      - name: jenkins
        image: your-registry/jenkins-custom:latest
        ports:
        - containerPort: 8080
        - containerPort: 50000
        env:
        - name: MAVEN_HOME
          value: "/opt/maven"
        - name: PATH
          value: "/opt/maven/bin:/usr/local/bin:$(PATH)"
        volumeMounts:
        - name: jenkins-home
          mountPath: /var/jenkins_home
        - name: docker-sock
          mountPath: /var/run/docker.sock
      volumes:
      - name: jenkins-home
        persistentVolumeClaim:
          claimName: jenkins-pvc
      - name: docker-sock
        hostPath:
          path: /var/run/docker.sock
```

## Verification Steps

After setting up Jenkins with dependencies, verify everything is working:

### 1. Check Java
```bash
java -version
# Should show: openjdk version "17.0.x"
```

### 2. Check Maven
```bash
mvn -version
# Should show: Apache Maven 3.9.6
```

### 3. Check Docker
```bash
docker --version
# Should show: Docker version 20.x.x
```

### 4. Check kubectl
```bash
kubectl version --client
# Should show: Client Version: v1.x.x
```

## Jenkins Pipeline Configuration

1. **Create New Pipeline Job**:
   - Name: `e-commerce-microservices-pipeline`
   - Type: Pipeline

2. **Configure Source**:
   - Repository URL: `https://github.com/ettomarett/hamlaoui-devops.git`
   - Branch: `*/main`
   - Script Path: `backend/Jenkinsfile-Production`

3. **Environment Variables** (if needed):
   - `DOCKER_REGISTRY`: `localhost:32000`
   - `MAVEN_OPTS`: `-Dmaven.repo.local=/var/jenkins_home/.m2/repository`

## Troubleshooting

### Common Issues:

1. **Maven not found**:
   - Verify `/opt/maven/bin/mvn` exists
   - Check PATH includes `/opt/maven/bin`

2. **Docker permission denied**:
   - Ensure jenkins user is in docker group
   - Verify docker socket is mounted

3. **kubectl not working**:
   - Check kubectl is in `/usr/local/bin/`
   - Verify kubeconfig is accessible

4. **Build failures**:
   - Check disk space: `df -h`
   - Verify network connectivity
   - Check service dependencies

## Performance Optimization

1. **Maven Repository**:
   - Use persistent volume for `/var/jenkins_home/.m2/repository`
   - Pre-populate with common dependencies

2. **Docker Layer Caching**:
   - Use multi-stage builds
   - Optimize Dockerfile layer order

3. **Resource Limits**:
   - Set appropriate CPU/memory limits
   - Monitor resource usage

## Security Considerations

1. **Container Security**:
   - Run as non-root user when possible
   - Use specific image tags, not `latest`
   - Regularly update base images

2. **Network Security**:
   - Limit network access
   - Use private registries
   - Secure Jenkins credentials

3. **Access Control**:
   - Configure proper RBAC
   - Use service accounts
   - Audit access logs

## Next Steps

1. Build and deploy the custom Jenkins image
2. Update your pipeline to use `backend/Jenkinsfile-Production`
3. Test the pipeline with a sample build
4. Monitor performance and adjust resources as needed

This setup ensures all dependencies are pre-installed and available for your CI/CD pipeline without requiring sudo or runtime installations. 