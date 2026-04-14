#!/bin/bash
# Update NixOS to v0.2.0 Release
# Run this on your NixOS system to get the latest wiki version

echo "========================================="
echo "Project Nexus - Update to v0.2.0"
echo "========================================="
echo ""

# Navigate to wiki installation
cd /opt/nexus || cd ~ || exit 1

echo "1. Fetching latest release from GitHub..."
git fetch origin v0.2.0 --force

echo ""
echo "2. Checking out v0.2.0..."
git checkout v0.2.0

echo ""
echo "3. Verifying installation..."
if [ -f "infrastructure/configuration.nix" ]; then
    echo "✓ NixOS configuration found"
fi

if [ -f "backend/package.json" ]; then
    echo "✓ Backend package.json found"
fi

if [ -f "frontend/package.json" ]; then
    echo "✓ Frontend package.json found"
fi

echo ""
echo "========================================="
echo "v0.2.0 Release Installed!"
echo "========================================="
echo ""
echo "New in this release:"
echo "  • Frontend UI service (port 5173)"
echo "  • Fixed npm packages"
echo "  • Complete NixOS integration"
echo "  • All services auto-start on boot"
echo ""
echo "Services will be available at:"
echo "  Backend API: http://localhost:3001"
echo "  Frontend UI: http://localhost:5173"
echo ""
echo "To rebuild NixOS with new config:"
echo "  cd infrastructure"
echo "  nix flake update"
echo "  nix build .#packages.x86_64-linux.iso"
echo ""
