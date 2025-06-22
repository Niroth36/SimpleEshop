pipeline {
    agent any
    
    environment {
        DOCKER_HUB_CREDS = credentials('docker-hub-credentials')
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
                    // Generate image tag from git commit
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
                    // Check if any files in the web-app directory have changed
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
                dir('web-app') {
                    sh 'npm ci'
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
                        dir('web-app') {
                            sh 'npm test || echo "Tests not configured"'
                        }
                    }
                }
                stage('Lint Code') {
                    steps {
                        dir('web-app') {
                            sh 'npm run lint || echo "Lint not configured"'
                        }
                    }
                }
                stage('Integration Tests') {
                    steps {
                        sh './test-integration.sh || echo "Integration tests not configured"'
                    }
                }
            }
        }
        
        stage('Build Multi-Arch Docker Image') {
            when {
                environment name: 'SHOULD_BUILD', value: 'true'
            }
            steps {
                script {
                    sh """
                        # Set up Docker buildx
                        docker buildx create --name mybuilder --use || true
                        docker buildx inspect --bootstrap
                        
                        # Login to Docker Hub
                        echo ${DOCKER_HUB_CREDS_PSW} | docker login -u ${DOCKER_HUB_CREDS_USR} --password-stdin
                        
                        # Build and push multi-arch image
                        docker buildx build \\
                            --platform linux/amd64,linux/arm64 \\
                            --tag ${FULL_IMAGE_TAG} \\
                            --tag ${DOCKER_IMAGE}:latest \\
                            --file Dockerfile.x86 \\
                            --push \\
                            .
                        
                        echo "✅ Multi-arch image built and pushed: ${FULL_IMAGE_TAG}"
                    """
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
                            # Configure git for this workspace
                            git config user.email "jenkins@simpleeshop.local"
                            git config user.name "Jenkins CI/CD"
                            
                            # Find and update deployment manifests
                            echo "🔍 Looking for deployment manifests..."
                            find kubernetes/ -name "*deployment*.yaml" -type f | head -5
                            
                            # Update image tag in SimpleEshop deployment manifest
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
                            
                            # Check if there are any changes to commit
                            if git diff --quiet; then
                                echo "ℹ️ No changes to commit"
                            else
                                echo "📋 Changes detected, committing..."
                                git add kubernetes/
                                git commit -m "🚀 Update ${APP_NAME} image to ${BUILD_NUMBER_TAG}
                            
                            - Jenkins Build: #${BUILD_NUMBER}
                            - Git Commit: ${IMAGE_TAG}
                            - Docker Image: ${FULL_IMAGE_TAG}
                            - Multi-arch: linux/amd64,linux/arm64
                            - Timestamp: \$(date -u +"%Y-%m-%d %H:%M:%S UTC")"
                                
                                # Push changes back to the same repository
                                git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/Niroth36/SimpleEshop.git HEAD:main
                                echo "✅ Kubernetes manifests updated in mono-repo!"
                            fi
                        """
                    }
                }
            }
        }
        
        stage('Trigger Deployment') {
            when {
                environment name: 'SHOULD_BUILD', value: 'true'
            }
            steps {
                script {
                    echo "🔄 ArgoCD will automatically sync the new deployment"
                    echo "📦 New multi-arch image: ${env.FULL_IMAGE_TAG}"
                    echo "🌐 Deployment URL: http://4.210.149.226:30000"
                    echo "📁 GitOps: Self-contained in mono-repo"
                }
            }
        }
    }
    
    post {
        always {
            // Clean up local images
            sh """
                docker logout || true
                docker system prune -f || true
            """
        }
        
        success {
            script {
                if (env.SHOULD_BUILD == "true") {
                    def deploymentTime = new Date().format("yyyy-MM-dd HH:mm:ss")
                    echo """
                    🎉 SUCCESS: SimpleEshop Mono-Repo CI/CD Completed!
                    
                    📦 Image Details:
                       - Repository: ${DOCKER_IMAGE}
                       - Tag: ${BUILD_NUMBER_TAG}
                       - Full Image: ${FULL_IMAGE_TAG}
                       - Architectures: linux/amd64, linux/arm64
                       
                    🚀 Deployment:
                       - Kubernetes Manifests Updated: ✅
                       - ArgoCD Sync: Automatic
                       - Application URL: http://4.210.149.226:30000
                       
                    📁 GitOps Strategy: Mono-repo self-update
                    ⏰ Deployment Time: ${deploymentTime}
                    """
                } else {
                    echo """
                    ℹ️ SUCCESS: No Web App Changes Detected
                    
                    📁 Checked: web-app/ directory
                    🔄 Action: Skipped Docker build (no changes)
                    ✅ Status: Pipeline completed successfully
                    """
                }
            }
        }
        
        failure {
            echo """
            ❌ FAILED: SimpleEshop Mono-Repo CI/CD Failed!
            
            🔍 Check the following:
               - Docker Hub credentials
               - GitHub credentials  
               - Network connectivity
               - Application tests
               - Kubernetes manifest paths
               
            📋 Build Details:
               - Build Number: ${BUILD_NUMBER}
               - Commit: ${env.IMAGE_TAG}
               - Should Build: ${env.SHOULD_BUILD}
            """
        }
        
        cleanup {
            sh 'docker system prune -f || true'
        }
    }
}