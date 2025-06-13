#!/bin/bash

# Build Auto-Connect Remotely Client
# This script builds the Remotely Desktop client with built-in auto-connect functionality

set -e

echo "🚀 Building Auto-Connect Remotely Client"
echo "========================================"

# Configuration
SERVER_IP="192.168.1.32"
SERVER_PORT="5001"
BUILD_CONFIG="Release"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] ✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ❌${NC} $1"
}

# Check if .NET SDK is installed
check_dotnet() {
    print_status "Checking .NET SDK..."
    if ! command -v dotnet &> /dev/null; then
        print_error ".NET SDK not found. Please install .NET 8.0 SDK"
        exit 1
    fi
    
    local dotnet_version=$(dotnet --version)
    print_success ".NET SDK found: $dotnet_version"
}

# Clean previous builds
clean_build() {
    print_status "Cleaning previous builds..."
    
    if [ -d "Desktop.Win/bin" ]; then
        rm -rf Desktop.Win/bin
    fi
    
    if [ -d "Desktop.Win/obj" ]; then
        rm -rf Desktop.Win/obj
    fi
    
    if [ -d "Desktop.Linux/bin" ]; then
        rm -rf Desktop.Linux/bin
    fi
    
    if [ -d "Desktop.Linux/obj" ]; then
        rm -rf Desktop.Linux/obj
    fi
    
    print_success "Build directories cleaned"
}

# Update auto-connect configuration
update_config() {
    print_status "Updating auto-connect configuration..."
    
    # Update the server URL in the AutoConnectConfig.cs file
    sed -i.bak "s|private const string DEFAULT_SERVER_URL = \".*\";|private const string DEFAULT_SERVER_URL = \"http://${SERVER_IP}:${SERVER_PORT}\";|" \
        Desktop.Shared/Services/AutoConnectConfig.cs
    
    print_success "Configuration updated: http://${SERVER_IP}:${SERVER_PORT}"
}

# Build Windows client
build_windows() {
    print_status "Building Windows client..."
    
    dotnet publish Desktop.Win/Desktop.Win.csproj \
        -c $BUILD_CONFIG \
        -r win-x64 \
        --self-contained true \
        -p:PublishSingleFile=true \
        -p:PublishTrimmed=false \
        -o "./build/windows/"
    
    if [ $? -eq 0 ]; then
        print_success "Windows client built successfully"
        
        # Create web directory and copy
        mkdir -p "./Server/wwwroot/Content/AI-Exam-Clients"
        
        # Rename and copy the executable
        if [ -f "./build/windows/Remotely_Desktop.exe" ]; then
            cp "./build/windows/Remotely_Desktop.exe" "./build/windows/AI-Exam-Client.exe"
            cp "./build/windows/Remotely_Desktop.exe" "./Server/wwwroot/Content/AI-Exam-Clients/AI-Exam-Client-win-x64.exe"
            print_success "Windows client copied to web directory"
        fi
    else
        print_error "Windows build failed"
        return 1
    fi
}

# Build Linux client
build_linux() {
    print_status "Building Linux client..."
    
    dotnet publish Desktop.Linux/Desktop.Linux.csproj \
        -c $BUILD_CONFIG \
        -r linux-x64 \
        --self-contained true \
        -p:PublishSingleFile=true \
        -p:PublishTrimmed=false \
        -o "./build/linux/"
    
    if [ $? -eq 0 ]; then
        print_success "Linux client built successfully"
        
        # Create web directory and copy
        mkdir -p "./Server/wwwroot/Content/AI-Exam-Clients"
        
        # Rename and copy the executable
        if [ -f "./build/linux/Remotely_Desktop" ]; then
            cp "./build/linux/Remotely_Desktop" "./build/linux/AI-Exam-Client"
            cp "./build/linux/Remotely_Desktop" "./Server/wwwroot/Content/AI-Exam-Clients/AI-Exam-Client-linux-x64"
            chmod +x "./build/linux/AI-Exam-Client"
            chmod +x "./Server/wwwroot/Content/AI-Exam-Clients/AI-Exam-Client-linux-x64"
            print_success "Linux client copied to web directory"
        fi
    else
        print_error "Linux build failed"
        return 1
    fi
}

# Build macOS client
build_macos() {
    print_status "Building macOS client..."
    
    dotnet publish Desktop.Linux/Desktop.Linux.csproj \
        -c $BUILD_CONFIG \
        -r osx-arm64 \
        --self-contained true \
        -p:PublishSingleFile=true \
        -p:PublishTrimmed=false \
        -o "./build/macos/"
    
    if [ $? -eq 0 ]; then
        print_success "macOS client built successfully"
        
        # Create web directory and copy
        mkdir -p "./Server/wwwroot/Content/AI-Exam-Clients"
        
        # Rename and copy the executable
        if [ -f "./build/macos/Remotely_Desktop" ]; then
            cp "./build/macos/Remotely_Desktop" "./build/macos/AI-Exam-Client"
            cp "./build/macos/Remotely_Desktop" "./Server/wwwroot/Content/AI-Exam-Clients/AI-Exam-Client-osx-arm64"
            chmod +x "./build/macos/AI-Exam-Client"
            chmod +x "./Server/wwwroot/Content/AI-Exam-Clients/AI-Exam-Client-osx-arm64"
            print_success "macOS client copied to web directory"
        fi
    else
        print_error "macOS build failed"
        return 1
    fi
}

