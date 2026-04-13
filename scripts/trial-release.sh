#!/bin/bash

# Trial Release - Test Release Without Pushing
# Purpose: Verify release process locally before actual deployment

set -e

echo "════════════════════════════════════════════════════════════════"
echo "🧪 PROJECT NEXUS - TRIAL RELEASE (LOCAL ONLY)"
echo "════════════════════════════════════════════════════════════════"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RELEASE_ARTIFACTS="$PROJECT_DIR/release-artifacts"

# Get version from arguments
TRIAL_VERSION="${1:-0.1.0}"
TRIAL_MESSAGE="${2:-Trial release for testing}"

echo "📋 Trial Release Configuration:"
echo "  Version: $TRIAL_VERSION"
echo "  Message: $TRIAL_MESSAGE"
echo "  Mode: LOCAL ONLY (no push to GitHub)"
echo ""

# Step 1: Verify version format
echo "Step 1: Validating version format..."
if ! [[ $TRIAL_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Invalid version format: $TRIAL_VERSION"
    echo "   Expected format: X.Y.Z (e.g., 0.1.0)"
    exit 1
fi
echo "✅ Version format valid"
echo ""

# Step 2: Check working directory is clean
echo "Step 2: Checking working directory..."
if [ -n "$(git -C "$PROJECT_DIR" status --porcelain)" ]; then
    echo "⚠️  WARNING: Working directory has uncommitted changes"
    echo ""
    git -C "$PROJECT_DIR" status
    echo ""
    echo "Commit changes before release:"
    echo "  git add ."
    echo "  git commit -m 'Your message'"
    exit 1
fi
echo "✅ Working directory clean"
echo ""

# Step 3: Verify SSH connection (if pushing to GitHub)
echo "Step 3: Checking SSH connection to GitHub..."
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "✅ SSH connection working"
    GITHUB_READY=true
else
    echo "⚠️  SSH connection to GitHub not working"
    echo "   You can still build locally, but won't be able to push"
    GITHUB_READY=false
fi
echo ""

# Step 4: Update VERSION file
echo "Step 4: Updating VERSION file..."
echo "$TRIAL_VERSION" > "$PROJECT_DIR/VERSION"
echo "✅ VERSION updated to $TRIAL_VERSION"
echo ""

# Step 5: Update flake.nix version
echo "Step 5: Updating flake.nix version..."
if [ -f "$PROJECT_DIR/flake.nix" ]; then
    sed -i.bak "s/version = \"[^\"]*\"/version = \"$TRIAL_VERSION\"/g" "$PROJECT_DIR/flake.nix"
    rm -f "$PROJECT_DIR/flake.nix.bak"
    echo "✅ flake.nix version updated"
else
    echo "⚠️  flake.nix not found"
fi
echo ""

# Step 6: Update Nix flake lock
echo "Step 6: Updating Nix flake..."
if command -v nix &> /dev/null; then
    cd "$PROJECT_DIR"
    nix flake update
    echo "✅ Nix flake updated"
else
    echo "⚠️  Nix not available, skipping flake update"
fi
echo ""

# Step 7: Build ISO
echo "Step 7: Building NixOS ISO (This takes 5-10 minutes)..."
echo ""

ISO_BUILD_OUTPUT=$(mktemp)

if nix build "$PROJECT_DIR#nixosConfigurations.nexusISO.config.system.build.isoImage" \
    --out-link "$PROJECT_DIR/result-iso" 2>&1 | tee "$ISO_BUILD_OUTPUT"; then
    
    ISO_PATH="$PROJECT_DIR/result-iso/iso/nexus-*.iso"
    
    if ls $ISO_PATH 1> /dev/null 2>&1; then
        LATEST_ISO=$(ls -t $ISO_PATH | head -1)
        ISO_SIZE=$(du -h "$LATEST_ISO" | cut -f1)
        
        echo ""
        echo "✅ ISO Build SUCCESSFUL!"
        echo ""
        echo "📦 ISO Information:"
        echo "  Path: $LATEST_ISO"
        echo "  Size: $ISO_SIZE"
        echo "  Created: $(date -r "$LATEST_ISO" '+%Y-%m-%d %H:%M:%S')"
        echo ""
    else
        echo "❌ ISO build succeeded but file not found"
        exit 1
    fi
else
    echo "❌ ISO Build FAILED"
    echo ""
    echo "Check the error output above"
    exit 1
fi
rm -f "$ISO_BUILD_OUTPUT"
echo ""

# Step 8: Create git commit (but don't push)
echo "Step 8: Creating git commit..."
cd "$PROJECT_DIR"

git add VERSION flake.nix flake.lock 2>/dev/null || true
git add infrastructure/configuration.nix 2>/dev/null || true

if git commit -m "Trial release v$TRIAL_VERSION: $TRIAL_MESSAGE" 2>/dev/null || true; then
    echo "✅ Git commit created"
fi
echo ""

# Step 9: Create git tag (but don't push)
echo "Step 9: Creating git tag..."
git tag -a "v$TRIAL_VERSION-trial" -m "Trial release: $TRIAL_MESSAGE" || true
echo "✅ Git tag created (v$TRIAL_VERSION-trial)"
echo ""

# Step 10: Summary
echo "════════════════════════════════════════════════════════════════"
echo "✅ TRIAL RELEASE COMPLETE (LOCAL ONLY)"
echo "════════════════════════════════════════════════════════════════"
echo ""

echo "📊 Release Summary:"
echo "  Version: $TRIAL_VERSION"
echo "  ISO: $(basename "$LATEST_ISO")"
echo "  Size: $ISO_SIZE"
echo ""

if [ "$GITHUB_READY" = true ]; then
    echo "🚀 NEXT STEP: Push to GitHub"
    echo ""
    echo "To push this release to GitHub, run:"
    echo "  ./scripts/release.sh $TRIAL_VERSION \"$TRIAL_MESSAGE\""
    echo ""
else
    echo "⚠️  To push to GitHub, first:"
    echo "  1. Add SSH key to GitHub: ./scripts/show-ssh-key.sh"
    echo "  2. Verify SSH: ./scripts/verify-ssh.sh"
    echo "  3. Push release: ./scripts/release.sh $TRIAL_VERSION \"$TRIAL_MESSAGE\""
    echo ""
fi

echo "📍 Local Changes:"
echo "  Git tag: v$TRIAL_VERSION-trial (not pushed)"
echo "  Git commit: Changes staged locally (not pushed)"
echo "  ISO location: $LATEST_ISO"
echo ""

echo "To delete trial tag and try again:"
echo "  git tag -d v$TRIAL_VERSION-trial"
echo ""
