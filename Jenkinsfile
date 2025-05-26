pipeline {
    agent {
        docker {
            image 'maven:3.9.6-eclipse-temurin-17'
            args '-v /var/jenkins_home/.m2:/root/.m2'
        }
    }

    environment {
        DOCKER_REGISTRY = 'localhost:32000'
        KUBECONFIG = '/var/jenkins_home/.kube/config'
        GIT_REPO = 'https://github.com/ettomarett/hamlaoui-devops.git'
        PROJECT_DIR = 'hamlaoui-devops'
    }

    stages {
        stage('🚀 Pipeline Start') {
            steps {
                echo '🎯 STARTING E-COMMERCE MICROSERVICES CI/CD PIPELINE'
                echo "📅 Build Date: ${new Date()}"
                echo "🔢 Build Number: ${BUILD_NUMBER}"
                echo "🌿 Branch: ${env.GIT_BRANCH ?: 'main'}"

                cleanWs()
                checkout scm

                script {
                    env.GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                }

                echo "📝 Commit: ${env.GIT_COMMIT_SHORT}"
            }
        }

        stage('📦 Build Microservices') {
            parallel {
                stage('🛍️ Product Service') {
                    steps {
                        dir("${PROJECT_DIR}/product-service") {
                            sh 'mvn clean compile package -DskipTests -B'
                        }
                    }
                }
                stage('📦 Inventory Service') {
                    steps {
                        dir("${PROJECT_DIR}/inventory-service") {
                            sh 'mvn clean compile package -DskipTests -B'
                        }
                    }
                }
                stage('🛒 Order Service') {
                    steps {
                        dir("${PROJECT_DIR}/order-service") {
                            sh 'mvn clean compile package -DskipTests -B'
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
                            sh 'mvn test -B'
                        }
                    }
                }
                stage('📦 Test Inventory') {
                    steps {
                        dir("${PROJECT_DIR}/inventory-service") {
                            sh 'mvn test -B'
                        }
                    }
                }
                stage('🛒 Test Order') {
                    steps {
                        dir("${PROJECT_DIR}/order-service") {
                            sh 'mvn test -B'
                        }
                    }
                }
            }
        }
    }
}
