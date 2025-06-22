const fs = require("fs");
const http = require("http");
const Minio = require("minio");
const handler = require("./handler");

// Configure MinIO client
const minioClient = new Minio.Client({
    endPoint: process.env.MINIO_HOST || "minio-service",
    port: parseInt(process.env.MINIO_PORT || "9000"),
    useSSL: false,
    accessKey: process.env.MINIO_ACCESS_KEY || "minioadmin",
    secretKey: process.env.MINIO_SECRET_KEY || "minioadmin"
});

// Create a server to listen for health checks and webhook notifications
const server = http.createServer((req, res) => {
    // Health check endpoint
    if (req.method === 'GET') {
        res.writeHead(200, { "Content-Type": "text/plain" });
        res.end("Order Confirmation Email Service is running");
        return;
    }

    // Handle webhook notifications from MinIO
    if (req.method === 'POST') {
        let body = '';

        req.on('data', chunk => {
            body += chunk.toString();
        });

        req.on('end', async () => {
            try {
                console.log("Received webhook notification:", body);
                const notification = JSON.parse(body);

                // Process the notification
                if (notification.Records && Array.isArray(notification.Records)) {
                    for (const record of notification.Records) {
                        // Extract the S3 event details
                        const s3Event = {
                            eventName: record.eventName,
                            s3: {
                                bucket: { name: record.s3.bucket.name },
                                object: { key: record.s3.object.key }
                            }
                        };

                        await processOrderConfirmation(s3Event);
                    }
                } else {
                    // Handle direct notification format
                    await processOrderConfirmation(notification);
                }

                res.writeHead(200, { "Content-Type": "application/json" });
                res.end(JSON.stringify({ status: "success" }));
            } catch (error) {
                console.error("Error processing webhook notification:", error);
                res.writeHead(500, { "Content-Type": "application/json" });
                res.end(JSON.stringify({ error: "Failed to process notification" }));
            }
        });

        return;
    }

    // Handle other requests
    res.writeHead(404, { "Content-Type": "text/plain" });
    res.end("Not Found");
});

server.listen(8081, () => {
    console.log("Order Confirmation Email Service listening on port 8081");
});

// Listen for MinIO events
console.log("Setting up MinIO bucket notification listener...");

// Function to process order confirmation events
async function processOrderConfirmation(notification) {
    try {
        console.log(`[DEBUG] Processing event: ${notification.eventName} for ${notification.s3.object.key}`);
        console.log(`[DEBUG] Full notification: ${JSON.stringify(notification)}`);

        // Only process object creation events
        if (notification.eventName !== "s3:ObjectCreated:Put" && notification.eventName !== "s3:ObjectCreated:Post") {
            return;
        }

        const bucketName = notification.s3.bucket.name;
        const objectName = notification.s3.object.key;

        // Get the object data
        const dataStream = await minioClient.getObject(bucketName, objectName);

        // Read the data
        let orderData = "";
        dataStream.on("data", chunk => {
            orderData += chunk.toString();
        });

        dataStream.on("end", async () => {
            try {
                // Parse the order data
                console.log(`[DEBUG] Raw order data: ${orderData}`);
                const orderDataObj = JSON.parse(orderData);
                console.log(`[DEBUG] Parsed order data: ${JSON.stringify(orderDataObj)}`);

                // Call the handler function
                const result = await handler({ body: orderDataObj }, {});
                console.log(`[DEBUG] Handler result: ${JSON.stringify(result)}`);
            } catch (error) {
                console.error("Error processing order data:", error);
            }
        });

        dataStream.on("error", error => {
            console.error("Error reading object data:", error);
        });
    } catch (error) {
        console.error("Error processing notification:", error);
    }
}

// Set up bucket notification
async function setupBucketNotification() {
    try {
        // Check if bucket exists, create it if not
        console.log("[DEBUG] Checking if order-confirmations bucket exists...");
        const bucketExists = await minioClient.bucketExists("order-confirmations");
        console.log(`[DEBUG] Bucket exists: ${bucketExists}`);

        if (!bucketExists) {
            console.log("[DEBUG] Creating order-confirmations bucket...");
            await minioClient.makeBucket("order-confirmations");
            console.log("[DEBUG] Bucket created successfully");
        }

        console.log("[DEBUG] Setting up bucket notification listener...");

        // Listen for bucket notifications
        const listener = minioClient.listenBucketNotification("order-confirmations", "", "", ["s3:ObjectCreated:*"]);

        listener.on("notification", async notification => {
            console.log("[DEBUG] Received notification from listener:", notification);
            console.log(`[DEBUG] Notification type: ${typeof notification}`);
            console.log(`[DEBUG] Notification JSON: ${JSON.stringify(notification)}`);
            await processOrderConfirmation(notification);
        });

        console.log("Bucket notification listener set up successfully");
    } catch (error) {
        console.error("Error setting up bucket notification:", error);
        // Retry after a delay
        setTimeout(setupBucketNotification, 5000);
    }
}

// Wait for MinIO to be ready before setting up bucket notification
function waitForMinIO() {
    console.log("[DEBUG] Checking if MinIO is ready...");
    minioClient.listBuckets()
        .then((buckets) => {
            console.log(`[DEBUG] MinIO is ready. Found ${buckets.length} buckets:`);
            buckets.forEach(bucket => console.log(`[DEBUG] - ${bucket.name}`));
            setupBucketNotification();
        })
        .catch(error => {
            console.error(`[DEBUG] MinIO not ready yet: ${error.message}`);
            console.error(`[DEBUG] MinIO connection details: endPoint=${minioClient.host}, port=${minioClient.port}`);
            setTimeout(waitForMinIO, 5000);
        });
}

// Start the service
console.log("Order Confirmation Email Service starting...");
waitForMinIO();