# Create deployment packages
create_packages() {
    print_status "Creating deployment packages..."
    
    mkdir -p "./build/packages"
    
    # Windows package
    if [ -d "./build/windows" ]; then
        cd "./build/windows"
        zip -r "../packages/AI-Exam-Client-Windows.zip" .
        cd - > /dev/null
        print_success "Windows package created: AI-Exam-Client-Windows.zip"
    fi
    
    # Linux package
    if [ -d "./build/linux" ]; then
        cd "./build/linux"
        tar -czf "../packages/AI-Exam-Client-Linux.tar.gz" .
        cd - > /dev/null
        print_success "Linux package created: AI-Exam-Client-Linux.tar.gz"
    fi
    
    # macOS package
    if [ -d "./build/macos" ]; then
        cd "./build/macos"
        tar -czf "../packages/AI-Exam-Client-macOS.tar.gz" .
        cd - > /dev/null
        print_success "macOS package created: AI-Exam-Client-macOS.tar.gz"
    fi
}

# Create README for deployment
create_readme() {
    print_status "Creating deployment README..."
    
    cat > "./build/README.md" << EOF
# AI Exam Taker - Auto-Connect Client

## Overview

This is the auto-connect version of the Remotely Desktop client, pre-configured to automatically connect to your AI Exam Taker server.

## Configuration

- **Server**: http://${SERVER_IP}:${SERVER_PORT}
- **Device Name**: AI-Exam-Client
- **Auto-Connect**: Enabled
- **Hide Session ID**: Enabled

## Usage

### Windows
1. Extract \`AI-Exam-Client-Windows.zip\`
2. Run \`AI-Exam-Client.exe\`
3. Client will automatically connect to the server

### Linux
1. Extract \`AI-Exam-Client-Linux.tar.gz\`
2. Run \`./AI-Exam-Client\`
3. Client will automatically connect to the server

### macOS
1. Extract \`AI-Exam-Client-macOS.tar.gz\`
2. Run \`./AI-Exam-Client\`
3. Client will automatically connect to the server

## No Configuration Required

- No session IDs needed
- No manual server entry
- No user interaction required
- Automatic reconnection on network issues

## Troubleshooting

If the client doesn't connect:
1. Ensure the server is running at http://${SERVER_IP}:${SERVER_PORT}
2. Check network connectivity
3. Verify firewall settings allow connections
4. Check client logs for error messages

## Server Control

Once connected, the client will appear as "AI-Exam-Client" in your server's device list. You can then:
1. Select the device from the server interface
2. Start a remote control session
3. Use the AI Control features for automated exam taking

Built on: $(date)
Server: http://${SERVER_IP}:${SERVER_PORT}
EOF

    print_success "README created"
}

# Main build process
main() {
    print_status "Starting auto-connect client build process..."
    
    # Create build directory
    mkdir -p "./build"
    
    # Check prerequisites
    check_dotnet
    
    # Clean previous builds
    clean_build
    
    # Update configuration
    update_config
    
    # Build for different platforms
    print_status "Building for multiple platforms..."
    
    build_windows
    build_linux
    build_macos
    
    # Create packages
    create_packages
    
    # Create README
    create_readme
    
    echo
    print_success "Build process complete! 🎉"
    echo
    echo "📦 Built Packages:"
    if [ -f "./build/packages/AI-Exam-Client-Windows.zip" ]; then
        echo "  - Windows: ./build/packages/AI-Exam-Client-Windows.zip"
    fi
    if [ -f "./build/packages/AI-Exam-Client-Linux.tar.gz" ]; then
        echo "  - Linux: ./build/packages/AI-Exam-Client-Linux.tar.gz"
    fi
    if [ -f "./build/packages/AI-Exam-Client-macOS.tar.gz" ]; then
        echo "  - macOS: ./build/packages/AI-Exam-Client-macOS.tar.gz"
    fi
    echo
    echo "🔧 Configuration:"
    echo "  - Server: http://${SERVER_IP}:${SERVER_PORT}"
    echo "  - Auto-Connect: Enabled"
    echo "  - Device Name: AI-Exam-Client"
    echo
    echo "📋 Next Steps:"
    echo "1. Deploy the appropriate package to target machines"
    echo "2. Run the client executable"
    echo "3. Client will automatically connect to your server"
    echo "4. No user interaction required!"
    echo
    print_success "Ready for deployment! 🚀"
}

# Run main function
main "$@" 