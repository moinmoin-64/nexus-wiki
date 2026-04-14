#!/bin/bash
# Rebuild NixOS ISO with updated configuration including frontend service

set -e

echo "========================================="
echo "Building NixOS ISO with Project Nexus"
echo "========================================="
echo ""

cd /nix/var/nix/profiles/default/etc/profile.d
source nix-daemon.sh 2>/dev/null || true

cd /mnt/c/Users/olist/Programmieren/wiki/infrastructure

echo "1. Updating Nix flakes..."
nix flake update

echo ""
echo "2. Building NixOS ISO..."
echo "   (This takes 10-20 minutes - please be patient)"
echo ""

rm -rf result 2>/dev/null || true

nix build .#packages.x86_64-linux.iso

echo ""
echo "========================================="
echo "ISO Build Complete!"
echo "========================================="
echo ""

ISO_PATH=$(find result/iso -name "nixos-*.iso" 2>/dev/null | head -1)

if [ -n "$ISO_PATH" ]; then
    echo "✓ ISO created successfully"
    echo "  Path: $ISO_PATH"
    ls -lh "$ISO_PATH"
    echo ""
    echo "Next steps:"
    echo "  1. Copy the ISO to your VM/USB"
    echo "  2. Boot the new ISO"
    echo "  3. Run: sudo systemctl status postgresql neo4j redis nexus-backend nexus-frontend"
    echo "  4. All services should be running automatically"
else
    echo "✗ ISO build failed - could not find ISO file"
    exit 1
fi
