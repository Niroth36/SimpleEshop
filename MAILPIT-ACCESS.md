# Accessing Mailpit in Kubernetes

This guide provides detailed instructions on how to access the Mailpit email testing tool when deployed in a Kubernetes environment.

## What is Mailpit?

Mailpit is an email testing tool that captures all outgoing emails from your application for testing purposes. It provides a web interface where you can view and inspect these emails without them being sent to real recipients.

## Why Port Forwarding?

In Kubernetes, Mailpit runs inside the cluster and is not directly accessible from outside by default. To access the Mailpit web interface, we need to create a secure tunnel from our local machine to the Mailpit service running in the Kubernetes cluster. This is done using the `kubectl port-forward` command.

## Step-by-Step Guide to Access Mailpit

### 1. Ensure you have kubectl installed and configured

Before you can access Mailpit, make sure you have:
- kubectl installed on your machine
- Access to the Kubernetes cluster where SimpleEshop is deployed
- The correct kubectl context set

You can check your current context with:
```bash
kubectl config current-context
```

### 2. Verify that Mailpit is running

First, check that the Mailpit pod is running in the simpleeshop namespace:

```bash
kubectl get pods -n simpleeshop -l app=mailpit
```

You should see output similar to:
```
NAME                      READY   STATUS    RESTARTS   AGE
mailpit-5d7b9c7b4d-x2jvf  1/1     Running   0          3h
```

If the pod is not running or shows a status other than "Running", check the logs:
```bash
kubectl logs -n simpleeshop -l app=mailpit
```

### 3. Start port forwarding

To access the Mailpit web interface, run the following command:

```bash
kubectl port-forward svc/mailpit-service -n simpleeshop 8025:8025
```

This command:
- Creates a secure tunnel from your local port 8025 to port 8025 of the mailpit-service in the Kubernetes cluster
- Keeps running in the terminal as long as you need the connection
- Will show output like "Forwarding from 127.0.0.1:8025 -> 8025" when successful

**Note:** Keep this terminal window open while you're accessing Mailpit. If you close it, the port forwarding will stop and you'll lose access to the Mailpit interface.

### 4. Access the Mailpit web interface

While the port-forward command is running, open your web browser and navigate to:

```
http://localhost:8025
```

You should now see the Mailpit web interface where you can view all emails captured by the system.

## Troubleshooting

### Port already in use

If you see an error like "port 8025 already in use", you can:

1. Find and close the application using that port, or
2. Use a different local port:
   ```bash
   kubectl port-forward svc/mailpit-service -n simpleeshop 8026:8025
   ```
   Then access Mailpit at http://localhost:8026

### Connection refused

If you see "connection refused" when trying to access http://localhost:8025:

1. Check that the port-forward command is still running
2. Verify that the Mailpit pod is running (see step 2)
3. Try restarting the port-forward command

### Unable to connect to the server

If kubectl shows "Unable to connect to the server":

1. Check your VPN connection if you're using one
2. Verify your kubectl context is correct
3. Ensure you have network access to the Kubernetes API server

## Alternative Access Methods

### NodePort (if configured)

If Mailpit is exposed via NodePort, you can access it directly at:
```
http://<node-ip>:<nodeport>
```

### Ingress (if configured)

If Mailpit is exposed via an Ingress controller, you can access it at the configured hostname:
```
http://mailpit.your-domain.com
```

## Viewing Emails

Once you've accessed the Mailpit web interface:

1. All captured emails will be listed in the left panel
2. Click on an email to view its contents
3. You can see both the HTML and plain text versions of the email
4. Attachments can be viewed and downloaded
5. Email headers are available for inspection

## When to Use Mailpit

Use Mailpit to:
- Verify that welcome emails are being sent when users register
- Check the format and content of order confirmation emails
- Test any other email functionality in the application
- Debug email-related issues

## Conclusion

By following this guide, you should now be able to access the Mailpit web interface and view all emails sent by the SimpleEshop application in your Kubernetes environment.