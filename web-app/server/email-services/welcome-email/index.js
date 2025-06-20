const fs = require("fs");
const http = require("http");
const Minio = require("minio");
const handler = require("./handler");

// Configure MinIO client
const minioClient = new Minio.Client({
    endPoint: process.env.MINIO_HOST || "minio",
    port: parseInt(process.env.MINIO_PORT || "9000"),
    useSSL: false,
    accessKey: process.env.MINIO_ACCESS_KEY || "minioadmin",
    secretKey: process.env.MINIO_SECRET_KEY || "minioadmin"
});

// Create a server to listen for health checks
const server = http.createServer((req, res) => {
    res.writeHead(200, { "Content-Type": "text/plain" });
    res.end("Welcome Email Service is running");
});

server.listen(8080, () => {
    console.log("Welcome Email Service listening on port 8080");
});

// Listen for MinIO events
console.log("Setting up MinIO bucket notification listener...");

// Function to process user registration events
async function processUserRegistration(notification) {
    try {
        console.log(`Processing event: ${notification.eventName} for ${notification.s3.object.key}`);

        // Only process object creation events
        if (notification.eventName !== "s3:ObjectCreated:Put" && notification.eventName !== "s3:ObjectCreated:Post") {
            return;
        }

        const bucketName = notification.s3.bucket.name;
        const objectName = notification.s3.object.key;

        // Get the object data
        const dataStream = await minioClient.getObject(bucketName, objectName);

        // Read the data
        let userData = "";
        dataStream.on("data", chunk => {
            userData += chunk.toString();
        });

        dataStream.on("end", async () => {
            try {
                // Parse the user data
                const userDataObj = JSON.parse(userData);
                console.log("User data:", userDataObj);

                // Call the handler function
                const result = await handler({ body: userDataObj }, {});
                console.log("Handler result:", result);
            } catch (error) {
                console.error("Error processing user data:", error);
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
        const bucketExists = await minioClient.bucketExists("user-registrations");
        if (!bucketExists) {
            console.log("Creating user-registrations bucket...");
            await minioClient.makeBucket("user-registrations");
        }

        console.log("Setting up bucket notification listener...");

        // Listen for bucket notifications
        const listener = minioClient.listenBucketNotification("user-registrations", "", "", ["s3:ObjectCreated:*"]);

        listener.on("notification", async notification => {
            console.log("Received notification:", notification);
            await processUserRegistration(notification);
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
    minioClient.listBuckets()
        .then(() => {
            console.log("MinIO is ready");
            setupBucketNotification();
        })
        .catch(error => {
            console.error("MinIO not ready yet:", error);
            setTimeout(waitForMinIO, 5000);
        });
}

// Start the service
console.log("Welcome Email Service starting...");
waitForMinIO();
