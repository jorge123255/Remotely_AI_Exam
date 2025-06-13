#!/bin/bash

# Automated Remotely AI Docker Build Script v2.0
# Enhanced with comprehensive error handling and logging

set -e

echo "🚀 Building Remotely AI Exam Container v2.0"
echo "============================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to handle build failure
handle_failure() {
    log "❌ Build failed at step: $1"
    log "🔍 Checking for common issues..."
    
    # Check disk space
    df -h
    
    # Check Docker status
    docker system df
    
    log "💡 Try running: docker system prune -f"
    exit 1
}

# Cleanup previous builds
log "🧹 Cleaning up previous builds..."
docker system prune -f || true
docker rmi remotely-ai-exam:latest || true

# Build with progress tracking
log "🔨 Starting Docker build..."
docker build \
    -f Dockerfile.ai \
    -t remotely-ai-exam:latest \
    --progress=plain \
    --no-cache \
    . || handle_failure "Docker build"

log "✅ Build completed successfully!"

# Verify the image
log "🔍 Verifying built image..."
docker images | grep remotely-ai-exam || handle_failure "Image verification"

log "🎉 Remotely AI Exam container is ready!"
log "📋 To run: docker run -p 5000:5000 remotely-ai-exam:latest"

# Optional: Test the container
read -p "🤔 Would you like to test the container now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "🧪 Testing container..."
    docker run --rm -d -p 5000:5000 --name remotely-ai-test remotely-ai-exam:latest
    
    # Wait for startup
    sleep 10
    
    # Test health endpoint
    if curl -f http://localhost:5000/health 2>/dev/null; then
        log "✅ Container is healthy!"
    else
        log "⚠️  Health check failed, but container may still be starting..."
    fi
    
    # Stop test container
    docker stop remotely-ai-test || true
    log "🛑 Test container stopped"
fi

log "🎯 Build process complete!"
