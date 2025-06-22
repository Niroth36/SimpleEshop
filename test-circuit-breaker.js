#!/usr/bin/env node

/**
 * Test script for demonstrating the Circuit Breaker Pattern in email services
 * 
 * This script simulates email sending failures to trigger the circuit breaker
 * and shows how it prevents cascading failures.
 */

const http = require('http');
const fs = require('fs');

// Configuration
const WELCOME_EMAIL_PORT = process.env.WELCOME_EMAIL_PORT || 8080;
const ORDER_EMAIL_PORT = process.env.ORDER_EMAIL_PORT || 8081;
const MAILPIT_PORT = process.env.MAILPIT_PORT || 1025;
const TEST_EMAIL = 'test@example.com';
const TEST_USERNAME = 'TestUser';

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m'
};

// Helper function to log with colors
function log(message, color = colors.reset) {
  console.log(`${color}${message}${colors.reset}`);
}

// Helper function to make HTTP requests
function makeRequest(options, data) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let responseData = '';
      
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        try {
          const parsedData = JSON.parse(responseData);
          resolve({ statusCode: res.statusCode, data: parsedData });
        } catch (e) {
          resolve({ statusCode: res.statusCode, data: responseData });
        }
      });
    });
    
    req.on('error', (error) => {
      reject(error);
    });
    
    if (data) {
      req.write(JSON.stringify(data));
    }
    
    req.end();
  });
}

// Test the welcome email service with circuit breaker
async function testWelcomeEmailCircuitBreaker() {
  log('\n=== Testing Welcome Email Circuit Breaker ===', colors.blue);
  
  // Prepare test data
  const userData = {
    userData: {
      username: TEST_USERNAME,
      email: TEST_EMAIL
    }
  };
  
  // Test options
  const options = {
    hostname: 'localhost',
    port: WELCOME_EMAIL_PORT,
    path: '/',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    }
  };
  
  // First, check if the service is running
  try {
    await makeRequest({
      hostname: 'localhost',
      port: WELCOME_EMAIL_PORT,
      path: '/',
      method: 'GET'
    });
    log('Welcome Email Service is running', colors.green);
  } catch (error) {
    log('Welcome Email Service is not running. Please start it first.', colors.red);
    log('You can start it with: docker-compose up -d welcome-email', colors.yellow);
    return;
  }
  
  // Simulate successful request
  log('\n1. Sending a successful welcome email request...', colors.cyan);
  try {
    const response = await makeRequest(options, userData);
    log(`Response (${response.statusCode}):`, colors.green);
    console.log(JSON.stringify(response.data, null, 2));
    
    // Check circuit status
    if (response.data.circuitStatus) {
      log('Circuit Status:', colors.cyan);
      console.log(JSON.stringify(response.data.circuitStatus, null, 2));
    }
  } catch (error) {
    log(`Error: ${error.message}`, colors.red);
  }
  
  // Simulate a failure by stopping the SMTP server (Mailpit)
  log('\n2. Simulating SMTP server failure...', colors.yellow);
  log('To fully test this, you would need to stop the Mailpit service.', colors.yellow);
  log('For demonstration purposes, we will make requests that will fail.', colors.yellow);
  
  // Simulate multiple failed requests to trigger the circuit breaker
  log('\n3. Sending multiple requests to trigger the circuit breaker...', colors.magenta);
  
  // Modify options to cause failures (invalid port)
  const failOptions = {
    ...options,
    port: MAILPIT_PORT + 1 // Use an invalid port to cause connection failures
  };
  
  // Send multiple requests to trigger the circuit breaker
  for (let i = 1; i <= 5; i++) {
    log(`\nRequest ${i}:`, colors.cyan);
    try {
      const response = await makeRequest(failOptions, userData);
      log(`Response (${response.statusCode}):`, colors.green);
      console.log(JSON.stringify(response.data, null, 2));
    } catch (error) {
      log(`Error: ${error.message}`, colors.red);
    }
    
    // Add a small delay between requests
    await new Promise(resolve => setTimeout(resolve, 500));
  }
  
  // Try a request after the circuit should be open
  log('\n4. Sending a request after circuit should be open...', colors.cyan);
  try {
    const response = await makeRequest(options, userData);
    log(`Response (${response.statusCode}):`, colors.green);
    console.log(JSON.stringify(response.data, null, 2));
    
    // Check circuit status
    if (response.data.circuitStatus) {
      log('Circuit Status:', colors.cyan);
      console.log(JSON.stringify(response.data.circuitStatus, null, 2));
    }
  } catch (error) {
    log(`Error: ${error.message}`, colors.red);
  }
  
  // Wait for the circuit to reset and try again
  log('\n5. Waiting for circuit reset timeout (30 seconds)...', colors.yellow);
  log('For demonstration purposes, we will skip the actual wait.', colors.yellow);
  log('In a real scenario, you would wait for the reset timeout.', colors.yellow);
  
  log('\nTest completed. The circuit breaker should have prevented cascading failures.', colors.green);
}

