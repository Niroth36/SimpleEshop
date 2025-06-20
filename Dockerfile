# Use Node.js 18 LTS as base image
FROM node:18-alpine

# Set working directory inside container
WORKDIR /app

# Copy package.json and package-lock.json from the correct location
COPY web-app/server/package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY web-app/ ./web-app/
COPY database/ ./database/

# Create a non-root user for security
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# Change ownership of the app directory to the nodejs user
RUN chown -R nextjs:nodejs /app
USER nextjs

# Expose the port the app runs on
EXPOSE 3000

# Define the command to run the application
CMD ["node", "web-app/server/server_postgresql.js"]
