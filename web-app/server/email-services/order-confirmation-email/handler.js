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

    // Extract order data from the event
    // Check if the data is already wrapped in an orderData property
    const orderData = body.orderData ? body.orderData : body;
    const { orderId, userId, username, email, items } = orderData;

    // Ensure total is a number and handle undefined, null, or NaN values
    let total = 0;
    try {
        if (typeof orderData.total === 'number') {
            total = orderData.total;
        } else if (orderData.total) {
            total = parseFloat(orderData.total);
        }
        // If parsing failed or resulted in NaN, set to 0
        if (isNaN(total)) {
            total = 0;
        }
    } catch (e) {
        console.error(`Error parsing total: ${e.message}`);
        total = 0;
    }


    if (!email) {
        console.error("No email address provided");
        return {
            statusCode: 400,
            body: JSON.stringify({ error: "No email address provided" })
        };
    }

    if (!items || !Array.isArray(items) || items.length === 0) {
        console.error("No items in order");
        return {
            statusCode: 400,
            body: JSON.stringify({ error: "No items in order" })
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

    // Process items and generate HTML
    const processedItems = items.map(item => {
        // Ensure price is a number
        let price = 0;
        if (typeof item.price === 'number') {
            price = item.price;
        } else if (item.price) {
            price = parseFloat(item.price);
        }
        if (isNaN(price)) price = 0;

        // Ensure quantity is a number
        let quantity = 1;
        if (typeof item.quantity === 'number') {
            quantity = item.quantity;
        } else if (item.quantity) {
            quantity = parseInt(item.quantity);
        }
        if (isNaN(quantity)) quantity = 1;


        return {
            name: item.name || 'Unknown Item',
            price: price,
            quantity: quantity,
            subtotal: price * quantity
        };
    });

    // Generate HTML for items
    const itemsHtml = processedItems.map(item => `
        <tr>
            <td style="padding: 10px; border-bottom: 1px solid #ddd;">${item.name}</td>
            <td style="padding: 10px; border-bottom: 1px solid #ddd; text-align: center;">${item.quantity}</td>
            <td style="padding: 10px; border-bottom: 1px solid #ddd; text-align: right;">$${item.price.toFixed(2)}</td>
            <td style="padding: 10px; border-bottom: 1px solid #ddd; text-align: right;">$${item.subtotal.toFixed(2)}</td>
        </tr>
    `).join('');

    // Generate text for items
    const itemsText = processedItems.map(item => 
        `- ${item.name} (${item.quantity}) - $${item.subtotal.toFixed(2)}`
    ).join('\n');

    // Prepare email content
    const mailOptions = {
        from: '"SimpleEshop" <orders@simpleeshop.com>',
        to: email,
        subject: `Your SimpleEshop Order #${orderId} Confirmation`,
        text: `
Hello ${username || 'there'},

Thank you for your order from SimpleEshop!

Order #: ${orderId}
Order Total: $${total.toFixed(2)}

Order Items:
${itemsText}

We'll process your order as soon as possible.

Thank you for shopping with us!
The SimpleEshop Team
        `,
        html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                <h2>Order Confirmation</h2>
                <p>Hello ${username || 'there'},</p>
                <p>Thank you for your order from SimpleEshop!</p>

                <div style="background-color: #f8f8f8; padding: 15px; margin: 20px 0; border-radius: 5px;">
                    <p><strong>Order #:</strong> ${orderId}</p>
                    <p><strong>Order Date:</strong> ${new Date().toLocaleDateString()}</p>
                </div>

                <h3>Order Summary</h3>
                <table style="width: 100%; border-collapse: collapse;">
                    <thead>
                        <tr style="background-color: #f2f2f2;">
                            <th style="padding: 10px; text-align: left;">Item</th>
                            <th style="padding: 10px; text-align: center;">Quantity</th>
                            <th style="padding: 10px; text-align: right;">Price</th>
                            <th style="padding: 10px; text-align: right;">Subtotal</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${itemsHtml}
                    </tbody>
                    <tfoot>
                        <tr>
                            <td colspan="3" style="padding: 10px; text-align: right; font-weight: bold;">Total:</td>
                            <td style="padding: 10px; text-align: right; font-weight: bold;">$${total.toFixed(2)}</td>
                        </tr>
                    </tfoot>
                </table>

                <p>We'll process your order as soon as possible.</p>
                <p>Thank you for shopping with us!</p>
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
            name: 'OrderConfirmationEmailCircuit'
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
                message: 'Order confirmation email sent successfully',
                recipient: email,
                orderId: orderId,
                messageId: info.messageId,
                circuitStatus: emailCircuitBreaker.getStatus()
            })
        };
    } catch (error) {
        console.error('Error sending email:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({
                error: 'Failed to send order confirmation email',
                details: error.message,
                circuitStatus: emailCircuitBreaker.getStatus()
            })
        };
    }
};
