# Design Patterns in SimpleEshop

This document outlines the design patterns used in the SimpleEshop application and recommends additional patterns to improve the system's resilience, scalability, and maintainability.

## Table of Contents

- [Currently Implemented Patterns](#currently-implemented-patterns)
  - [Retry Pattern](#1-retry-pattern)
  - [Event-Driven Architecture](#2-event-driven-architecture)
  - [Stateless Services](#3-stateless-services)
  - [Async Processing](#4-async-processing)
  - [Circuit Breaker Pattern](#5-circuit-breaker-pattern)
- [Recommended Additional Patterns](#recommended-additional-patterns)
  - [Idempotency Pattern](#1-idempotency-pattern)
  - [Claim Check Pattern](#2-claim-check-pattern)
  - [Compensating Transaction Pattern](#3-compensating-transaction-pattern)
  - [Async Reply Pattern](#4-async-reply-pattern)
- [Pattern Summary Table](#pattern-summary-table)
- [Conclusion](#conclusion)

---

## Currently Implemented Patterns

### 1. Retry Pattern

**Status: ✅ Implemented**

The Retry pattern is implemented in several places:

- **Database Connection**: In `server_postgresql.js`, the `connectWithRetry()` function implements a retry mechanism for database connections with exponential backoff.
  ```javascript
  async function connectWithRetry() {
      const maxRetries = 5;
      let retries = 0;
      while (retries < maxRetries) {
          try {
              const client = await pool.connect();
              console.log('Connected to PostgreSQL!');
              client.release();
              return;
          } catch (err) {
              retries++;
              console.log(`Database connection attempt ${retries}/${maxRetries} failed. Retrying in 5 seconds...`);
              await new Promise(resolve => setTimeout(resolve, 5000));
          }
      }
  }
  ```

- **MinIO Connection**: In both email services (`welcome-email/index.js` and `order-confirmation-email/index.js`), there are retry mechanisms for setting up MinIO bucket notifications and waiting for MinIO to be ready.
  ```javascript
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
  ```

### 2. Event-Driven Architecture

**Status: ✅ Implemented**

The application uses an event-driven architecture for certain operations:

- **Email Services**: Both the welcome-email and order-confirmation-email services listen for events (object creation in MinIO buckets) to trigger their operations.
  ```javascript
  const listener = minioClient.listenBucketNotification("user-registrations", "", "", ["s3:ObjectCreated:*"]);
  listener.on("notification", async notification => {
      console.log("Received notification:", notification);
      await processUserRegistration(notification);
  });
  ```

### 3. Stateless Services

**Status: ✅ Implemented**

The email services are designed as stateless microservices:

- They don't maintain any state between requests
- Each request is processed independently
- They can be scaled horizontally without concerns about state synchronization

### 4. Async Processing

**Status: ✅ Implemented**

The application uses asynchronous processing in several places:

- **Email Services**: Both email services use async/await and event listeners to handle asynchronous operations.
- **Database Operations**: Many database operations in `server_postgresql.js` use async/await for non-blocking I/O.

### 5. Circuit Breaker Pattern

**Status: ✅ Implemented**

The Circuit Breaker pattern is implemented to prevent cascading failures:

- **Email Sending**: Both email services use a circuit breaker for SMTP operations to handle email server failures gracefully.

**Implementation Location**: `web-app/server/email-services/circuit-breaker.js`

**Key Features**:
- Failure threshold configuration
- Automatic state transitions (CLOSED → OPEN → HALF-OPEN)
- Configurable reset timeout
- Detailed status reporting and monitoring
- Named circuit instances for better logging

**Code Excerpt**:
```javascript
class CircuitBreaker {
    constructor(fn, options = {}) {
        this.fn = fn;
        this.failureThreshold = options.failureThreshold || 3;
        this.resetTimeout = options.resetTimeout || 30000; // 30 seconds
        this.state = 'CLOSED';
        this.failureCount = 0;
        this.nextAttempt = Date.now();
        this.name = options.name || 'Circuit';

        // For monitoring
        this.successCount = 0;
        this.lastFailure = null;
        this.lastSuccess = null;
    }

    // Main method to execute the wrapped function
    async fire(...args) {
        // Circuit state logic...
    }
}
```

**Usage Example**:
```javascript
// Create a circuit breaker for email sending
const emailCircuitBreaker = new CircuitBreaker(
    async (mailOpts) => await transporter.sendMail(mailOpts),
    {
        failureThreshold: 3,
        resetTimeout: 30000,
        name: 'EmailCircuit'
    }
);

// Use the circuit breaker
const result = await emailCircuitBreaker.fire(mailOptions);
```

**Testing**:

A test script is provided to demonstrate the Circuit Breaker Pattern in action:

```bash
# Run the test
./test-circuit-breaker.js
```

**Benefits**:
1. Prevents cascading failures
2. Allows failing services time to recover
3. Fails fast when services are unavailable
4. Provides monitoring and status information


## Pattern Summary Table

| Pattern | Status | Purpose | Key Benefits |
|---------|--------|---------|-------------|
| Retry | ✅ Implemented | Handle transient failures | Improved reliability, resilience to network issues |
| Event-Driven Architecture | ✅ Implemented | Decouple components | Better scalability, loose coupling |
| Stateless Services | ✅ Implemented | Enable horizontal scaling | Easier scaling, no shared state |
| Async Processing | ✅ Implemented | Non-blocking operations | Better resource utilization, responsiveness |
| Circuit Breaker | ✅ Implemented | Prevent cascading failures | System stability, fast failure, controlled recovery |

---

## Conclusion

SimpleEshop currently implements several important design patterns including Retry, Event-Driven Architecture, Stateless Services, Async Processing, and Circuit Breaker. These patterns provide a solid foundation for a resilient and scalable application.
