#!/bin/bash

# Verify SSH Connection to GitHub
# Purpose: Test that SSH key is properly configured for GitHub

set -e

echo "════════════════════════════════════════════════════════════════"
echo "🔐 PROJECT NEXUS - SSH CONNECTION VERIFICATION"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Step 1: Check SSH key exists
echo "Step 1: Checking SSH key..."
SSH_KEY_FILE="$HOME/.ssh/id_rsa"

if [ ! -f "$SSH_KEY_FILE" ]; then
    echo "❌ SSH key not found at $SSH_KEY_FILE"
    echo ""
    echo "Generate SSH key with:"
    echo "  ./scripts/setup-ssh.sh"
    exit 1
fi
echo "✅ SSH key found"
echo ""

# Step 2: Check SSH agent is running
echo "Step 2: Checking SSH agent..."
if ! ssh-add -l > /dev/null 2>&1; then
    echo "⚠️  Starting SSH agent..."
    eval "$(ssh-agent -s)" > /dev/null
    ssh-add "$SSH_KEY_FILE" > /dev/null 2>&1
fi
echo "✅ SSH agent running"
echo ""

# Step 3: Test GitHub connection
echo "Step 3: Testing GitHub SSH connection..."
echo ""

if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "✅ SSH connection SUCCESSFUL!"
    echo ""
    SSH_OUTPUT=$(ssh -T git@github.com 2>&1 || true)
    echo "GitHub response:"
    echo "  $SSH_OUTPUT"
    echo ""
    echo "✅ YOU ARE READY TO MAKE RELEASES!"
    echo ""
    echo "To make your first release, run:"
    echo "  ./scripts/release.sh 0.1.0 \"Initial release with auto-update\""
    exit 0
else
    echo "❌ SSH connection FAILED"
    echo ""
    echo "Troubleshooting:"
    echo ""
    echo "1. Verify SSH public key is added to GitHub:"
    echo "   https://github.com/settings/keys"
    echo ""
    echo "2. Show your SSH public key:"
    echo "   ./scripts/show-ssh-key.sh"
    echo ""
    echo "3. Test SSH connection manually:"
    echo "   ssh -vvv git@github.com"
    echo ""
    echo "4. If you see 'Permission denied', re-add the SSH key to GitHub"
    echo ""
    exit 1
fi
