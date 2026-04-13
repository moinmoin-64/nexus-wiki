#!/bin/bash
# Quick setup guide for Windows/WSL to enable Nexus release management

set -e

echo "🚀 Nexus Release System Setup"
echo "═════════════════════════════════════════════════════════════"
echo ""

# Check if in repo
if [ ! -d ".git" ]; then
  echo "❌ Not in a git repository!"
  echo "Run: cd ~/Programmieren/wiki"
  exit 1
fi

# Check Nix installation
if ! command -v nix &> /dev/null; then
  echo "⚠️  Nix not found"
  echo ""
  echo "To install Nix in WSL, run:"
  echo "  curl -L https://nixos.org/nix/install | sh -s -- --daemon"
  echo ""
  echo "Or install via package manager:"
  echo "  sudo apt install nix-bin  # Ubuntu/Debian"
  echo ""
  exit 1
fi

echo "✅ Git repository found"
echo "✅ Nix installed (version: $(nix --version))"
echo ""

# Check flakes enabled
echo "Checking Nix flakes support..."
if nix flake --version 2>/dev/null || nix flake show --version 2>/dev/null; then
  echo "✅ Nix flakes enabled"
else
  echo "⚠️  Flakes may not be enabled"
  echo "   Edit ~/.config/nix/nix.conf and add:"
  echo "   experimental-features = nix-command flakes"
fi

echo ""
echo "═════════════════════════════════════════════════════════════"
echo "✅ SETUP COMPLETE!"
echo "═════════════════════════════════════════════════════════════"
echo ""
echo "📋 Next steps:"
echo ""
echo "1. Make code changes"
echo "   $ git add . && git commit -m 'Your changes'"
echo ""
echo "2. Release new version (builds ISO automatically)"
echo "   $ ./scripts/release.sh 0.1.0 'Initial release'"
echo ""
echo "3. Wait for GitHub to build and publish"
echo "   $ git tag  # View tags"
echo ""
echo "4. On NixOS ISO, update manually anytime"
echo "   $ update"
echo ""
echo "5. Updates run automatically every Monday at 02:00 UTC"
echo ""
echo "📚 Documentation:"
echo "   - scripts/README.md                 # Scripts overview"
echo "   - infrastructure/AUTO_UPDATE_GUIDE.md  # Full guide"
echo "   - QUICK_REFERENCE.sh                # Quick commands"
echo ""
