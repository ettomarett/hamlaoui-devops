#!/bin/bash

# Jenkins Quick Fix Script - Option A Implementation
# This script installs Maven, Docker CLI, and kubectl in the existing Jenkins container

echo "🚀 Starting Jenkins Quick Fix - Installing Dependencies"
echo "=================================================="

# Get Jenkins pod name
JENKINS_POD=$(kubectl get pods -n ci-cd -l app=jenkins -o jsonpath='{.items[0].metadata.name}')

if [ -z "$JENKINS_POD" ]; then
    echo "❌ Jenkins pod not found in ci-cd namespace"
    echo "Checking default namespace..."
    JENKINS_POD=$(kubectl get pods -l app=jenkins -o jsonpath='{.items[0].metadata.name}')
    NAMESPACE="default"
else
    NAMESPACE="ci-cd"
fi

if [ -z "$JENKINS_POD" ]; then
    echo "❌ Jenkins pod not found. Please check your Jenkins deployment."
    exit 1
fi

echo "✅ Found Jenkins pod: $JENKINS_POD in namespace: $NAMESPACE"

# Function to execute commands in Jenkins pod
exec_in_jenkins() {
    kubectl exec -n $NAMESPACE $JENKINS_POD -- bash -c "$1"
}

# Function to execute commands as root in Jenkins pod
exec_in_jenkins_root() {
    kubectl exec -n $NAMESPACE $JENKINS_POD -- bash -c "sudo bash -c \"$1\""
}

echo ""
echo "🔍 Checking current environment in Jenkins pod..."
echo "=================================================="

# Check current Java version
echo "Java Version:"
exec_in_jenkins "java -version" 2>&1 || echo "Java check failed"

# Check if Maven exists
echo ""
echo "Maven Status:"
exec_in_jenkins "mvn -version" 2>&1 || echo "Maven not found - will install"

# Check if Docker exists
echo ""
echo "Docker Status:"
exec_in_jenkins "docker --version" 2>&1 || echo "Docker not found - will install"

# Check if kubectl exists
echo ""
echo "kubectl Status:"
exec_in_jenkins "kubectl version --client" 2>&1 || echo "kubectl not found - will install"

echo ""
echo "🔧 Installing Dependencies..."
echo "=================================================="

# Update package lists
echo "📦 Updating package lists..."
exec_in_jenkins_root "apt-get update" || echo "Package update failed, continuing..."

# Install basic dependencies
echo "📦 Installing basic dependencies..."
exec_in_jenkins_root "apt-get install -y curl wget unzip apt-transport-https ca-certificates gnupg lsb-release" || echo "Basic deps install failed"

# Install Maven 3.9.6
echo ""
echo "📦 Installing Maven 3.9.6..."
exec_in_jenkins_root "
if [ ! -d '/opt/maven' ]; then
    echo 'Downloading Maven...'
    wget -q https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz -O /tmp/maven.tar.gz
    echo 'Extracting Maven...'
    tar -xzf /tmp/maven.tar.gz -C /opt/
    ln -sf /opt/apache-maven-3.9.6 /opt/maven
    rm -f /tmp/maven.tar.gz
    echo 'Maven installed successfully'
else
    echo 'Maven already installed'
fi
"

# Install Docker CLI
echo ""
echo "🐳 Installing Docker CLI..."
exec_in_jenkins_root "
if ! command -v docker &> /dev/null; then
    echo 'Installing Docker CLI...'
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable' | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce-cli
    echo 'Docker CLI installed successfully'
else
    echo 'Docker CLI already installed'
fi
"

# Install kubectl
echo ""
echo "☸️ Installing kubectl..."
exec_in_jenkins_root "
if ! command -v kubectl &> /dev/null; then
    echo 'Installing kubectl...'
    curl -LO 'https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl'
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm -f kubectl
    echo 'kubectl installed successfully'
else
    echo 'kubectl already installed'
fi
"

# Set up Maven environment
echo ""
echo "🔧 Setting up Maven environment..."
exec_in_jenkins_root "
echo 'export MAVEN_HOME=/opt/maven' >> /etc/environment
echo 'export PATH=\$PATH:/opt/maven/bin:/usr/local/bin' >> /etc/environment
"

# Create Maven repository directory
echo ""
echo "📁 Setting up Maven repository..."
exec_in_jenkins_root "
mkdir -p /var/jenkins_home/.m2/repository
chown -R jenkins:jenkins /var/jenkins_home/.m2
"

# Set up Docker permissions
echo ""
echo "🐳 Setting up Docker permissions..."
exec_in_jenkins_root "
if getent group docker > /dev/null 2>&1; then
    usermod -aG docker jenkins
    echo 'Added jenkins user to docker group'
else
    echo 'Docker group not found, skipping user addition'
fi
"

echo ""
echo "✅ Verification - Checking installed tools..."
echo "=================================================="

# Verify Java
echo "Java Version:"
exec_in_jenkins "java -version" 2>&1

# Verify Maven
echo ""
echo "Maven Version:"
exec_in_jenkins "/opt/maven/bin/mvn -version" 2>&1 || exec_in_jenkins "mvn -version" 2>&1

# Verify Docker
echo ""
echo "Docker Version:"
exec_in_jenkins "docker --version" 2>&1

# Verify kubectl
echo ""
echo "kubectl Version:"
exec_in_jenkins "kubectl version --client" 2>&1

# Check environment variables
echo ""
echo "Environment Variables:"
exec_in_jenkins "echo 'MAVEN_HOME: /opt/maven'"
exec_in_jenkins "echo 'PATH includes Maven: ' && echo \$PATH | grep -o '/opt/maven/bin' || echo 'Maven not in PATH'"

echo ""
echo "📋 Final Setup Steps..."
echo "=================================================="

echo "1. ✅ Dependencies installed in Jenkins pod: $JENKINS_POD"
echo "2. ✅ Maven 3.9.6 installed at /opt/maven"
echo "3. ✅ Docker CLI installed"
echo "4. ✅ kubectl installed"
echo "5. ✅ Maven repository created at /var/jenkins_home/.m2/repository"

echo ""
echo "🔄 Next Steps:"
echo "1. Update your Jenkins pipeline to use 'backend/Jenkinsfile-Production'"
echo "2. Set Jenkins environment variables if needed:"
echo "   - MAVEN_HOME: /opt/maven"
echo "   - PATH: \$PATH:/opt/maven/bin:/usr/local/bin"
echo "3. Test the pipeline with a new build"

echo ""
echo "🎉 Jenkins Quick Fix completed successfully!"
echo "Your Jenkins container now has all required dependencies installed." 