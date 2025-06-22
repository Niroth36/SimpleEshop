# Setting Up SSH Keys for Jenkins to Access GitHub

This guide will walk you through the process of setting up SSH keys for Jenkins to securely access your GitHub repositories. Using SSH keys is more secure than using username/password credentials.

## Step 1: Generate SSH Keys on the Jenkins Server

First, you need to generate an SSH key pair on the Jenkins server. SSH into your control plane VM where Jenkins is running:

```bash
ssh azureuser@4.210.149.226
```

Then, execute the following commands to generate an SSH key pair for the Jenkins user:

```bash
# Switch to the Jenkins user context
sudo -u jenkins bash

# If the above doesn't work, you can use the Jenkins container
JENKINS_POD=$(sg microk8s -c "microk8s kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}'")
sg microk8s -c "microk8s kubectl exec -it $JENKINS_POD -n jenkins -- bash"

# Generate SSH key pair (inside the Jenkins container)
mkdir -p /var/jenkins_home/.ssh
ssh-keygen -t rsa -b 4096 -C "jenkins@simpleeshop" -f /var/jenkins_home/.ssh/id_rsa -N ""

# Display the public key
cat /var/jenkins_home/.ssh/id_rsa.pub
```

Copy the output of the last command (the public key) as you'll need to add it to GitHub.

## Step 2: Add the SSH Public Key to GitHub

1. Log in to your GitHub account
2. Go to Settings > SSH and GPG keys
3. Click "New SSH key"
4. Give the key a title (e.g., "Jenkins SimpleEshop")
5. Paste the public key you copied in the previous step
6. Click "Add SSH key"

## Step 3: Configure Jenkins to Use SSH for Git

1. Access Jenkins at http://4.210.149.226:30080
2. Go to "Manage Jenkins" > "Manage Credentials" > "Jenkins" > "Global credentials" > "Add Credentials"
3. Select "SSH Username with private key" from the "Kind" dropdown
4. Set the ID to "github-ssh-key"
5. Set the Username to "git"
6. Select "Enter directly" for the Private Key option
7. Paste the private key (from `/var/jenkins_home/.ssh/id_rsa` on the Jenkins server)
8. Click "OK" to save the credentials

## Step 4: Update the Jenkinsfile to Use SSH

Update your Jenkinsfile.webapp to use SSH instead of HTTPS for Git operations:

```groovy
// Change this line:
sh "git clone https://github.com/Niroth36/SimpleEshop-gitops.git"

// To this:
sh "git clone git@github.com:Niroth36/SimpleEshop-gitops.git"

// And change this block:
withCredentials([usernamePassword(credentialsId: 'github-credentials', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
    sh "git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/Niroth36/SimpleEshop-gitops.git main"
}

// To this:
sshagent(['github-ssh-key']) {
    sh "git push origin main"
}
```

## Step 5: Test the SSH Connection

To ensure that the SSH connection works correctly, you can run a test command in the Jenkins container:

```bash
# Inside the Jenkins container
ssh -T git@github.com
```

You should see a message like:

```
Hi Niroth36! You've successfully authenticated, but GitHub does not provide shell access.
```

This indicates that the SSH connection is working correctly.

## Step 6: Configure Known Hosts (Optional but Recommended)

To avoid the "Host key verification failed" error, you should add GitHub's host key to the known_hosts file:

```bash
# Inside the Jenkins container
mkdir -p /var/jenkins_home/.ssh
ssh-keyscan github.com >> /var/jenkins_home/.ssh/known_hosts
```

## Troubleshooting

If you encounter issues with SSH authentication:

1. **Permission Issues**: Ensure that the SSH key files have the correct permissions:
   ```bash
   chmod 700 /var/jenkins_home/.ssh
   chmod 600 /var/jenkins_home/.ssh/id_rsa
   chmod 644 /var/jenkins_home/.ssh/id_rsa.pub
   ```

2. **Host Key Verification Failed**: If you see this error, it means that GitHub's host key is not in the known_hosts file. Run the ssh-keyscan command from Step 6.

3. **Agent Issues**: If you see "Agent not found" errors, make sure you have the SSH Agent plugin installed in Jenkins.

4. **Debug SSH**: You can debug SSH connections by adding the `-v` flag:
   ```bash
   ssh -vT git@github.com
   ```

## Conclusion

You have successfully set up SSH keys for Jenkins to access GitHub. This provides a more secure way to authenticate with GitHub compared to using username/password credentials. Your Jenkins pipelines can now clone repositories and push changes using SSH authentication.