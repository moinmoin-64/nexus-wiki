#!/bin/bash
# Nexus Update Script (runs in ISO)
# - Run manually: $ update
# - Run automatically: Every Monday via systemd timer
# - Pulls latest code from GitHub, rebuilds, restarts services

set -e

# Configuration
REPO_URL="https://github.com/moinmoin-64/nexus-wiki.git"
REPO_DIR="/opt/nexus/repo"
BACKEND_DIR="$REPO_DIR/backend"
LOG_FILE="/var/log/nexus-update.log"

# Colors (for terminal output)
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Log function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Error handler
error() {
  echo -e "${RED}[ERROR] $1${NC}" | tee -a "$LOG_FILE"
  log "Update failed: $1"
  exit 1
}

# Success message
success() {
  echo -e "${GREEN}[✓] $1${NC}"
  log "✓ $1"
}

# Main update
update_nexus() {
  clear
  echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║  Project Nexus - Auto Update           ║${NC}"
  echo -e "${BLUE}║  $(date '+%Y-%m-%d %H:%M:%S')                    ║${NC}"
  echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
  echo ""
  
  log "Starting Nexus update process..."
  
  # Create repo directory if not exists
  mkdir -p "$REPO_DIR"
  
  # Clone or update repo
  if [ -d "$REPO_DIR/.git" ]; then
    log "📥 Pulling latest from GitHub..."
    cd "$REPO_DIR"
    git fetch origin
    git reset --hard origin/main
    success "Repository updated"
  else
    log "📥 Cloning repository from GitHub..."
    git clone "$REPO_URL" "$REPO_DIR"
    success "Repository cloned"
  fi
  
  cd "$REPO_DIR"
  
  # Get version
  if [ -f "VERSION" ]; then
    NEXUS_VERSION=$(cat VERSION)
    log "Version: $NEXUS_VERSION"
  else
    NEXUS_VERSION="unknown"
  fi
  
  # Build backend
  echo ""
  log "🔨 Building backend (TypeScript)..."
  cd "$BACKEND_DIR"
  
  npm ci --production 2>&1 | tee -a "$LOG_FILE"
  npm run build 2>&1 | tee -a "$LOG_FILE"
  success "Backend built successfully"
  
  # Run migrations
  echo ""
  log "🗄️  Running database migrations..."
  if npm run migrate 2>&1 | tee -a "$LOG_FILE"; then
    success "Database migrations completed"
  else
    log "⚠️  Migrations skipped or not available"
  fi
  
  # Stop services
  echo ""
  log "🛑 Stopping services..."
  sudo systemctl stop nexus-backend nexus-graph-mirror || true
  success "Services stopped"
  
  # Deploy built code
  log "📤 Deploying build artifacts..."
  sudo cp -r dist/* /opt/nexus/backend/dist/
  sudo cp -r services/* /opt/nexus/backend/services/ 2>/dev/null || true
  success "Build artifacts deployed"
  
  # Start services
  echo ""
  log "🚀 Starting services..."
  sudo systemctl start nexus-backend
  sleep 2
  sudo systemctl start nexus-graph-mirror
  success "Services started"
  
  # Wait for backend to be ready
  log "⏳ Waiting for backend health check..."
  for i in {1..30}; do
    if curl -s http://localhost:3001/health > /dev/null 2>&1; then
      success "Backend is healthy"
      break
    fi
    if [ $i -eq 30 ]; then
      error "Backend failed to start within 60 seconds"
    fi
    sleep 2
  done
  
  # Summary
  echo ""
  echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║   ✅ Update Completed Successfully!   ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
  echo ""
  echo "📊 Update Summary:"
  echo "   Version:  $NEXUS_VERSION"
  echo "   Updated:  $(date '+%Y-%m-%d %H:%M:%S')"
  echo "   Backend:  $(systemctl is-active nexus-backend)"
  echo "   Graph:    $(systemctl is-active nexus-graph-mirror)"
  echo ""
  
  log "✅ Update completed successfully"
}

# Check if running as part of automatic update
if [ "$1" = "--cron" ]; then
  # Running from systemd timer - less verbose output
  log "Starting scheduled update..."
  update_nexus >> "$LOG_FILE" 2>&1 || error "Scheduled update failed"
else
  # Running interactively via 'update' command
  update_nexus
fi
