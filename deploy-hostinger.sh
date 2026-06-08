#!/bin/bash
# Flutter Health Companion - Hostinger Docker Deploy Script
# Run this on your Hostinger VPS after uploading files

set -e

echo "🐳 Building Flutter Health Companion Docker image..."

# Build the Docker image
docker build -t health-companion-flutter .

# Run with docker-compose (if available)
if command -v docker-compose &> /dev/null; then
    echo "🚀 Starting with docker-compose..."
    docker-compose up -d
else
    echo "🚀 Starting with docker run..."
    docker run -d \
        --name health-companion-flutter \
        -p 3002:80 \
        --restart unless-stopped \
        health-companion-flutter
fi

echo "✅ Health Companion Flutter app deployed!"
echo "📱 Access at: http://YOUR_SERVER_IP:3002"