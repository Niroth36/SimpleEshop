#!/bin/bash

# test-email-services.sh - Test if email services are properly deployed and functioning
set -e

echo "🧪 Testing Email Services..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check cluster connectivity
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    print_warning "Make sure your kubeconfig is set up correctly"
    exit 1
fi

# Check if email services are deployed
print_header "Checking Email Services Deployment"

# Check if welcome-email deployment exists
if kubectl get deployment welcome-email -n simpleeshop &> /dev/null; then
    print_status "Welcome Email Service is deployed"
else
    print_error "Welcome Email Service is not deployed"
    exit 1
fi

# Check if order-confirmation-email deployment exists
if kubectl get deployment order-confirmation-email -n simpleeshop &> /dev/null; then
    print_status "Order Confirmation Email Service is deployed"
else
    print_error "Order Confirmation Email Service is not deployed"
    exit 1
fi

# Check if mailpit deployment exists
if kubectl get deployment mailpit -n simpleeshop &> /dev/null; then
    print_status "Mailpit is deployed"
else
    print_error "Mailpit is not deployed"
    exit 1
fi

# Check if services are running
print_header "Checking Email Services Status"

# Check if welcome-email pods are running
WELCOME_EMAIL_PODS=$(kubectl get pods -n simpleeshop -l app=welcome-email -o jsonpath='{.items[*].status.phase}')
if [[ "$WELCOME_EMAIL_PODS" == "Running" ]]; then
    print_status "Welcome Email Service pods are running"
else
    print_warning "Welcome Email Service pods are not running: $WELCOME_EMAIL_PODS"
    kubectl get pods -n simpleeshop -l app=welcome-email
fi

# Check if order-confirmation-email pods are running
ORDER_EMAIL_PODS=$(kubectl get pods -n simpleeshop -l app=order-confirmation-email -o jsonpath='{.items[*].status.phase}')
if [[ "$ORDER_EMAIL_PODS" == "Running" ]]; then
    print_status "Order Confirmation Email Service pods are running"
else
    print_warning "Order Confirmation Email Service pods are not running: $ORDER_EMAIL_PODS"
    kubectl get pods -n simpleeshop -l app=order-confirmation-email
fi

# Check if mailpit pods are running
MAILPIT_PODS=$(kubectl get pods -n simpleeshop -l app=mailpit -o jsonpath='{.items[*].status.phase}')
if [[ "$MAILPIT_PODS" == "Running" ]]; then
    print_status "Mailpit pods are running"
else
    print_warning "Mailpit pods are not running: $MAILPIT_PODS"
    kubectl get pods -n simpleeshop -l app=mailpit
fi

# Check if MinIO is accessible from email services
print_header "Checking MinIO Connectivity"
kubectl exec -it -n simpleeshop deployment/welcome-email -- wget -O- minio-service:9000 &> /dev/null
if [ $? -eq 0 ]; then
    print_status "Welcome Email Service can connect to MinIO"
else
    print_warning "Welcome Email Service cannot connect to MinIO"
fi

# Check if Mailpit is accessible from email services
print_header "Checking Mailpit Connectivity"
kubectl exec -it -n simpleeshop deployment/welcome-email -- wget -O- mailpit-service:1025 &> /dev/null
if [ $? -eq 0 ]; then
    print_status "Welcome Email Service can connect to Mailpit"
else
    print_warning "Welcome Email Service cannot connect to Mailpit"
fi

# Final status
print_header "🧪 Test Summary"
echo "Email services deployment status:"
kubectl get pods -n simpleeshop -l tier=backend

echo ""
print_status "Test completed! 🎉"