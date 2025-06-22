/**
 * Circuit Breaker implementation for email services
 * This helps prevent cascading failures when the email service is experiencing issues
 */

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
                console.log(`${this.name}: Circuit is HALF-OPEN, allowing test request`);
                this.state = 'HALF-OPEN';
            } else {
                const remainingTime = Math.round((this.nextAttempt - Date.now()) / 1000);
                console.log(`${this.name}: Circuit is OPEN, fast failing. Retry in ${remainingTime}s`);
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
        console.log(`${this.name}: Operation succeeded, circuit CLOSED`);
    }

    failure(error) {
        this.failureCount++;
        this.lastFailure = new Date();
        
        console.log(`${this.name}: Operation failed (${this.failureCount}/${this.failureThreshold}): ${error.message}`);
        
        if (this.failureCount >= this.failureThreshold) {
            this.state = 'OPEN';
            this.nextAttempt = Date.now() + this.resetTimeout;
            const resetTime = new Date(this.nextAttempt).toISOString().substr(11, 8);
            console.log(`${this.name}: Circuit OPENED until ${resetTime}`);
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