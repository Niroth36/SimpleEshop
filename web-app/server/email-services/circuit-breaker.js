/**
 * Circuit Breaker implementation for email services
 * This helps prevent cascading failures when the email service is experiencing issues
 */

// Import logger if available, otherwise use console
let logger;
let metrics;
try {
    logger = require('../utils/logger');
    metrics = require('../utils/metrics');
} catch (err) {
    // Fallback to console if logger module is not available
    logger = {
        info: console.log,
        error: console.error,
        warn: console.warn,
        debug: console.log
    };
    // Create a dummy metrics object if metrics module is not available
    metrics = {
        updateCircuitBreakerMetrics: () => {}
    };
}

class CircuitBreaker {
    constructor(fn, options = {}) {
        this.fn = fn;
        this.failureThreshold = options.failureThreshold || 3;
        this.resetTimeout = options.resetTimeout || 30000; // 30 seconds
        this.state = 'CLOSED';
        this.failureCount = 0;
        this.nextAttempt = Date.now();
        this.name = options.name || 'Circuit';

        // For logging/monitoring
        this.successCount = 0;
        this.lastFailure = null;
        this.lastSuccess = null;
    }

    async fire(...args) {
        // Check if circuit is OPEN
        if (this.state === 'OPEN') {
            if (this.nextAttempt <= Date.now()) {
                logger.info(`${this.name}: Circuit is HALF-OPEN, allowing test request`);
                this.state = 'HALF-OPEN';
                metrics.updateCircuitBreakerMetrics(this.name, this.state);
            } else {
                const remainingTime = Math.round((this.nextAttempt - Date.now()) / 1000);
                logger.warn(`${this.name}: Circuit is OPEN, fast failing. Retry in ${remainingTime}s`);
                throw new Error(`Circuit is OPEN. Retry in ${remainingTime}s`);
            }
        }

        try {
            const result = await this.fn(...args);
            this.success();
            return result;
        } catch (error) {
            this.failure(error);
            throw error;
        }
    }

    success() {
        this.failureCount = 0;
        this.state = 'CLOSED';
        this.successCount++;
        this.lastSuccess = new Date();
        logger.info(`${this.name}: Operation succeeded, circuit CLOSED`);
        metrics.updateCircuitBreakerMetrics(this.name, this.state, true);
    }

    failure(error) {
        this.failureCount++;
        this.lastFailure = new Date();

        logger.warn(`${this.name}: Operation failed (${this.failureCount}/${this.failureThreshold}): ${error.message}`);
        metrics.updateCircuitBreakerMetrics(this.name, this.state, false);

        if (this.failureCount >= this.failureThreshold) {
            this.state = 'OPEN';
            this.nextAttempt = Date.now() + this.resetTimeout;
            const resetTime = new Date(this.nextAttempt).toISOString().substr(11, 8);
            logger.error(`${this.name}: Circuit OPENED until ${resetTime}`);
            metrics.updateCircuitBreakerMetrics(this.name, this.state);
        }
    }

    // Get current status for monitoring
    getStatus() {
        return {
            state: this.state,
            failureCount: this.failureCount,
            failureThreshold: this.failureThreshold,
            resetTimeout: this.resetTimeout,
            nextAttempt: this.state === 'OPEN' ? new Date(this.nextAttempt).toISOString() : null,
            successCount: this.successCount,
            lastFailure: this.lastFailure ? this.lastFailure.toISOString() : null,
            lastSuccess: this.lastSuccess ? this.lastSuccess.toISOString() : null
        };
    }
}

module.exports = CircuitBreaker;
