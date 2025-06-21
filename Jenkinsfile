pipeline {
    agent any

    environment {
        DOCKER_HUB_CREDS = credentials('docker-hub-credentials')
        DOCKER_IMAGE = 'niroth36/simpleeshop'
        WELCOME_EMAIL_IMAGE = 'niroth36/welcome-email'
        ORDER_EMAIL_IMAGE = 'niroth36/order-confirmation-email'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Images') {
            parallel {
                stage('Build Main App') {
                    steps {
                        sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                        sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
                    }
                }

                stage('Build Welcome Email Service') {
                    steps {
                        dir('web-app/server/email-services/welcome-email') {
                            sh "docker build -t ${WELCOME_EMAIL_IMAGE}:${DOCKER_TAG} -f Dockerfile.k8s ."
                            sh "docker tag ${WELCOME_EMAIL_IMAGE}:${DOCKER_TAG} ${WELCOME_EMAIL_IMAGE}:latest"
                        }
                    }
                }

                stage('Build Order Confirmation Email Service') {
                    steps {
                        dir('web-app/server/email-services/order-confirmation-email') {
                            sh "docker build -t ${ORDER_EMAIL_IMAGE}:${DOCKER_TAG} -f Dockerfile.k8s ."
                            sh "docker tag ${ORDER_EMAIL_IMAGE}:${DOCKER_TAG} ${ORDER_EMAIL_IMAGE}:latest"
                        }
                    }
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                sh "echo ${DOCKER_HUB_CREDS_PSW} | docker login -u ${DOCKER_HUB_CREDS_USR} --password-stdin"

                // Push main app image
                sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                sh "docker push ${DOCKER_IMAGE}:latest"

                // Push email service images
                sh "docker push ${WELCOME_EMAIL_IMAGE}:${DOCKER_TAG}"
                sh "docker push ${WELCOME_EMAIL_IMAGE}:latest"
                sh "docker push ${ORDER_EMAIL_IMAGE}:${DOCKER_TAG}"
                sh "docker push ${ORDER_EMAIL_IMAGE}:latest"
            }
        }

        stage('Update Kubernetes Manifests') {
            steps {
                script {
                    // Clone the GitOps repository
                    sh "git clone https://github.com/Niroth36/SimpleEshop-gitops.git"

                    // Update the image tags in the deployment manifests
                    dir('SimpleEshop-gitops') {
                        // Update main app image
                        sh "sed -i 's|image: ${DOCKER_IMAGE}:.*|image: ${DOCKER_IMAGE}:${DOCKER_TAG}|' kubernetes/applications/simpleeshop-deployment.yaml"

                        // Update welcome email service image
                        sh "sed -i 's|image: ${WELCOME_EMAIL_IMAGE}:.*|image: ${WELCOME_EMAIL_IMAGE}:${DOCKER_TAG}|' kubernetes/email-services/welcome-email-deployment.yaml"

                        // Update order confirmation email service image
                        sh "sed -i 's|image: ${ORDER_EMAIL_IMAGE}:.*|image: ${ORDER_EMAIL_IMAGE}:${DOCKER_TAG}|' kubernetes/email-services/order-confirmation-email-deployment.yaml"

                        // Commit and push the changes
                        sh "git config user.email 'jenkins@example.com'"
                        sh "git config user.name 'Jenkins CI'"
                        sh "git add kubernetes/applications/simpleeshop-deployment.yaml"
                        sh "git add kubernetes/email-services/welcome-email-deployment.yaml"
                        sh "git add kubernetes/email-services/order-confirmation-email-deployment.yaml"
                        sh "git commit -m 'Update image tags to ${DOCKER_TAG}'"

                        withCredentials([usernamePassword(credentialsId: 'github-credentials', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
                            sh "git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/Niroth36/SimpleEshop-gitops.git main"
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            sh "docker logout"
            cleanWs()
        }
    }
}
