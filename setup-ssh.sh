#!/bin/bash
# SSH Setup for GitHub - Run this in WSL
# This allows automatic git push from release.sh without password

set -e

echo "🔐 GitHub SSH Key Setup"
echo "════════════════════════════════════════════════"
echo ""

# Check if key already exists
if [ -f ~/.ssh/id_rsa ]; then
  echo "⚠️  SSH key already exists at ~/.ssh/id_rsa"
  echo ""
  echo "Using existing key. Public key:"
  cat ~/.ssh/id_rsa.pub | head -1
  echo ""
else
  echo "🔑 Generating new SSH key..."
  ssh-keygen -t ed25519 -f ~/.ssh/id_rsa -N "" -C "github-nexus-$(date +%Y%m%d)"
  echo "✅ SSH key created"
  echo ""
fi

# Display public key
echo "📋 Copy this public key to GitHub:"
echo "════════════════════════════════════════════════"
cat ~/.ssh/id_rsa.pub
echo ""
echo "════════════════════════════════════════════════"
echo ""
echo "📖 Steps to add key to GitHub:"
echo "   1. Go to: https://github.com/settings/keys"
echo "   2. Click 'New SSH key'"
echo "   3. Title: 'Nexus Release (WSL)'"
echo "   4. Paste the public key above"
echo "   5. Add SSH key"
echo ""

# Test GitHub connection
echo "🧪 Testing GitHub connection..."
if ssh -o StrictHostKeyChecking=no -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  echo "✅ Successfully authenticated to GitHub!"
else
  echo "⏳ First connection to GitHub - adding to known_hosts..."
  ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null
  echo "⚠️  Key added to known_hosts. Try release.sh again after adding key to GitHub."
fi

echo ""
echo "🚀 You can now run:"
echo "   cd /mnt/c/Users/olist/Programmieren/wiki"
echo "   git remote set-url origin git@github.com:moinmoin-64/nexus-wiki.git"
echo "   ./scripts/release.sh 1.0.1 'Auto-update system ready'"
echo ""
