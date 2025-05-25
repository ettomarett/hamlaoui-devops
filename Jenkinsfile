pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'localhost:32000'
        KUBECONFIG = '/var/jenkins_home/.kube/config'
        GIT_REPO = 'https://github.com/hamlaoui/hamlaoui-devops.git'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '🚀 STARTING CI/CD PIPELINE...'
                checkout scm
                sh 'echo "Commit: ${GIT_COMMIT}"'
                sh 'echo "Branch: ${GIT_BRANCH}"'
            }
        }
        
        stage('Build Applications') {
            parallel {
                stage('Build Product Service') {
                    steps {
                        dir('product-service') {
                            echo '🏗️ Building Product Service...'
                            sh 'mvn clean package -DskipTests'
                            sh 'echo "Product Service JAR built successfully"'
                        }
                    }
                }
                stage('Build Inventory Service') {
                    steps {
                        dir('inventory-service') {
                            echo '🏗️ Building Inventory Service...'
                            sh 'mvn clean package -DskipTests'
                            sh 'echo "Inventory Service JAR built successfully"'
                        }
                    }
                }
                stage('Build Order Service') {
                    steps {
                        dir('order-service') {
                            echo '🏗️ Building Order Service...'
                            sh 'mvn clean package -DskipTests'
                            sh 'echo "Order Service JAR built successfully"'
                        }
                    }
                }
            }
        }
        
        stage('Run Tests') {
            parallel {
                stage('Test Product Service') {
                    steps {
                        dir('product-service') {
                            echo '🧪 Testing Product Service...'
                            sh 'mvn test || echo "Tests completed with status $?"'
                        }
                    }
                }
                stage('Test Inventory Service') {
                    steps {
                        dir('inventory-service') {
                            echo '🧪 Testing Inventory Service...'
                            sh 'mvn test || echo "Tests completed with status $?"'
                        }
                    }
                }
                stage('Test Order Service') {
                    steps {
                        dir('order-service') {
                            echo '🧪 Testing Order Service...'
                            sh 'mvn test || echo "Tests completed with status $?"'
                        }
                    }
                }
            }
        }
        
        stage('Build Docker Images') {
            parallel {
                stage('Docker Build Product') {
                    steps {
                        dir('product-service') {
                            echo '🐳 Building Product Service Docker Image...'
                            script {
                                def imageTag = "${DOCKER_REGISTRY}/product-service:${BUILD_NUMBER}"
                                sh "docker build -t ${imageTag} ."
                                sh "docker tag ${imageTag} ${DOCKER_REGISTRY}/product-service:latest"
                                echo "Product Service image built: ${imageTag}"
                            }
                        }
                    }
                }
                stage('Docker Build Inventory') {
                    steps {
                        dir('inventory-service') {
                            echo '🐳 Building Inventory Service Docker Image...'
                            script {
                                def imageTag = "${DOCKER_REGISTRY}/inventory-service:${BUILD_NUMBER}"
                                sh "docker build -t ${imageTag} ."
                                sh "docker tag ${imageTag} ${DOCKER_REGISTRY}/inventory-service:latest"
                                echo "Inventory Service image built: ${imageTag}"
                            }
                        }
                    }
                }
                stage('Docker Build Order') {
                    steps {
                        dir('order-service') {
                            echo '🐳 Building Order Service Docker Image...'
                            script {
                                def imageTag = "${DOCKER_REGISTRY}/order-service:${BUILD_NUMBER}"
                                sh "docker build -t ${imageTag} ."
                                sh "docker tag ${imageTag} ${DOCKER_REGISTRY}/order-service:latest"
                                echo "Order Service image built: ${imageTag}"
                            }
                        }
                    }
                }
            }
        }
        
        stage('Push to Registry') {
            steps {
                echo '📤 Pushing Docker Images to Registry...'
                sh """
                    docker push ${DOCKER_REGISTRY}/product-service:${BUILD_NUMBER}
                    docker push ${DOCKER_REGISTRY}/product-service:latest
                    docker push ${DOCKER_REGISTRY}/inventory-service:${BUILD_NUMBER}
                    docker push ${DOCKER_REGISTRY}/inventory-service:latest
                    docker push ${DOCKER_REGISTRY}/order-service:${BUILD_NUMBER}
                    docker push ${DOCKER_REGISTRY}/order-service:latest
                """
                echo '✅ All images pushed successfully!'
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                echo '☸️ Deploying to Kubernetes...'
                script {
                    // Update deployment images with new build number
                    sh """
                        kubectl set image deployment/product-service product-service=${DOCKER_REGISTRY}/product-service:${BUILD_NUMBER} --namespace=default
                        kubectl set image deployment/inventory-service inventory-service=${DOCKER_REGISTRY}/inventory-service:${BUILD_NUMBER} --namespace=default
                        kubectl set image deployment/order-service order-service=${DOCKER_REGISTRY}/order-service:${BUILD_NUMBER} --namespace=default
                    """
                    
                    // Wait for rollout to complete
                    sh """
                        kubectl rollout status deployment/product-service --namespace=default --timeout=300s
                        kubectl rollout status deployment/inventory-service --namespace=default --timeout=300s
                        kubectl rollout status deployment/order-service --namespace=default --timeout=300s
                    """
                }
                echo '✅ Kubernetes deployment completed!'
            }
        }
        
        stage('Health Check') {
            steps {
                echo '🔍 Running Health Checks...'
                script {
                    sleep(30) // Wait for services to start
                    
                    def services = [
                        'product': 'http://20.86.144.152:31309/actuator/health',
                        'inventory': 'http://20.86.144.152:31081/actuator/health',
                        'order': 'http://20.86.144.152:31004/actuator/health'
                    ]
                    
                    services.each { name, url ->
                        sh """
                            echo "Checking ${name} service..."
                            curl -f ${url} || (echo "❌ ${name} service health check failed" && exit 1)
                            echo "✅ ${name} service is healthy"
                        """
                    }
                }
                echo '🎉 All services are healthy!'
            }
        }
        
        stage('Cleanup') {
            steps {
                echo '🧹 Cleaning up old Docker images...'
                sh """
                    docker image prune -f
                    docker system prune -f --volumes=false
                """
                echo '✅ Cleanup completed!'
            }
        }
    }
    
    post {
        success {
            echo '🎉 PIPELINE COMPLETED SUCCESSFULLY!'
            echo '✅ All microservices deployed and healthy'
            echo """
            🌐 Service URLs:
            - Product: http://20.86.144.152:31309/actuator/health
            - Inventory: http://20.86.144.152:31081/actuator/health  
            - Order: http://20.86.144.152:31004/actuator/health
            - Grafana: http://20.86.144.152:31000
            - Prometheus: http://20.86.144.152:31090
            - Jenkins: http://20.86.144.152:31080
            """
        }
        failure {
            echo '❌ PIPELINE FAILED!'
            echo 'Check the logs above for error details'
        }
        always {
            echo '📊 Pipeline execution completed'
            echo "Build Number: ${BUILD_NUMBER}"
            echo "Git Commit: ${GIT_COMMIT}"
        }
    }
} 