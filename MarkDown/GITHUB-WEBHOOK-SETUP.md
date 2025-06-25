# Setting Up GitHub Webhooks for Jenkins

This guide will walk you through the process of setting up GitHub webhooks to automatically trigger your Jenkins pipeline when changes are pushed to your GitHub repository.

## Step 1: Configure Jenkins for Webhook Access

First, you need to ensure that Jenkins is accessible from the internet and properly configured to receive webhooks:

1. Access Jenkins at http://4.210.149.226:30080
2. Go to "Manage Jenkins" > "Configure System"
3. Scroll down to the "GitHub" section
4. Click "Advanced" and check "Specify another hook URL for GitHub configuration"
5. Set the Hook URL to `http://4.210.149.226:30080/github-webhook/`
6. Click "Save"

## Step 2: Install Required Jenkins Plugins

Ensure you have the necessary plugins installed:

1. Go to "Manage Jenkins" > "Manage Plugins" > "Available"
2. Search for and install the following plugins if they're not already installed:
   - GitHub Integration
   - Generic Webhook Trigger
3. Click "Install without restart"
4. Check "Restart Jenkins when installation is complete and no jobs are running"

## Step 3: Configure Your Jenkins Pipeline for Webhook Triggers

1. Go to your Jenkins dashboard
2. Click on your web-app pipeline job
3. Click "Configure"
4. In the "General" section, check "GitHub project" and enter your repository URL (e.g., https://github.com/Niroth36/SimpleEshop)
5. In the "Build Triggers" section, check "GitHub hook trigger for GITScm polling"
6. Click "Save"

## Step 4: Create a GitHub Webhook

1. Go to your GitHub repository (e.g., https://github.com/Niroth36/SimpleEshop)
2. Click on "Settings" > "Webhooks" > "Add webhook"
3. Set the Payload URL to `http://4.210.149.226:30080/github-webhook/`
4. Set the Content type to `application/json`
5. For "Which events would you like to trigger this webhook?", select "Just the push event" (or choose specific events as needed)
6. Check "Active"
7. Click "Add webhook"

## Step 5: Configure Path-Based Webhook Filtering (Optional)

If you want to trigger the pipeline only when changes are made to the web-app directory:

1. Go to your GitHub repository
2. Click on "Settings" > "Webhooks" > Edit your webhook
3. Scroll down to "Which events would you like to trigger this webhook?"
4. Select "Let me select individual events"
5. Check "Pushes" and "Pull requests"
6. In the "Push events" section, you can specify a branch name pattern (e.g., `main`)
7. Click "Update webhook"

## Step 6: Test the Webhook

1. Make a small change to a file in the web-app directory
2. Commit and push the change to GitHub:
   ```bash
   git add web-app/path/to/file
   git commit -m "Test webhook trigger"
   git push origin main
   ```
3. Go to your GitHub repository > "Settings" > "Webhooks"
4. Click on your webhook
5. Scroll down to "Recent Deliveries" to see if the webhook was delivered successfully
6. Check your Jenkins pipeline to see if it was triggered

## Step 7: Verify Pipeline Execution

1. Go to your Jenkins dashboard
2. Check if your pipeline job was triggered
3. Click on the build number to see the build details
4. Check the console output to ensure that the pipeline is executing as expected

## Troubleshooting

### Webhook Not Triggering

1. **Check Webhook Delivery**: In GitHub, go to your repository > "Settings" > "Webhooks" > click on your webhook > "Recent Deliveries" to see if there are any failed deliveries and why they failed.

2. **Check Jenkins Logs**: Go to "Manage Jenkins" > "System Log" to check for any errors related to webhook processing.

3. **Firewall Issues**: Ensure that port 30080 is open on your control plane VM and that GitHub can reach your Jenkins server.

4. **URL Issues**: Make sure the webhook URL is correct and includes the trailing slash: `http://4.210.149.226:30080/github-webhook/`

### Pipeline Not Filtering Correctly

If your pipeline is being triggered for all changes, not just web-app changes:

1. Check your Jenkinsfile to ensure the "Check for Web App Changes" stage is working correctly
2. Test the git diff command manually to ensure it's returning the expected results

## Security Considerations

1. **Authentication**: Consider setting up a secret token for your webhook to ensure that only GitHub can trigger your pipeline.

2. **HTTPS**: For production environments, use HTTPS for your webhook URL to encrypt the traffic between GitHub and Jenkins.

3. **IP Filtering**: Consider restricting webhook access to GitHub's IP ranges only.

## Conclusion

You have successfully set up GitHub webhooks to automatically trigger your Jenkins pipeline when changes are pushed to your GitHub repository. This automation is a key component of a CI/CD workflow, allowing for continuous integration and delivery of your application.

For more information, refer to the [Jenkins GitHub Integration documentation](https://plugins.jenkins.io/github-integration/) and the [GitHub Webhooks documentation](https://docs.github.com/en/developers/webhooks-and-events/webhooks/about-webhooks).
