#!/bin/bash
# Health Companion - Quick Setup Script
# Run this ONCE to prepare everything for docker-compose
#
# Usage:
#   chmod +x setup.sh
#   ./setup.sh
#   docker-compose up -d --build

set -e

echo "=========================================="
echo "  Health Companion - Setup"
echo "=========================================="

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Please run this script from the health-companion-flutter directory"
    exit 1
fi

# Clone the API repo if not present
if [ ! -d "../bp-tracker" ] || [ ! -f "../bp-tracker/server/index.js" ]; then
    echo "📦 Cloning Health Companion API repo..."
    cd ..
    git clone https://github.com/raghuraminnet/health-companion-api.git bp-tracker
    cd health-companion-flutter
else
    echo "✅ API repo already present"
fi

# Check for docker-compose
if ! command -v docker-compose &> /dev/null && ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

echo ""
echo "=========================================="
echo "  ✅ Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. docker-compose up -d --build"
echo "  2. Wait ~2-3 minutes for everything to build/start"
echo "  3. Access app at http://YOUR_SERVER_IP:3002"
echo ""
echo "Services:"
echo " 🌐 Flutter Web:  http://localhost:3002"
echo "  🔗 API: http://localhost:38257"
echo "  🗄️  PostgreSQL:  localhost:5432"
echo ""
echo "Database credentials:"
echo "  User:     healthuser"
echo "  Password:  healthpass123"
echo "  Database: healthapp"
echo ""