pipeline {
    agent {
        docker {
            image 'maven:3.9.4-eclipse-temurin-17'
            args '-v /root/.m2:/root/.m2'
        }
    }

    environment {
        REGISTRY = 'your-docker-registry-url'
        BRANCH_NAME = "${env.GIT_BRANCH ?: 'main'}"
    }

    stages {
        stage('🚀 Pipeline Start') {
            steps {
                echo '🎯 STARTING E-COMMERCE MICROSERVICES CI/CD PIPELINE'
                echo "📅 Build Date: ${new Date()}"
                echo "🔢 Build Number: ${env.BUILD_NUMBER}"
                echo "🌿 Branch: ${BRANCH_NAME}"
                cleanWs()
                script {
                    def shortCommit = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    echo "📝 Commit: ${shortCommit}"
                }
            }
        }

        stage('🔧 Setup Build Environment') {
            steps {
                echo '🔧 Using pre-installed Maven in Docker image'
            }
        }

        stage('📦 Build Microservices') {
            parallel {
                stage('🛍️ Product Service') {
                    steps {
                        dir('product-service') {
                            sh 'mvn clean install'
                        }
                    }
                }
                stage('📦 Inventory Service') {
                    steps {
                        dir('inventory-service') {
                            sh 'mvn clean install'
                        }
                    }
                }
                stage('🛒 Order Service') {
                    steps {
                        dir('order-service') {
                            sh 'mvn clean install'
                        }
                    }
                }
            }
        }

        stage('🧪 Run Tests') {
            parallel {
                stage('🛍️ Test Product') {
                    steps {
                        dir('product-service') {
                            sh 'mvn test'
                        }
                    }
                }
                stage('📦 Test Inventory') {
                    steps {
                        dir('inventory-service') {
                            sh 'mvn test'
                        }
                    }
                }
                stage('🛒 Test Order') {
                    steps {
                        dir('order-service') {
                            sh 'mvn test'
                        }
                    }
                }
            }
        }

        stage('🐳 Build Docker Images') {
            parallel {
                stage('🛍️ Docker Product') {
                    steps {
                        dir('product-service') {
                            sh "docker build -t $REGISTRY/product-service ."
                        }
                    }
                }
                stage('📦 Docker Inventory') {
                    steps {
                        dir('inventory-service') {
                            sh "docker build -t $REGISTRY/inventory-service ."
                        }
                    }
                }
                stage('🛒 Docker Order') {
                    steps {
                        dir('order-service') {
                            sh "docker build -t $REGISTRY/order-service ."
                        }
                    }
                }
            }
        }

        stage('📤 Push to Registry') {
            steps {
                sh '''
                    docker push $REGISTRY/product-service
                    docker push $REGISTRY/inventory-service
                    docker push $REGISTRY/order-service
                '''
            }
        }

        stage('☸️ Deploy to Kubernetes') {
            steps {
                echo '🚀 Deploying services to Kubernetes cluster...'
                // Add kubectl commands here if applicable
            }
        }

        stage('🔍 Health Check & Verification') {
            steps {
                echo '🩺 Performing health checks...'
                // Add HTTP health checks if needed
            }
        }

        stage('🧹 Cleanup') {
            steps {
                cleanWs()
            }
        }
    }

    post {
        success {
            echo '''
                ✅ ========================================
                ✅ PIPELINE SUCCESSFUL!
                ✅ ========================================
            '''
        }
        failure {
            echo '''
                ❌ ========================================
                ❌ PIPELINE FAILED!
                ❌ ========================================

                📋 FAILURE SUMMARY:
                🔍 Check build logs above
                🔧 Verify environment, tools, configs
            '''
        }
    }
}
