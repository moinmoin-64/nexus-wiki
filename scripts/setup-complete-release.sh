#!/bin/bash

# Complete Release Setup in One Command
# Purpose: Set up SSH key, show instructions, and verify everything works

set -e

echo "════════════════════════════════════════════════════════════════"
echo "🚀 PROJECT NEXUS - COMPLETE RELEASE SETUP"
echo "════════════════════════════════════════════════════════════════"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Step 1: Ensure SSH key exists
echo "Step 1️⃣  Ensuring SSH key exists..."
echo ""

SSH_KEY_FILE="$HOME/.ssh/id_rsa"

if [ ! -f "$SSH_KEY_FILE" ]; then
    echo "⚙️  SSH key not found. Generating new SSH key..."
    echo ""
    
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    
    ssh-keygen -t ed25519 -f "$SSH_KEY_FILE" -N '' -C "nexus-release@$(whoami)-$(hostname)"
    
    echo "✅ SSH key generated"
else
    echo "✅ SSH key already exists"
fi
echo ""

# Step 2: Display SSH public key
echo "Step 2️⃣  SSH Public Key:"
echo ""
echo "───────────────────────────────────────────────────────────────────"
cat "${SSH_KEY_FILE}.pub"
echo "───────────────────────────────────────────────────────────────────"
echo ""

# Step 3: Show fingerprint
echo "Key Fingerprint (for verification):"
ssh-keygen -lf "${SSH_KEY_FILE}.pub"
echo ""

# Step 4: Test SSH connection
echo "Step 3️⃣  Testing SSH connection to GitHub..."
echo ""

if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "✅ SSH connection SUCCESSFUL!"
    echo ""
    SSH_OUTPUT=$(ssh -T git@github.com 2>&1 || true)
    echo "  $SSH_OUTPUT"
    echo ""
    READY_FOR_RELEASE=true
else
    echo "⚠️  SSH connection to GitHub not yet configured"
    echo ""
    READY_FOR_RELEASE=false
fi
echo ""

# Step 5: Git configuration
echo "Step 4️⃣  Verifying git configuration..."
echo ""

if [ -z "$(git -C "$PROJECT_DIR" config user.name)" ]; then
    echo "⚙️  Setting git user configuration..."
    git -C "$PROJECT_DIR" config user.name "Nexus Release Bot"
    git -C "$PROJECT_DIR" config user.email "nexus@release.bot.local"
fi

echo "✅ Git user: $(git -C "$PROJECT_DIR" config user.name)"
echo "✅ Git email: $(git -C "$PROJECT_DIR" config user.email)"
echo ""

# Step 6: Check repository status
echo "Step 5️⃣  Repository status:"
echo ""

cd "$PROJECT_DIR"

BRANCH=$(git rev-parse --abbrev-ref HEAD)
COMMITS=$(git rev-list --count HEAD)
REMOTE=$(git remote get-url origin)

echo "  Branch: $BRANCH"
echo "  Commits: $COMMITS"
echo "  Remote: $REMOTE"
echo "  Status: $([ -z "$(git status --porcelain)" ] && echo "Clean" || echo "Has changes")"
echo ""

# Step 7: Summary and next steps
echo "════════════════════════════════════════════════════════════════"
echo "📋 SETUP SUMMARY"
echo "════════════════════════════════════════════════════════════════"
echo ""

if [ "$READY_FOR_RELEASE" = true ]; then
    echo "✅ SETUP COMPLETE - READY FOR RELEASES!"
    echo ""
    echo "🚀 You can now make releases with:"
    echo ""
    echo "   ./scripts/release.sh 0.1.0 \"Your release message\""
    echo ""
else
    echo "⚠️  SETUP INCOMPLETE - GitHub SSH key not yet added"
    echo ""
    echo "📌 TO COMPLETE SETUP:"
    echo ""
    echo "1. Copy the SSH public key above (entire block)"
    echo ""
    echo "2. Go to GitHub SSH Keys: https://github.com/settings/keys"
    echo ""
    echo "3. Click 'New SSH key'"
    echo ""
    echo "4. Title: 'Nexus Release - WSL'"
    echo ""
    echo "5. Paste the public key"
    echo ""
    echo "6. Click 'Add SSH key'"
    echo ""
    echo "7. Verify with: ssh -T git@github.com"
    echo ""
    echo "8. Then run releases with:"
    echo ""
    echo "   ./scripts/release.sh 0.1.0 \"Your message\""
    echo ""
fi

echo ""
echo "📚 AVAILABLE COMMANDS:"
echo ""
echo "  ./scripts/show-ssh-key.sh      - Display SSH public key for GitHub"
echo "  ./scripts/verify-ssh.sh         - Test GitHub SSH connection"
echo "  ./scripts/trial-release.sh      - Test release without pushing"
echo "  ./scripts/release.sh VERSION    - Make actual release"
echo "  ./scripts/setup-release.sh      - Verify release dependencies"
echo ""

echo "📖 DOCUMENTATION:"
echo ""
echo "  READ: RELEASE_READY.md          - Complete release guide"
echo "  READ: AUTO_UPDATE_GUIDE.md      - Auto-update infrastructure"
echo "  READ: scripts/README.md         - Script reference"
echo ""
