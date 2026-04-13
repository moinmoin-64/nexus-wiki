#!/bin/bash
# Git Initialization Script for Nexus Wiki Repository
# Run this in WSL to set up git properly

set -e

echo "🔧 Setting up Git for Nexus Wiki Repository"
echo "════════════════════════════════════════════"
echo ""

CD_PATH="/mnt/c/Users/olist/Programmieren/wiki"

if [ ! -d "$CD_PATH" ]; then
  echo "❌ Directory not found: $CD_PATH"
  exit 1
fi

cd "$CD_PATH"
echo "📁 Working in: $(pwd)"
echo ""

# Initialize git repo
echo "🔧 Initializing Git repository..."
git init
git config user.name "Oliver"
git config user.email "olist@Oliver.local"

echo ""
echo "📦 Adding all files..."
git add .

echo ""
echo "💾 First commit..."
git commit -m "Initial commit: Project Nexus with auto-update system"

echo ""
echo "🔗 Adding GitHub remote..."
git remote add origin https://github.com/moinmoin-64/nexus-wiki.git || {
  echo "⚠️  Remote already exists, updating..."
  git remote set-url origin https://github.com/moinmoin-64/nexus-wiki.git
}

echo ""
echo "✅ Git initialization complete!"
echo ""
echo "📋 Next steps:"
echo ""
echo "1. Setup GitHub SSH key (if not done):"
echo "   ssh-keygen -t ed25519 -f ~/.ssh/id_rsa -N ''"
echo "   cat ~/.ssh/id_rsa.pub  # Copy to GitHub Settings → SSH Keys"
echo ""
echo "2. Change remote to SSH (better for automation):"
echo "   git remote set-url origin git@github.com:moinmoin-64/nexus-wiki.git"
echo ""
echo "3. Now you can release:"
echo "   ./scripts/release.sh 1.0.1"
echo ""
echo "📊 Git status:"
git status
echo ""
