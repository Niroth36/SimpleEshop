// Simple logger that outputs to console
// This replaces the Winston logger with a simpler version that works with Loki

// Get current log level from environment
const getCurrentLevel = () => {
  const env = process.env.NODE_ENV || 'development';
  return env === 'development' ? 'debug' : 'info';
};

// Log levels and their numeric values (lower = higher priority)
const LOG_LEVELS = {
  error: 0,
  warn: 1,
  info: 2,
  http: 3,
  debug: 4
};

// Current log level
const currentLevel = getCurrentLevel();
const currentLevelValue = LOG_LEVELS[currentLevel];

// Format timestamp
const getTimestamp = () => {
  const now = new Date();
  return now.toISOString().replace('T', ' ').replace('Z', '');
};

// Create logger object with methods for each log level
const logger = {
  error: (message) => {
    if (LOG_LEVELS.error <= currentLevelValue) {
      console.error(`${getTimestamp()} error: ${message}`);
    }
  },
  warn: (message) => {
    if (LOG_LEVELS.warn <= currentLevelValue) {
      console.warn(`${getTimestamp()} warn: ${message}`);
    }
  },
  info: (message) => {
    if (LOG_LEVELS.info <= currentLevelValue) {
      console.info(`${getTimestamp()} info: ${message}`);
    }
  },
  http: (message) => {
    if (LOG_LEVELS.http <= currentLevelValue) {
      console.log(`${getTimestamp()} http: ${message}`);
    }
  },
  debug: (message) => {
    if (LOG_LEVELS.debug <= currentLevelValue) {
      console.debug(`${getTimestamp()} debug: ${message}`);
    }
  }
};

module.exports = logger;
