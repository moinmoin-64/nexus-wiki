#!/bin/bash

# Show SSH Public Key for GitHub Setup
# Purpose: Display the SSH public key that needs to be added to GitHub

set -e

echo "════════════════════════════════════════════════════════════════"
echo "🔐 PROJECT NEXUS - SSH PUBLIC KEY SETUP"
echo "════════════════════════════════════════════════════════════════"
echo ""

SSH_KEY_FILE="$HOME/.ssh/id_rsa.pub"

# Check if SSH key exists
if [ ! -f "$SSH_KEY_FILE" ]; then
    echo "❌ ERROR: SSH key not found at $SSH_KEY_FILE"
    echo ""
    echo "Run this first to generate the SSH key:"
    echo "  ./scripts/setup-ssh.sh"
    exit 1
fi

echo "📋 SSH PUBLIC KEY (copy the entire text below):"
echo ""
echo "───────────────────────────────────────────────────────────────────"
cat "$SSH_KEY_FILE"
echo ""
echo "───────────────────────────────────────────────────────────────────"
echo ""

# Show fingerprint for verification
echo "🆔 Key Fingerprint (for verification):"
ssh-keygen -lf "$SSH_KEY_FILE"
echo ""

echo "📌 NEXT STEPS:"
echo ""
echo "1. Copy the SSH PUBLIC KEY above (everything between the dashes)"
echo ""
echo "2. Go to GitHub SSH Keys Settings:"
echo "   https://github.com/settings/keys"
echo ""
echo "3. Click 'New SSH key'"
echo ""
echo "4. Title: 'Project Nexus - WSL Development Machine'"
echo ""
echo "5. Paste the public key in the Key field"
echo ""
echo "6. Click 'Add SSH key'"
echo ""
echo "7. Verify connection with:"
echo "   ssh -T git@github.com"
echo ""
echo "   Expected output:"
echo "   Hi moinmoin-64! You've successfully authenticated..."
echo ""

echo "✅ Setup complete! You can now run releases with:"
echo "   ./scripts/release.sh 0.1.0 \"Initial release message\""
echo ""
