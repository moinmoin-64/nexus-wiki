#!/bin/bash

# Build Project Nexus NixOS ISO
# Usage: ./build-iso.sh

set -e

echo "🔨 Building Project Nexus NixOS TUI Appliance ISO..."

cd "$(dirname "$0")"

# Update flake
echo "📦 Updating nix flakes..."
nix flake update

# Build ISO
echo "🏗️  Building ISO image..."
nix build .#packages.x86_64-linux.iso -v

# Result location
ISO_PATH="./result/iso/nixos-*.iso"

echo ""
echo "✅ Build complete!"
echo ""
echo "ISO Location: $(ls $ISO_PATH 2>/dev/null || echo 'result/iso/')"
echo ""
echo "🚀 Next steps:"
echo "  1. Upload ISO to Proxmox"
echo "  2. Create VM with:"
echo "     - 4 CPU cores"
echo "     - 8 GB RAM"
echo "     - 50 GB storage"
echo "  3. Boot from ISO"
echo "  4. Services auto-start on boot"
echo ""
echo "Access:"
echo "  Web UI:  http://vm-ip"
echo "  API:     http://vm-ip:3001"
echo "  SSH:     ssh -i key nexus@vm-ip"
echo ""
