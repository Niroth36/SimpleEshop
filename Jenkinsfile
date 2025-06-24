pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'niroth36/simpleeshop'
        DOCKER_TAG = "${BUILD_NUMBER}"
        DOCKERFILE_PATH = 'Dockerfile.x86'
        CONTROL_PLANE_IP = '4.210.149.226'
        // Flag to track if this is a manual build
        MANUAL_TRIGGER = "${currentBuild.getBuildCauses().toString().contains('UserIdCause') ? 'true' : 'false'}"
    }


    stages {
        stage('Clone Repository') {
            steps {
                script {
                    deleteDir()
                    git credentialsId: 'github-token', 
                        url: 'https://github.com/Niroth36/SimpleEshop.git',
                        branch: 'master'
                    sh 'ls -la Dockerfile.x86'
                }
            }
        }

        stage('Check for Web-App Changes') {
            steps {
                script {
                    // Get the previous successful commit
                    def previousSuccessfulCommit = ""
                    def lastSuccessfulBuild = currentBuild.previousSuccessfulBuild
                    if (lastSuccessfulBuild) {
                        // Use a safer approach to get the previous commit
                        try {
                            // Get the current commit
                            def currentCommit = sh(script: "git rev-parse HEAD", returnStdout: true).trim()
                            echo "Current commit: ${currentCommit}"

                            // Use the build number to get the previous commit
                            def previousBuildNumber = lastSuccessfulBuild.number
                            echo "Previous successful build number: ${previousBuildNumber}"

                            // Assume the first commit in the log is the one we want
                            previousSuccessfulCommit = sh(script: "git log --format='%H' -n 1 HEAD~1", returnStdout: true).trim()
                            echo "Previous successful commit: ${previousSuccessfulCommit}"
                        } catch (Exception e) {
                            echo "Error getting previous commit: ${e.message}"
                            // If there's an error, assume there are changes
                            previousSuccessfulCommit = ""
                        }
                    }

                    // CONDITION 1: Check if there are changes in the web-app directory
                    if (previousSuccessfulCommit) {
                        // Check if there are changes in the web-app directory
                        def changes = sh(script: "git diff --name-only ${previousSuccessfulCommit} HEAD | grep -q '^web-app/' || echo 'no_changes'", returnStdout: true).trim()
                        env.WEBAPP_CHANGES = changes != 'no_changes' ? 'true' : 'false'
                    } else {
                        // If no previous successful build, assume changes
                        env.WEBAPP_CHANGES = 'true'
                    }

                    // CONDITION 2: Check if the build was manually triggered using the build button
                    // This is set in the environment section: MANUAL_TRIGGER

                    echo "CONDITION 1 - Web-app changes detected: ${env.WEBAPP_CHANGES}"
                    echo "CONDITION 2 - Manual trigger: ${env.MANUAL_TRIGGER}"

                    // Set a flag to determine if we should proceed with the build
                    // The build will proceed if EITHER condition is true
                    env.SHOULD_BUILD = (env.WEBAPP_CHANGES == 'true' || env.MANUAL_TRIGGER == 'true') ? 'true' : 'false'

                    if (env.SHOULD_BUILD == 'true') {
                        echo "🚀 Build will proceed due to either:"
                        echo "   - CONDITION 1: Changes detected in web-app directory, or"
                        echo "   - CONDITION 2: Manually triggered using the build button"
                    } else {
                        echo "⏭️ No web-app changes detected and not manually triggered, skipping build"
                    }
                }
            }
        }

        stage('Install SSH Client') {
            when {
                expression { return env.SHOULD_BUILD == 'true' }
            }
            steps {
                script {
                    sh """
                        apt-get update
                        apt-get install -y openssh-client
                    """
                }
            }
        }

        stage('Build on Control Plane') {
            when {
                expression { return env.SHOULD_BUILD == 'true' }
            }
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'control-plane-credentials', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                        sh """
                            # Set up SSH key
                            mkdir -p ~/.ssh
                            cp \${SSH_KEY} ~/.ssh/id_rsa
                            chmod 600 ~/.ssh/id_rsa
                            ssh-keyscan -H ${CONTROL_PLANE_IP} >> ~/.ssh/known_hosts

                            # SSH to control plane and build
                            ssh -i ~/.ssh/id_rsa \${SSH_USER}@${CONTROL_PLANE_IP} '
                                echo "🏗️ Starting build on control plane..."

                                # Clean up any previous build
                                rm -rf /tmp/simpleeshop-build-${BUILD_NUMBER}
                                mkdir -p /tmp/simpleeshop-build-${BUILD_NUMBER}
                                cd /tmp/simpleeshop-build-${BUILD_NUMBER}

                                # Clone the repository
                                echo "📥 Cloning repository..."
                                git clone https://github.com/Niroth36/SimpleEshop.git .

                                # Verify Dockerfile exists
                                ls -la ${DOCKERFILE_PATH}

                                # Build the Docker image
                                echo "🐳 Building Docker image..."
                                docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} -f ${DOCKERFILE_PATH} .
                                docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest

                                # List the built image
                                echo "✅ Built images:"
                                docker images | grep ${DOCKER_IMAGE}
                            '
                        """
                    }
                }
            }
        }

        stage('Push to Docker Hub') {
            when {
                expression { return env.SHOULD_BUILD == 'true' }
            }
            steps {
                script {
                    withCredentials([
                        usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS'),
                        sshUserPrivateKey(credentialsId: 'control-plane-credentials', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')
                    ]) {
                        sh """
                            ssh -i ~/.ssh/id_rsa \${SSH_USER}@${CONTROL_PLANE_IP} '
                                echo "🚀 Pushing to Docker Hub..."

                                # Login to Docker Hub
                                echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin

                                # Push the images
                                docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                                docker push ${DOCKER_IMAGE}:latest

                                echo "✅ Successfully pushed images to Docker Hub"

                                # Logout for security
                                docker logout
                            '
                        """
                    }
                }
            }
        }

        stage('Update Kubernetes Manifest') {
            when {
                expression { return env.SHOULD_BUILD == 'true' }
            }
            steps {
                script {
                    // Update the image tag in the Kubernetes deployment YAML file
                    sh """
                        # Update the image tag in the deployment file
                        sed -i 's|image: ${DOCKER_IMAGE}:.*|image: ${DOCKER_IMAGE}:${DOCKER_TAG}|' kubernetes/applications/simpleeshop-deployment.yaml

                        # Show the changes
                        echo "📄 Updated deployment manifest:"
                        cat kubernetes/applications/simpleeshop-deployment.yaml | grep image:
                    """

                    // Commit and push the changes
                    withCredentials([usernamePassword(credentialsId: 'github-token', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
                        sh """
                            # Configure Git
                            git config user.email "jenkins@example.com"
                            git config user.name "Jenkins CI"

                            # Add, commit and push changes
                            git add kubernetes/applications/simpleeshop-deployment.yaml
                            git commit -m "Update image tag to ${DOCKER_IMAGE}:${DOCKER_TAG} [ci skip]"

                            # Use credentials to push
                            git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/Niroth36/SimpleEshop.git master

                            echo "✅ Successfully updated and pushed deployment manifest"
                        """
                    }
                }
            }
        }

        stage('Cleanup Control Plane') {
            when {
                expression { return env.SHOULD_BUILD == 'true' }
            }
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'control-plane-credentials', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                        sh """
                            ssh -i ~/.ssh/id_rsa \${SSH_USER}@${CONTROL_PLANE_IP} '
                                echo "🧹 Cleaning up..."

                                # Remove local images to save space
                                docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG} || true
                                docker rmi ${DOCKER_IMAGE}:latest || true

                                # Clean up build directory
                                rm -rf /tmp/simpleeshop-build-${BUILD_NUMBER}

                                echo "✅ Cleanup completed"
                            '
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            deleteDir()
        }
        success {
            script {
                if (env.SHOULD_BUILD == 'true') {
                    echo "🎉 Pipeline completed successfully!"
                    echo "🐳 Image pushed to Docker Hub: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    echo "🔗 Latest tag: ${DOCKER_IMAGE}:latest"
                    echo "📄 Kubernetes manifest updated and pushed to GitHub"
                } else {
                    echo "⏭️ Pipeline skipped - Neither condition was met:"
                    echo "   - CONDITION 1: No changes detected in web-app directory"
                    echo "   - CONDITION 2: Not manually triggered using the build button"
                    echo "ℹ️ The pipeline will run when EITHER:"
                    echo "   - CONDITION 1: Triggered by a webhook and changes are detected in the web-app directory"
                    echo "   - CONDITION 2: Manually triggered using the build button"
                }
            }
        }
        failure {
            echo "❌ Pipeline failed. Check the logs for details."
        }
    }
}
