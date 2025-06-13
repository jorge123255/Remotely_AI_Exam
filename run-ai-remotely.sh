#!/bin/bash

# AI-Enhanced Remotely Server Deployment Script
# This script builds and runs the Remotely server with AI integration

set -e

echo "🚀 Starting AI-Enhanced Remotely Server Deployment"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

print_success "Docker is running"

# Stop existing containers
print_status "Stopping existing containers..."
docker-compose -f docker-compose-ai.yml down || true

# Clean up old images (optional)
if [ "$1" = "--clean" ]; then
    print_status "Cleaning up old Docker images..."
    docker system prune -f
    docker image prune -f
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p data logs ai-integration

# Build and start the container
print_status "Building and starting AI-Enhanced Remotely server..."
if docker-compose -f docker-compose-ai.yml up --build -d; then
    print_success "Container started successfully"
else
    print_error "Failed to start container"
    exit 1
fi

# Wait for the service to be ready
print_status "Waiting for service to be ready..."
sleep 10

# Check if the service is responding
for i in {1..30}; do
    if curl -f http://localhost:5001/health > /dev/null 2>&1; then
        print_success "Service is ready and responding!"
        break
    elif [ $i -eq 30 ]; then
        print_error "Service failed to start within 30 attempts"
        print_status "Checking container logs..."
        docker-compose -f docker-compose-ai.yml logs --tail=50
        exit 1
    else
        print_status "Attempt $i/30: Service not ready yet, waiting..."
        sleep 2
    fi
done

# Display final status
echo ""
echo "🎉 AI-Enhanced Remotely Server is now running!"
echo "=================================================="
echo "🌐 Web Interface: http://localhost:5001"
echo "🤖 AI Control: http://localhost:5001/ai-control"
echo ""
echo "📋 Useful commands:"
echo "  View logs: docker-compose -f docker-compose-ai.yml logs -f"
echo "  Stop server: docker-compose -f docker-compose-ai.yml down"
echo "  Restart: ./run-ai-remotely.sh"
echo "  Clean rebuild: ./run-ai-remotely.sh --clean"
echo ""
print_success "Deployment completed successfully!" 