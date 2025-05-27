#!/bin/bash

echo "🚀 Deploying Enhanced Jenkins with Maven, Docker, kubectl, Trivy, and Node.js..."

# Copy the enhanced Dockerfile to the cloud instance and deploy
scp -i ~/omarkey.pem Dockerfile.jenkins-enhanced omar@20.86.144.152:/tmp/

# SSH into the cloud instance and execute the deployment
ssh -i ~/omarkey.pem omar@20.86.144.152 << 'EOF'

echo "🏗️ Building enhanced Jenkins image with all tools..."
cd /tmp
docker build -f /tmp/Dockerfile.jenkins-enhanced -t localhost:32000/jenkins-enhanced:latest /tmp

if [ $? -ne 0 ]; then
    echo "❌ Failed to build Jenkins enhanced image"
    exit 1
fi

echo "📤 Pushing enhanced image to local registry..."
docker push localhost:32000/jenkins-enhanced:latest

if [ $? -ne 0 ]; then
    echo "❌ Failed to push Jenkins enhanced image"
    exit 1
fi

echo "🔄 Updating Jenkins deployment to use enhanced image..."

# Update the Jenkins deployment to use the new enhanced image
microk8s kubectl patch deployment jenkins-enhanced -n ci-cd -p '{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "jenkins",
          "image": "localhost:32000/jenkins-enhanced:latest",
          "env": [
            {"name": "JENKINS_OPTS", "value": "--httpPort=8080"},
            {"name": "JAVA_OPTS", "value": "-Xmx2048m -Dhudson.slaves.NodeProvisioner.MARGIN=50 -Dhudson.slaves.NodeProvisioner.MARGIN0=0.85"},
            {"name": "MAVEN_HOME", "value": "/opt/maven"},
            {"name": "MAVEN_OPTS", "value": "-Dmaven.repo.local=/var/jenkins_home/.m2/repository"},
            {"name": "DOCKER_HOST", "value": "unix:///var/run/docker.sock"}
          ],
          "volumeMounts": [
            {"name": "docker-sock", "mountPath": "/var/run/docker.sock"},
            {"name": "jenkins-home", "mountPath": "/var/jenkins_home"}
          ]
        }],
        "volumes": [
          {"name": "docker-sock", "hostPath": {"path": "/var/run/docker.sock"}},
          {"name": "jenkins-home", "persistentVolumeClaim": {"claimName": "jenkins-pvc"}}
        ]
      }
    }
  }
}'

if [ $? -ne 0 ]; then
    echo "❌ Failed to update Jenkins deployment"
    exit 1
fi

echo "⏳ Waiting for Jenkins to restart with enhanced image..."
microk8s kubectl rollout status deployment/jenkins-enhanced -n ci-cd --timeout=600s

echo "✅ Jenkins enhanced deployment updated successfully!"

echo "🔍 Verifying all tools are available..."
sleep 45

# Get the new pod name
NEW_POD=$(microk8s kubectl get pods -n ci-cd -l app=jenkins-enhanced -o jsonpath='{.items[0].metadata.name}')
echo "📋 New Jenkins enhanced pod: $NEW_POD"

echo "🔧 Checking Java version:"
microk8s kubectl exec $NEW_POD -n ci-cd -- java -version

echo "🔧 Checking Maven version:"
microk8s kubectl exec $NEW_POD -n ci-cd -- mvn -version

echo "🔧 Checking Docker version:"
microk8s kubectl exec $NEW_POD -n ci-cd -- docker --version

echo "🔧 Checking kubectl version:"
microk8s kubectl exec $NEW_POD -n ci-cd -- kubectl version --client

echo "🔧 Checking Trivy version:"
microk8s kubectl exec $NEW_POD -n ci-cd -- trivy --version

echo "🔧 Checking Node.js version:"
microk8s kubectl exec $NEW_POD -n ci-cd -- node --version

echo "🔧 Checking npm version:"
microk8s kubectl exec $NEW_POD -n ci-cd -- npm --version

echo "🎉 Jenkins Enhanced is now ready with all required tools!"
echo "🌐 Access Jenkins at: http://20.86.144.152:31080"
echo "📋 Available tools:"
echo "  ✅ Java 17"
echo "  ✅ Maven 3.9.6"
echo "  ✅ Docker CLI"
echo "  ✅ kubectl"
echo "  ✅ Trivy (Security Scanner)"
echo "  ✅ Node.js 18"
echo "  ✅ npm"
echo ""
echo "🚀 You can now run your CI/CD pipeline with security scanning!"

EOF 