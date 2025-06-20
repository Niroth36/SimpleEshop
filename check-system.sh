#!/bin/bash

# Script to check the status of all components in the SimpleEshop system

echo "=== SimpleEshop System Check ==="
echo ""

# Function to check if a service is running
check_service() {
    local service_name=$1
    local container_name=$2
    local port=$3
    local endpoint=$4

    echo "Checking $service_name..."

    # Check if container is running
    if docker ps | grep -q $container_name; then
        echo "  ✅ Container $container_name is running"
    else
        echo "  ❌ Container $container_name is NOT running"
        echo "      Try: docker compose up -d $container_name"
        return 1
    fi

    # Check if port is accessible
    if nc -z localhost $port; then
        echo "  ✅ Port $port is accessible"
    else
        echo "  ❌ Port $port is NOT accessible"
        echo "      Check container logs: docker logs $container_name"
        return 1
    fi

    # Check if endpoint is accessible (if provided)
    if [ ! -z "$endpoint" ]; then
        if curl -s -o /dev/null -w "%{http_code}" $endpoint | grep -q "200\|201\|202\|203\|204"; then
            echo "  ✅ Endpoint $endpoint is accessible"
        else
            echo "  ❌ Endpoint $endpoint is NOT accessible"
            echo "      Check container logs: docker logs $container_name"
            return 1
        fi
    fi

    return 0
}

# Check PostgreSQL
check_service "PostgreSQL" "simpleeshop-postgres" "5432" ""
POSTGRES_STATUS=$?

# Check Redis
check_service "Redis" "simpleeshop-redis" "6379" ""
REDIS_STATUS=$?

# Check MinIO
check_service "MinIO" "simpleeshop-minio" "9002" "http://localhost:9002/minio/health/live"
MINIO_STATUS=$?

# Check Mailpit
check_service "Mailpit" "simpleeshop-mailpit" "8025" "http://localhost:8025"
MAILPIT_STATUS=$?

# Check Welcome Email Service
check_service "Welcome Email Service" "simpleeshop-welcome-email" "8080" "http://localhost:8080"
WELCOME_EMAIL_STATUS=$?

# Check Order Confirmation Email Service
check_service "Order Confirmation Email Service" "simpleeshop-order-confirmation-email" "8081" "http://localhost:8081"
ORDER_CONFIRMATION_EMAIL_STATUS=$?

# Check Web App
check_service "Web App" "simpleeshop-app" "3000" "http://localhost:3000"
WEBAPP_STATUS=$?

echo ""
echo "=== Welcome Email Service Check ==="

# The welcome-email service was already checked above using check_service
# This section is kept for clarity and to provide additional information
echo "  The welcome-email service is a standalone Node.js service that listens for MinIO events"
echo "  and sends welcome emails to new users."
echo "  To test it, run: ./test-welcome-email.sh"

echo ""
echo "=== Order Confirmation Email Service Check ==="

# The order-confirmation-email service was already checked above using check_service
# This section is kept for clarity and to provide additional information
echo "  The order-confirmation-email service is a standalone Node.js service that listens for MinIO events"
echo "  and sends order confirmation emails to users when they submit an order."
echo "  To test it, run: ./test-order-confirmation-email.sh"

echo ""
echo "=== System Status Summary ==="

if [ $POSTGRES_STATUS -eq 0 ] && [ $REDIS_STATUS -eq 0 ] && [ $MINIO_STATUS -eq 0 ] && [ $MAILPIT_STATUS -eq 0 ] && [ $WELCOME_EMAIL_STATUS -eq 0 ] && [ $ORDER_CONFIRMATION_EMAIL_STATUS -eq 0 ] && [ $WEBAPP_STATUS -eq 0 ]; then
    echo "✅ All systems are operational!"
    echo ""
    echo "You can now run the tests to verify functionality:"
    echo "  ./run-all-tests.sh"
    echo "  ./test-welcome-email.sh"
    echo "  ./test-order-confirmation-email.sh"
else
    echo "❌ Some core systems are not operational. Please fix the issues above."
    echo ""
    echo "After fixing the issues, run this script again to verify:"
    echo "  ./check-system.sh"
fi

echo ""
echo "=== Useful Commands ==="
echo "• Start all services:           docker compose up -d"
echo "• Stop all services:            docker compose down"
echo "• View container logs:          docker logs <container-name>"
echo "• Run all tests:                ./run-all-tests.sh"
echo "• Test welcome-email service:   ./test-welcome-email.sh"
echo "• Test order-confirmation-email service: ./test-order-confirmation-email.sh"
echo "• Check Mailpit web interface:  http://localhost:8025"
echo "• Check MinIO web interface:    http://localhost:9001"
echo "• Check Web App:                http://localhost:3000"
echo "• View welcome-email logs:      docker logs simpleeshop-welcome-email"
echo "• View order-confirmation-email logs: docker logs simpleeshop-order-confirmation-email"
echo "• Restart welcome-email:        docker compose restart welcome-email"
echo "• Restart order-confirmation-email: docker compose restart order-confirmation-email"

# Make the script executable
chmod +x check-system.sh
