const promClient = require('prom-client');

// Create a Registry to register metrics
const register = new promClient.Registry();

// Add default metrics (CPU, memory, etc.)
promClient.collectDefaultMetrics({ register });

// Create custom metrics
const httpRequestDurationMicroseconds = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10]
});

const httpRequestCounter = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const databaseQueryDurationSeconds = new promClient.Histogram({
  name: 'database_query_duration_seconds',
  help: 'Duration of database queries in seconds',
  labelNames: ['query_type', 'table'],
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5]
});

const circuitBreakerState = new promClient.Gauge({
  name: 'circuit_breaker_state',
  help: 'Current state of circuit breakers (0=closed, 1=half-open, 2=open)',
  labelNames: ['name']
});

const circuitBreakerFailures = new promClient.Counter({
  name: 'circuit_breaker_failures_total',
  help: 'Total number of circuit breaker failures',
  labelNames: ['name']
});

const circuitBreakerSuccesses = new promClient.Counter({
  name: 'circuit_breaker_successes_total',
  help: 'Total number of circuit breaker successes',
  labelNames: ['name']
});

// Register custom metrics
register.registerMetric(httpRequestDurationMicroseconds);
register.registerMetric(httpRequestCounter);
register.registerMetric(databaseQueryDurationSeconds);
register.registerMetric(circuitBreakerState);
register.registerMetric(circuitBreakerFailures);
register.registerMetric(circuitBreakerSuccesses);

// Helper function to measure HTTP request duration
const measureRequestDuration = (req, res, startTime) => {
  const duration = (Date.now() - startTime) / 1000;
  const path = req.route ? req.route.path : req.path;
  
  httpRequestDurationMicroseconds
    .labels(req.method, path, res.statusCode)
    .observe(duration);
  
  httpRequestCounter
    .labels(req.method, path, res.statusCode)
    .inc();
};

// Helper function to update circuit breaker metrics
const updateCircuitBreakerMetrics = (name, state, isSuccess = null) => {
  // Update state metric (0=closed, 1=half-open, 2=open)
  const stateValue = state === 'CLOSED' ? 0 : state === 'HALF-OPEN' ? 1 : 2;
  circuitBreakerState.labels(name).set(stateValue);
  
  // Update success/failure counters if provided
  if (isSuccess === true) {
    circuitBreakerSuccesses.labels(name).inc();
  } else if (isSuccess === false) {
    circuitBreakerFailures.labels(name).inc();
  }
};

// Express middleware to measure request duration
const requestDurationMiddleware = (req, res, next) => {
  const startTime = Date.now();
  
  // Once the request is finished, measure its duration
  res.on('finish', () => {
    measureRequestDuration(req, res, startTime);
  });
  
  next();
};

module.exports = {
  register,
  requestDurationMiddleware,
  measureRequestDuration,
  updateCircuitBreakerMetrics,
  databaseQueryDurationSeconds
};