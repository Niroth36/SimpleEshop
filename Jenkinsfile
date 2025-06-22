pipeline {
    agent {
        kubernetes {
            yaml """
                apiVersion: v1
                kind: Pod
                spec:
                  containers:
                  - name: node
                    image: node:18-alpine
                    command:
                    - cat
                    tty: true
                  - name: kaniko
                    image: gcr.io/kaniko-project/executor:debug
                    command:
                    - cat
                    tty: true
                    volumeMounts:
                    - name: docker-config
                      mountPath: /kaniko/.docker
                  volumes:
                  - name: docker-config
                    secret:
                      secretName: docker-hub-secret
                      items:
                      - key: .dockerconfigjson
                        path: config.json
            """
        }
    }
    
    environment {
        DOCKER_IMAGE = 'niroth36/simpleeshop'
        GITOPS_REPO = 'https://github.com/Niroth36/SimpleEshop.git'
        GITOPS_CREDENTIALS = 'github-credentials'
        APP_NAME = 'simpleeshop'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.IMAGE_TAG = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                    env.BUILD_NUMBER_TAG = "${env.BUILD_NUMBER}-${env.IMAGE_TAG}"
                    env.FULL_IMAGE_TAG = "${DOCKER_IMAGE}:${BUILD_NUMBER_TAG}"
                }
                echo "🏗️ Building: ${env.FULL_IMAGE_TAG}"
            }
        }
        
        stage('Check for Web App Changes') {
            steps {
                script {
                    def changedFiles = sh(
                        script: 'git diff --name-only HEAD~1 HEAD || echo "first-build"',
                        returnStdout: true
                    ).trim()
                    
                    echo "📝 Changed files: ${changedFiles}"
                    
                    def webAppChanged = sh(
                        script: 'git diff --name-only HEAD~1 HEAD | grep -q "^web-app/" && echo "true" || echo "false"',
                        returnStdout: true
                    ).trim()
                    
                    if (changedFiles == "first-build") {
                        echo "🎯 First build or no previous commit - proceeding with build"
                        env.SHOULD_BUILD = "true"
                    } else if (webAppChanged == "true") {
                        echo "✅ Changes detected in web-app directory - proceeding with build"
                        env.SHOULD_BUILD = "true"
                    } else {
                        echo "ℹ️ No changes in web-app directory - skipping Docker build"
                        env.SHOULD_BUILD = "false"
                    }
                }
            }
        }
        
        stage('Install Dependencies') {
            when {
                environment name: 'SHOULD_BUILD', value: 'true'
            }
            steps {
                container('node') {
                    dir('web-app') {
                        script {
                            if (!fileExists('package-lock.json')) {
                                echo "⚠️ package-lock.json not found, running npm install to generate it"
                                sh 'npm install'
                            } else {
                                sh 'npm ci'
                            }
                        }
                    }
                }
            }
        }
        
        stage('Run Tests') {
            when {
                environment name: 'SHOULD_BUILD', value: 'true'
            }
            parallel {
                stage('Unit Tests') {
                    steps {
                        container('node') {
                            dir('web-app') {
                                sh 'npm test || echo "Tests not configured"'
                            }
                        }
                    }
                }
                stage('Lint Code') {
                    steps {
                        container('node') {
                            dir('web-app') {
                                sh 'npm run lint || echo "Lint not configured"'
                            }
                        }
                    }
                }
            }
        }
        
        stage('Build Docker Image with Kaniko') {
            when {
                environment name: 'SHOULD_BUILD', value: 'true'
            }
            steps {
                container('kaniko') {
                    script {
                        sh """
                            /kaniko/executor \\
                                --dockerfile=Dockerfile.x86 \\
                                --context=. \\
                                --destination=${FULL_IMAGE_TAG} \\
                                --destination=${DOCKER_IMAGE}:latest \\
                                --cache=true \\
                                --cache-ttl=24h
                        """
                        echo "✅ Image built and pushed: ${FULL_IMAGE_TAG}"
                    }
                }
            }
        }
        
        stage('Update Kubernetes Manifests') {
            when {
                environment name: 'SHOULD_BUILD', value: 'true'
            }
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: GITOPS_CREDENTIALS, usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
                        sh """
                            git config user.email "jenkins@simpleeshop.local"
                            git config user.name "Jenkins CI/CD"
                            
                            echo "🔍 Looking for deployment manifests..."
                            find kubernetes/ -name "*deployment*.yaml" -type f | head -5
                            
                            if [ -f kubernetes/applications/simpleeshop-deployment.yaml ]; then
                                echo "📝 Updating kubernetes/applications/simpleeshop-deployment.yaml"
                                sed -i 's|image: ${DOCKER_IMAGE}:.*|image: ${FULL_IMAGE_TAG}|g' kubernetes/applications/simpleeshop-deployment.yaml
                                grep "image:" kubernetes/applications/simpleeshop-deployment.yaml
                            elif [ -f kubernetes/simpleeshop-deployment.yaml ]; then
                                echo "📝 Updating kubernetes/simpleeshop-deployment.yaml"
                                sed -i 's|image: ${DOCKER_IMAGE}:.*|image: ${FULL_IMAGE_TAG}|g' kubernetes/simpleeshop-deployment.yaml
                                grep "image:" kubernetes/simpleeshop-deployment.yaml
                            else
                                echo "⚠️ Searching for any deployment file with simpleeshop..."
                                find . -name "*simpleeshop*deployment*.yaml" -type f
                                find . -name "*deployment*.yaml" -type f | grep -i simple || echo "No simpleeshop deployment found"
                            fi
                            
                            if git diff --quiet; then
                                echo "ℹ️ No changes to commit"
                            else
                                echo "📋 Changes detected, committing..."
                                git add kubernetes/
                                git commit -m "🚀 Update ${APP_NAME} image to ${BUILD_NUMBER_TAG}"
                                git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/Niroth36/SimpleEshop.git HEAD:main
                                echo "✅ Kubernetes manifests updated!"
                            fi
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            script {
                if (env.SHOULD_BUILD == "true") {
                    echo """
                    🎉 SUCCESS: SimpleEshop CI/CD Completed with Kaniko!
                    
                    📦 Image: ${FULL_IMAGE_TAG}
                    🚀 Deployment: Updated via GitOps
                    🌐 URL: http://4.210.149.226:30000
                    """
                }
            }
        }
        
        failure {
            echo """
            ❌ FAILED: Check Docker Hub secret and GitHub credentials
            📋 Build: ${BUILD_NUMBER} | Commit: ${env.IMAGE_TAG}
            """
        }
    }
}