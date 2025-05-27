#!/bin/bash

echo "🚀 Deploying Jenkins with pre-installed tools to cloud instance..."

# SSH into the cloud instance and execute the deployment
ssh -i /tmp/omarkey.pem omar@20.86.144.152 << 'EOF'

echo "📦 Creating custom Jenkins Dockerfile on cloud instance..."

# Create the custom Jenkins Dockerfile
cat > /tmp/Dockerfile.jenkins << 'DOCKERFILE'
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
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && apt-get install -y docker-ce-cli && rm -rf /var/lib/apt/lists/*

# Install Maven 3.9.6
RUN wget https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz -O /tmp/maven.tar.gz \
    && tar -xzf /tmp/maven.tar.gz -C /opt/ \
    && ln -s /opt/apache-maven-3.9.6 /opt/maven \
    && rm /tmp/maven.tar.gz

# Install Node.js and npm (for frontend builds if needed)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV MAVEN_HOME=/opt/maven
ENV PATH=$PATH:$MAVEN_HOME/bin:/usr/local/bin

# Create Maven repository directory and set permissions
RUN mkdir -p /var/jenkins_home/.m2/repository \
    && chown -R jenkins:jenkins /var/jenkins_home/.m2

# Add jenkins user to docker group (if it exists)
RUN groupadd -f docker && usermod -aG docker jenkins

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
    timestamper \
    pipeline-stage-view \
    blueocean

# Set Jenkins environment variables
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Dhudson.model.DirectoryBrowserSupport.CSP="
ENV MAVEN_OPTS="-Dmaven.repo.local=/var/jenkins_home/.m2/repository"
DOCKERFILE

echo "🏗️ Building custom Jenkins image..."
docker build -f /tmp/Dockerfile.jenkins -t localhost:32000/jenkins-custom:latest /tmp/

if [ $? -ne 0 ]; then
    echo "❌ Failed to build Jenkins image"
    exit 1
fi

echo "📤 Pushing image to local registry..."
docker push localhost:32000/jenkins-custom:latest

if [ $? -ne 0 ]; then
    echo "❌ Failed to push Jenkins image"
    exit 1
fi

echo "🔄 Updating Jenkins deployment..."

# Update the Jenkins deployment to use the new image
microk8s kubectl patch deployment jenkins -n ci-cd -p '{"spec":{"template":{"spec":{"containers":[{"name":"jenkins","image":"localhost:32000/jenkins-custom:latest","env":[{"name":"JENKINS_OPTS","value":"--httpPort=8080"},{"name":"JAVA_OPTS","value":"-Xmx2048m -Dhudson.slaves.NodeProvisioner.MARGIN=50 -Dhudson.slaves.NodeProvisioner.MARGIN0=0.85"},{"name":"MAVEN_HOME","value":"/opt/maven"},{"name":"MAVEN_OPTS","value":"-Dmaven.repo.local=/var/jenkins_home/.m2/repository"}]}]}}}}'

if [ $? -ne 0 ]; then
    echo "❌ Failed to update Jenkins deployment"
    exit 1
fi

echo "⏳ Waiting for Jenkins to restart..."
microk8s kubectl rollout status deployment/jenkins -n ci-cd --timeout=300s

echo "✅ Jenkins deployment updated successfully!"

echo "🔍 Verifying tools are available..."
sleep 30

# Get the new pod name
NEW_POD=$(microk8s kubectl get pods -n ci-cd -l app=jenkins -o jsonpath='{.items[0].metadata.name}')
echo "📋 New Jenkins pod: $NEW_POD"

echo "🔧 Checking Java version:"
microk8s kubectl exec $NEW_POD -n ci-cd -- java -version

echo "🔧 Checking Maven version:"
microk8s kubectl exec $NEW_POD -n ci-cd -- mvn -version

echo "🔧 Checking Docker version:"
microk8s kubectl exec $NEW_POD -n ci-cd -- docker --version

echo "🔧 Checking Node.js version:"
microk8s kubectl exec $NEW_POD -n ci-cd -- node --version

echo "🎉 Jenkins is now ready with all required tools!"
echo "🌐 Access Jenkins at: http://20.86.144.152:31080"
echo "📋 You can now run your pipeline without tool installation errors!"

EOF 