#!/bin/bash

# Script to run all component tests in sequence

echo "=== SimpleEshop Component Testing Suite ==="
echo ""

# Function to check if a test passed
check_result() {
    if [ $? -eq 0 ]; then
        echo "✅ $1 test PASSED"
    else
        echo "❌ $1 test FAILED"
        FAILED_TESTS="$FAILED_TESTS $1"
    fi
    echo ""
}

# Initialize failed tests tracker
FAILED_TESTS=""

# Test 1: Mailpit
echo "=== Testing Mailpit (Email Service) ==="
./test-mailpit.sh
check_result "Mailpit"

# Test 2: Welcome Email Function
echo "=== Testing Welcome Email Function (Standalone Service → Mailpit) ==="
./test-welcome-email.sh
check_result "Welcome Email Function"

# Test 3: Order Confirmation Email Function
echo "=== Testing Order Confirmation Email Function (Standalone Service → Mailpit) ==="
./test-order-confirmation-email.sh
check_result "Order Confirmation Email Function"

# Test 4: Integration
echo "=== Testing Integration (MinIO → Welcome Email Service → Mailpit) ==="
./test-integration.sh
check_result "Integration"

# Summary
echo "=== Test Summary ==="
if [ -z "$FAILED_TESTS" ]; then
    echo "All tests passed successfully! 🎉"
    echo "The system appears to be working correctly."
else
    echo "The following tests failed:$FAILED_TESTS"
    echo "Please check the TESTING.md file for troubleshooting tips."
fi

echo ""
echo "Don't forget to check the Mailpit web interface at http://localhost:8025"
echo "to verify that the emails were sent correctly."