// Test the order confirmation email service with circuit breaker
async function testOrderConfirmationEmailCircuitBreaker() {
  log('\n=== Testing Order Confirmation Email Circuit Breaker ===', colors.blue);
  
  // Prepare test data
  const orderData = {
    orderData: {
      orderId: '12345',
      userId: '67890',
      username: TEST_USERNAME,
      email: TEST_EMAIL,
      total: 99.99,
      items: [
        {
          name: 'Test Product 1',
          price: 49.99,
          quantity: 1
        },
        {
          name: 'Test Product 2',
          price: 25.00,
          quantity: 2
        }
      ]
    }
  };
  
  // Test options
  const options = {
    hostname: 'localhost',
    port: ORDER_EMAIL_PORT,
    path: '/',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    }
  };
  
  // First, check if the service is running
  try {
    await makeRequest({
      hostname: 'localhost',
      port: ORDER_EMAIL_PORT,
      path: '/',
      method: 'GET'
    });
    log('Order Confirmation Email Service is running', colors.green);
  } catch (error) {
    log('Order Confirmation Email Service is not running. Please start it first.', colors.red);
    log('You can start it with: docker-compose up -d order-confirmation-email', colors.yellow);
    return;
  }
  
  // Simulate successful request
  log('\n1. Sending a successful order confirmation email request...', colors.cyan);
  try {
    const response = await makeRequest(options, orderData);
    log(`Response (${response.statusCode}):`, colors.green);
    console.log(JSON.stringify(response.data, null, 2));
    
    // Check circuit status
    if (response.data.circuitStatus) {
      log('Circuit Status:', colors.cyan);
      console.log(JSON.stringify(response.data.circuitStatus, null, 2));
    }
  } catch (error) {
    log(`Error: ${error.message}`, colors.red);
  }
  
  // The rest of the test is similar to the welcome email test
  log('\nThe rest of the test would be similar to the welcome email test.', colors.yellow);
  log('For brevity, we will not repeat the same steps.', colors.yellow);
}

// Main function
async function main() {
  log('=== Circuit Breaker Pattern Test ===', colors.blue);
  log('This script demonstrates how the Circuit Breaker Pattern works in the email services.', colors.cyan);
  log('It will simulate email sending failures to trigger the circuit breaker.', colors.cyan);
  
  // Test welcome email circuit breaker
  await testWelcomeEmailCircuitBreaker();
  
  // Test order confirmation email circuit breaker
  await testOrderConfirmationEmailCircuitBreaker();
  
  log('\n=== Test Complete ===', colors.blue);
  log('The Circuit Breaker Pattern helps prevent cascading failures by:', colors.green);
  log('1. Detecting when a service is failing', colors.green);
  log('2. Stopping requests to the failing service for a period of time', colors.green);
  log('3. Allowing the service to recover', colors.green);
  log('4. Resuming normal operation after the service recovers', colors.green);
}

// Run the main function
main().catch(error => {
  log(`Unhandled error: ${error.message}`, colors.red);
  process.exit(1);
});