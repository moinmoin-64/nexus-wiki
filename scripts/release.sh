#!/bin/bash
# Nexus Release Script - Run on Windows/WSL to push new release to GitHub
# Usage: ./scripts/release.sh [version] [message]
# Example: ./scripts/release.sh 1.0.1 "Bugfixes and optimizations"

set -e

VERSION=${1:-""}
MESSAGE=${2:-"New release"}
REPO_URL="https://github.com/moinmoin-64/nexus-wiki.git"
BUILD_DIR="./infrastructure"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Nexus Release Manager (WSL/Windows)  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# Validate version
if [ -z "$VERSION" ]; then
  echo -e "${RED}❌ Version required!${NC}"
  echo "Usage: $0 <version> [message]"
  echo "Example: $0 1.0.1 'Bugfixes and optimizations'"
  exit 1
fi

# Check if we're in a git repo
if [ ! -d ".git" ]; then
  echo -e "${RED}❌ Not a git repository!${NC}"
  exit 1
fi

echo -e "${YELLOW}📋 Release Information:${NC}"
echo "   Version: $VERSION"
echo "   Message: $MESSAGE"
echo "   Repo:    $REPO_URL"
echo ""

# Build ISO
echo -e "${YELLOW}🏗️  Building NixOS ISO...${NC}"
cd "$BUILD_DIR"

if ! command -v nix &> /dev/null; then
  echo -e "${RED}❌ Nix not found! Make sure you're in WSL with nix-shell or nix installed.${NC}"
  exit 1
fi

echo "   Running: nix flake update"
nix flake update

echo "   Running: nix build .#packages.x86_64-linux.iso"
nix build .#packages.x86_64-linux.iso -v

# Copy ISO to release artifacts directory
RELEASE_DIR="../release-artifacts"
mkdir -p "$RELEASE_DIR"
ISO_FILE=$(ls -t result/iso/nixos-*.iso 2>/dev/null | head -1)

if [ -z "$ISO_FILE" ]; then
  echo -e "${RED}❌ ISO build failed!${NC}"
  exit 1
fi

ISO_BASENAME=$(basename "$ISO_FILE")
RELEASE_ISO="$RELEASE_DIR/nexus-v${VERSION}.iso"

echo "   Copying ISO to release artifacts..."
cp "$ISO_FILE" "$RELEASE_ISO"
echo -e "${GREEN}   ✅ ISO: $RELEASE_ISO${NC}"

cd - > /dev/null

# Prepare git commit
echo ""
echo -e "${YELLOW}📤 Pushing to GitHub...${NC}"

# Update version file
echo "$VERSION" > VERSION
echo "   Updated VERSION to $VERSION"

# Stage files (excluding release artifacts)
git add -A
git add -u

# Show what's being committed
echo ""
echo -e "${YELLOW}📝 Staged files:${NC}"
git diff --cached --name-only | head -10
echo ""

# Commit
git commit -m "Release v${VERSION}: ${MESSAGE}" || true

# Tag
git tag "v${VERSION}" -m "Release v${VERSION}: ${MESSAGE}" || {
  echo -e "${YELLOW}⚠️  Tag already exists, updating...${NC}"
  git tag -d "v${VERSION}" 2>/dev/null || true
  git tag "v${VERSION}" -m "Release v${VERSION}: ${MESSAGE}"
}

echo -e "${GREEN}✅ Committed and tagged${NC}"

# Push to GitHub
echo ""
echo -e "${YELLOW}Pushing to remote...${NC}"
git push origin main --follow-tags

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ Release v${VERSION} Complete!     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "📊 Release Summary:"
echo "   Version:  v${VERSION}"
echo "   ISO:      $RELEASE_ISO ($(du -h "$RELEASE_ISO" | cut -f1))"
echo "   Repo:     $REPO_URL"
echo "   Branch:   $(git branch --show-current)"
echo "   Commits:  $(git rev-list --count HEAD)"
echo ""
echo "🚀 Next: Pull on ISO to get latest version"
echo "   In NixOS VM: $ update"
echo "   (or automatically on Monday via cron)"
echo ""
