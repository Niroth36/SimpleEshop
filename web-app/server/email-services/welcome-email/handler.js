const nodemailer = require('nodemailer');
const CircuitBreaker = require('../circuit-breaker');

module.exports = async (event, context) => {
    console.log("Function started with event:", event.body);

    let body;
    try {
        // Parse the event body if it's a string
        body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
    } catch (error) {
        console.error("Error parsing event body:", error);
        return {
            statusCode: 400,
            body: JSON.stringify({ error: "Invalid JSON in request body" })
        };
    }

    // Extract user data from the event
    const userData = body.userData || {};
    const { username, email } = userData;

    if (!email) {
        console.error("No email address provided");
        return {
            statusCode: 400,
            body: JSON.stringify({ error: "No email address provided" })
        };
    }

    // Configure SMTP transport
    const smtpHost = process.env.SMTP_HOST || 'mailpit-service';
    const smtpPort = parseInt(process.env.SMTP_PORT || '1025');
    console.log(`Using SMTP server: ${smtpHost}:${smtpPort}`);

    // Create a nodemailer transporter
    const transporter = nodemailer.createTransport({
        host: smtpHost,
        port: smtpPort,
        secure: false, // true for 465, false for other ports
        tls: {
            rejectUnauthorized: false // Accept self-signed certificates
        }
    });

    // Prepare email content
    const mailOptions = {
        from: '"SimpleEshop" <noreply@simpleeshop.com>',
        to: email,
        subject: `Welcome to SimpleEshop, ${username || 'New User'}!`,
        text: `Hello ${username || 'there'},\n\nWelcome to SimpleEshop! We're excited to have you on board.\n\nHappy shopping!\nThe SimpleEshop Team`,
        html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                <h2>Welcome to SimpleEshop!</h2>
                <p>Hello ${username || 'there'},</p>
                <p>We're excited to have you join our community of tech enthusiasts!</p>
                <p>With your new account, you can:</p>
                <ul>
                    <li>Browse our extensive catalog of tech products</li>
                    <li>Save items to your wishlist</li>
                    <li>Track your orders</li>
                    <li>Receive exclusive offers</li>
                </ul>
                <p>If you have any questions, feel free to contact our support team.</p>
                <p>Happy shopping!</p>
                <p><strong>The SimpleEshop Team</strong></p>
            </div>
        `
    };

    // Create a circuit breaker for email sending
    const emailCircuitBreaker = new CircuitBreaker(
        async (mailOpts) => await transporter.sendMail(mailOpts),
        {
            failureThreshold: 3,
            resetTimeout: 30000, // 30 seconds
            name: 'WelcomeEmailCircuit'
        }
    );

    try {
        // Send the email using the circuit breaker
        const info = await emailCircuitBreaker.fire(mailOptions);
        console.log('Email sent successfully:', info.messageId);

        return {
            statusCode: 200,
            body: JSON.stringify({
                status: 'success',
                message: 'Welcome email sent successfully',
                recipient: email,
                messageId: info.messageId,
                circuitStatus: emailCircuitBreaker.getStatus()
            })
        };
    } catch (error) {
        console.error('Error sending email:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({
                error: 'Failed to send welcome email',
                details: error.message,
                circuitStatus: emailCircuitBreaker.getStatus()
            })
        };
    }
};
