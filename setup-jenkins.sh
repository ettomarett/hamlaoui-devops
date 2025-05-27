#!/bin/bash

echo "🚀 Setting up Jenkins with pre-installed tools..."

# Stop existing Jenkins container if running
echo "🛑 Stopping existing Jenkins container..."
docker stop jenkins-custom 2>/dev/null || echo "No existing Jenkins container found"
docker rm jenkins-custom 2>/dev/null || echo "No existing Jenkins container to remove"

# Build the custom Jenkins image
echo "🏗️ Building custom Jenkins Docker image..."
docker build -f Dockerfile.jenkins -t jenkins-custom:latest .

if [ $? -ne 0 ]; then
    echo "❌ Failed to build Jenkins image"
    exit 1
fi

echo "✅ Jenkins image built successfully"

# Start Jenkins with Docker Compose
echo "🚀 Starting Jenkins with Docker Compose..."
docker-compose -f docker-compose.jenkins.yml up -d

if [ $? -ne 0 ]; then
    echo "❌ Failed to start Jenkins"
    exit 1
fi

echo "✅ Jenkins started successfully"

# Wait for Jenkins to be ready
echo "⏳ Waiting for Jenkins to be ready..."
sleep 30

# Check if Jenkins is running
if docker ps | grep -q jenkins-custom; then
    echo "✅ Jenkins is running"
    echo "🌐 Jenkins URL: http://localhost:31080"
    echo "🌐 Docker Registry: http://localhost:32000"
    
    # Get initial admin password
    echo "🔑 Getting initial admin password..."
    docker exec jenkins-custom cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || echo "Password file not found yet, wait a moment and try: docker exec jenkins-custom cat /var/jenkins_home/secrets/initialAdminPassword"
    
    echo ""
    echo "📋 Next Steps:"
    echo "1. Open http://localhost:31080 in your browser"
    echo "2. Use the admin password shown above"
    echo "3. Install suggested plugins"
    echo "4. Create a new pipeline job pointing to your repository"
    echo "5. Use 'Jenkinsfile-Fixed' as the pipeline script path"
    echo ""
    echo "🔧 Tools installed in Jenkins:"
    echo "- Java 17 (OpenJDK)"
    echo "- Maven 3.9.6"
    echo "- Docker CLI"
    echo "- kubectl"
    echo "- Node.js 18"
    echo "- npm"
    echo ""
    echo "🎯 Your pipeline should now work without sudo or runtime installations!"
    
else
    echo "❌ Jenkins failed to start"
    echo "📋 Checking logs..."
    docker logs jenkins-custom
    exit 1
fi 