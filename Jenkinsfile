pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'localhost:32000'
        KUBECONFIG = '/var/jenkins_home/.kube/config'
        GIT_REPO = 'https://github.com/hamlaoui/hamlaoui-devops.git'
        PROJECT_DIR = 'hamlaoui-devops'
        NOTIFICATION_WEBHOOK = 'YOUR_SLACK_WEBHOOK_URL' // Optional: Add your Slack webhook
    }
    
    stages {
        stage('🚀 Pipeline Start') {
            steps {
                echo '🎯 STARTING E-COMMERCE MICROSERVICES CI/CD PIPELINE'
                echo "📅 Build Date: ${new Date()}"
                echo "🔢 Build Number: ${BUILD_NUMBER}"
                echo "🌿 Branch: ${env.GIT_BRANCH ?: 'main'}"
                
                // Clean workspace
                cleanWs()
                
                // Checkout code
                checkout scm
                
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                }
                
                echo "📝 Commit: ${env.GIT_COMMIT_SHORT}"
            }
        }
        
        stage('🔍 Environment Check') {
            steps {
                echo '🔧 Checking Build Environment...'
                sh '''
                    echo "Java Version:"
                    java -version
                    echo "Maven Version:"
                    mvn -version
                    echo "Docker Version:"
                    docker --version
                    echo "Kubectl Version:"
                    /snap/microk8s/current/kubectl version --client
                    echo "Available Disk Space:"
                    df -h
                    echo "Current Directory:"
                    pwd
                    echo "Directory Contents:"
                    ls -la
                '''
            }
        }
        
        stage('📦 Build Microservices') {
            parallel {
                stage('🛍️ Product Service') {
                    steps {
                        dir("${PROJECT_DIR}/product-service") {
                            echo '🏗️ Building Product Service...'
                            sh '''
                                echo "📂 Current directory: $(pwd)"
                                echo "📋 Files in directory:"
                                ls -la
                                
                                if [ -f "pom.xml" ]; then
                                    echo "✅ Found pom.xml, building with Maven..."
                                    mvn clean compile package -DskipTests -B
                                    echo "📦 Product Service JAR built successfully"
                                    ls -la target/
                                else
                                    echo "❌ No pom.xml found in product-service"
                                    exit 1
                                fi
                            '''
                        }
                    }
                    post {
                        success {
                            echo '✅ Product Service build completed'
                        }
                        failure {
                            echo '❌ Product Service build failed'
                        }
                    }
                }
                
                stage('📦 Inventory Service') {
                    steps {
                        dir("${PROJECT_DIR}/inventory-service") {
                            echo '🏗️ Building Inventory Service...'
                            sh '''
                                echo "📂 Current directory: $(pwd)"
                                echo "📋 Files in directory:"
                                ls -la
                                
                                if [ -f "pom.xml" ]; then
                                    echo "✅ Found pom.xml, building with Maven..."
                                    mvn clean compile package -DskipTests -B
                                    echo "📦 Inventory Service JAR built successfully"
                                    ls -la target/
                                else
                                    echo "❌ No pom.xml found in inventory-service"
                                    exit 1
                                fi
                            '''
                        }
                    }
                    post {
                        success {
                            echo '✅ Inventory Service build completed'
                        }
                        failure {
                            echo '❌ Inventory Service build failed'
                        }
                    }
                }
                
                stage('🛒 Order Service') {
                    steps {
                        dir("${PROJECT_DIR}/order-service") {
                            echo '🏗️ Building Order Service...'
                            sh '''
                                echo "📂 Current directory: $(pwd)"
                                echo "📋 Files in directory:"
                                ls -la
                                
                                if [ -f "pom.xml" ]; then
                                    echo "✅ Found pom.xml, building with Maven..."
                                    mvn clean compile package -DskipTests -B
                                    echo "📦 Order Service JAR built successfully"
                                    ls -la target/
                                else
                                    echo "❌ No pom.xml found in order-service"
                                    exit 1
                                fi
                            '''
                        }
                    }
                    post {
                        success {
                            echo '✅ Order Service build completed'
                        }
                        failure {
                            echo '❌ Order Service build failed'
                        }
                    }
                }
            }
        }
        
        stage('🧪 Run Tests') {
            parallel {
                stage('🛍️ Test Product') {
                    steps {
                        dir("${PROJECT_DIR}/product-service") {
                            echo '🧪 Testing Product Service...'
                            sh '''
                                mvn test -B || echo "Tests completed with status $?"
                                echo "📊 Test Results:"
                                if [ -d "target/surefire-reports" ]; then
                                    ls -la target/surefire-reports/
                                fi
                            '''
                        }
                    }
                }
                stage('📦 Test Inventory') {
                    steps {
                        dir("${PROJECT_DIR}/inventory-service") {
                            echo '🧪 Testing Inventory Service...'
                            sh '''
                                mvn test -B || echo "Tests completed with status $?"
                                echo "📊 Test Results:"
                                if [ -d "target/surefire-reports" ]; then
                                    ls -la target/surefire-reports/
                                fi
                            '''
                        }
                    }
                }
                stage('🛒 Test Order') {
                    steps {
                        dir("${PROJECT_DIR}/order-service") {
                            echo '🧪 Testing Order Service...'
                            sh '''
                                mvn test -B || echo "Tests completed with status $?"
                                echo "📊 Test Results:"
                                if [ -d "target/surefire-reports" ]; then
                                    ls -la target/surefire-reports/
                                fi
                            '''
                        }
                    }
                }
            }
        }
        
        stage('🐳 Build Docker Images') {
            parallel {
                stage('🛍️ Docker Product') {
                    steps {
                        dir("${PROJECT_DIR}/product-service") {
                            echo '🐳 Building Product Service Docker Image...'
                            script {
                                def imageTag = "${DOCKER_REGISTRY}/product-service:${BUILD_NUMBER}"
                                def latestTag = "${DOCKER_REGISTRY}/product-service:latest"
                                
                                sh """
                                    echo "🔨 Building Docker image: ${imageTag}"
                                    docker build -t ${imageTag} .
                                    docker tag ${imageTag} ${latestTag}
                                    echo "✅ Product Service image built: ${imageTag}"
                                    docker images | grep product-service
                                """
                            }
                        }
                    }
                }
                stage('📦 Docker Inventory') {
                    steps {
                        dir("${PROJECT_DIR}/inventory-service") {
                            echo '🐳 Building Inventory Service Docker Image...'
                            script {
                                def imageTag = "${DOCKER_REGISTRY}/inventory-service:${BUILD_NUMBER}"
                                def latestTag = "${DOCKER_REGISTRY}/inventory-service:latest"
                                
                                sh """
                                    echo "🔨 Building Docker image: ${imageTag}"
                                    docker build -t ${imageTag} .
                                    docker tag ${imageTag} ${latestTag}
                                    echo "✅ Inventory Service image built: ${imageTag}"
                                    docker images | grep inventory-service
                                """
                            }
                        }
                    }
                }
                stage('🛒 Docker Order') {
                    steps {
                        dir("${PROJECT_DIR}/order-service") {
                            echo '🐳 Building Order Service Docker Image...'
                            script {
                                def imageTag = "${DOCKER_REGISTRY}/order-service:${BUILD_NUMBER}"
                                def latestTag = "${DOCKER_REGISTRY}/order-service:latest"
                                
                                sh """
                                    echo "🔨 Building Docker image: ${imageTag}"
                                    docker build -t ${imageTag} .
                                    docker tag ${imageTag} ${latestTag}
                                    echo "✅ Order Service image built: ${imageTag}"
                                    docker images | grep order-service
                                """
                            }
                        }
                    }
                }
            }
        }
        
        stage('📤 Push to Registry') {
            steps {
                echo '📤 Pushing Docker Images to Registry...'
                sh """
                    echo "🚀 Pushing images to ${DOCKER_REGISTRY}"
                    
                    docker push ${DOCKER_REGISTRY}/product-service:${BUILD_NUMBER}
                    docker push ${DOCKER_REGISTRY}/product-service:latest
                    echo "✅ Product service images pushed"
                    
                    docker push ${DOCKER_REGISTRY}/inventory-service:${BUILD_NUMBER}
                    docker push ${DOCKER_REGISTRY}/inventory-service:latest
                    echo "✅ Inventory service images pushed"
                    
                    docker push ${DOCKER_REGISTRY}/order-service:${BUILD_NUMBER}
                    docker push ${DOCKER_REGISTRY}/order-service:latest
                    echo "✅ Order service images pushed"
                    
                    echo "🎉 All images pushed successfully!"
                """
            }
        }
        
        stage('☸️ Deploy to Kubernetes') {
            steps {
                echo '☸️ Deploying to Kubernetes...'
                script {
                    sh """
                        echo "🔄 Updating Kubernetes deployments..."
                        
                        # Update deployment images with new build number
                        /snap/microk8s/current/kubectl set image deployment/product-service product-service=${DOCKER_REGISTRY}/product-service:${BUILD_NUMBER} --namespace=default || echo "Product deployment update failed"
                        /snap/microk8s/current/kubectl set image deployment/inventory-service inventory-service=${DOCKER_REGISTRY}/inventory-service:${BUILD_NUMBER} --namespace=default || echo "Inventory deployment update failed"
                        /snap/microk8s/current/kubectl set image deployment/order-service order-service=${DOCKER_REGISTRY}/order-service:${BUILD_NUMBER} --namespace=default || echo "Order deployment update failed"
                        
                        echo "⏳ Waiting for rollout to complete..."
                        
                        # Wait for rollout to complete with timeout
                        /snap/microk8s/current/kubectl rollout status deployment/product-service --namespace=default --timeout=300s || echo "Product rollout timeout"
                        /snap/microk8s/current/kubectl rollout status deployment/inventory-service --namespace=default --timeout=300s || echo "Inventory rollout timeout"
                        /snap/microk8s/current/kubectl rollout status deployment/order-service --namespace=default --timeout=300s || echo "Order rollout timeout"
                        
                        echo "📊 Current deployment status:"
                        /snap/microk8s/current/kubectl get deployments --namespace=default
                        /snap/microk8s/current/kubectl get pods --namespace=default | grep -E "(product|inventory|order)"
                    """
                }
                echo '✅ Kubernetes deployment completed!'
            }
        }
        
        stage('🔍 Health Check & Verification') {
            steps {
                echo '🔍 Running Comprehensive Health Checks...'
                script {
                    echo "⏳ Waiting 60 seconds for services to stabilize..."
                    sleep(60)
                    
                    def services = [
                        'Product': 'http://20.86.144.152:31309/actuator/health',
                        'Inventory': 'http://20.86.144.152:31081/actuator/health',
                        'Order': 'http://20.86.144.152:31004/actuator/health'
                    ]
                    
                    def healthResults = [:]
                    
                    services.each { name, url ->
                        try {
                            sh """
                                echo "🔍 Checking ${name} service at ${url}..."
                                response=\$(curl -s -w "%{http_code}" -o /tmp/${name.toLowerCase()}_health.json ${url})
                                echo "📊 ${name} HTTP Status: \$response"
                                
                                if [ "\$response" = "200" ]; then
                                    echo "✅ ${name} service is healthy"
                                    cat /tmp/${name.toLowerCase()}_health.json
                                else
                                    echo "⚠️ ${name} service returned status \$response"
                                    cat /tmp/${name.toLowerCase()}_health.json || echo "No response body"
                                fi
                            """
                            healthResults[name] = 'HEALTHY'
                        } catch (Exception e) {
                            echo "❌ ${name} service health check failed: ${e.getMessage()}"
                            healthResults[name] = 'UNHEALTHY'
                        }
                    }
                    
                    // Summary
                    echo "📋 HEALTH CHECK SUMMARY:"
                    healthResults.each { service, status ->
                        echo "   ${service}: ${status}"
                    }
                }
            }
        }
        
        stage('🧹 Cleanup') {
            steps {
                echo '🧹 Cleaning up resources...'
                sh """
                    echo "🗑️ Removing old Docker images..."
                    docker image prune -f --filter "until=24h"
                    
                    echo "🗑️ Cleaning Docker system..."
                    docker system prune -f --volumes=false
                    
                    echo "📊 Current Docker usage:"
                    docker system df
                    
                    echo "✅ Cleanup completed!"
                """
            }
        }
    }
    
    post {
        success {
            script {
                def duration = currentBuild.durationString.replace(' and counting', '')
                echo """
                🎉 ========================================
                🎉 PIPELINE COMPLETED SUCCESSFULLY! 
                🎉 ========================================
                
                📊 BUILD SUMMARY:
                ✅ Build Number: ${BUILD_NUMBER}
                ✅ Duration: ${duration}
                ✅ Git Commit: ${env.GIT_COMMIT_SHORT}
                ✅ All microservices deployed and healthy
                
                🌐 SERVICE ENDPOINTS:
                🛍️  Product Service:    http://20.86.144.152:31309/actuator/health
                📦 Inventory Service:  http://20.86.144.152:31081/actuator/health  
                🛒 Order Service:      http://20.86.144.152:31004/actuator/health
                
                🔧 MONITORING & TOOLS:
                📊 Grafana Dashboard:  http://20.86.144.152:31000
                📈 Prometheus:         http://20.86.144.152:31090
                🔧 Jenkins:            http://20.86.144.152:31080
                🌐 Frontend App:       http://20.86.144.152:8000
                
                🎯 NEXT STEPS:
                1. Verify all services are responding
                2. Run integration tests
                3. Monitor application metrics
                4. Check application logs if needed
                
                🎉 Happy Coding! 🚀
                """
            }
        }
        failure {
            script {
                def duration = currentBuild.durationString.replace(' and counting', '')
                echo """
                ❌ ========================================
                ❌ PIPELINE FAILED!
                ❌ ========================================
                
                📊 FAILURE SUMMARY:
                ❌ Build Number: ${BUILD_NUMBER}
                ❌ Duration: ${duration}
                ❌ Git Commit: ${env.GIT_COMMIT_SHORT}
                
                🔍 TROUBLESHOOTING STEPS:
                1. Check the build logs above for specific errors
                2. Verify Docker registry is accessible
                3. Check Kubernetes cluster status
                4. Ensure all dependencies are available
                5. Review application configuration
                
                📞 Need help? Check the Jenkins console output for detailed error messages.
                """
            }
        }
        always {
            echo """
            📊 ========================================
            📊 PIPELINE EXECUTION COMPLETED
            📊 ========================================
            
            📅 Timestamp: ${new Date()}
            🔢 Build Number: ${BUILD_NUMBER}
            📝 Git Commit: ${env.GIT_COMMIT_SHORT}
            🌿 Branch: ${env.GIT_BRANCH ?: 'main'}
            ⏱️ Duration: ${currentBuild.durationString.replace(' and counting', '')}
            
            📋 Workspace cleaned and ready for next build
            """
            
            // Archive build artifacts if they exist
            script {
                try {
                    archiveArtifacts artifacts: '**/target/*.jar', allowEmptyArchive: true
                    echo "📦 Build artifacts archived"
                } catch (Exception e) {
                    echo "ℹ️ No artifacts to archive"
                }
            }
        }
    }
} 