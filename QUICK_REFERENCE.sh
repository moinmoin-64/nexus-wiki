#!/usr/bin/env bash
# Nexus Release & Update - Quick Reference
# Copy this for quick access on Windows/WSL & NixOS ISO

# ═══════════════════════════════════════════════════════════════════════════
# WINDOWS/WSL - RELEASE MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════

# Release new version (builds ISO, commits, tags, pushes)
# Usage: release.sh <version> [message]

release() {
  cd ~/Programmieren/wiki  # Adjust path as needed
  ./scripts/release.sh "$@"
}

# Examples:
# release 1.0.1
# release 1.0.1 "Bugfixes and optimizations"
# release 2.0.0 "Major update with new features"

# View git log
show_releases() {
  cd ~/Programmieren/wiki
  git log --oneline --tags -10
}

# ═══════════════════════════════════════════════════════════════════════════
# NIXOS ISO - UPDATE COMMANDS
# ═══════════════════════════════════════════════════════════════════════════

# Manual update to latest version
update_cmd() {
  update
}

# View update logs
update_logs() {
  journalctl -u nexus-update -f
}

# Check update timer schedule
update_schedule() {
  systemctl list-timers nexus-update --all
}

# View last update
update_last() {
  journalctl -u nexus-update -n 50 --no-pager
}

# Manually trigger update (same as automatic)
update_now() {
  sudo /opt/nexus/scripts/update-nexus.sh --cron
}

# View current version
current_version() {
  cat /opt/nexus/VERSION || echo "Unknown"
}

# ═══════════════════════════════════════════════════════════════════════════
# MONITORING
# ═══════════════════════════════════════════════════════════════════════════

# Check all services after update
status_all() {
  echo "Backend:"
  systemctl status nexus-backend --no-pager
  echo ""
  echo "Graph Mirror:"
  systemctl status nexus-graph-mirror --no-pager
  echo ""
  echo "PostgreSQL:"
  systemctl status postgresql --no-pager
}

# Quick health check
health_check() {
  echo "Checking services..."
  curl -s http://localhost:3001/health | jq . && echo "✅ OK"
}

# Logs for debugging
follow_logs() {
  journalctl -u nexus-backend -u nexus-graph-mirror -f
}

# ═══════════════════════════════════════════════════════════════════════════
# GIT COMMANDS
# ═══════════════════════════════════════════════════════════════════════════

# Add functions to your .bashrc or .zshrc:

# cd ~/Programmieren/wiki
# source this file

# Quick access
alias nexus-repo="cd ~/Programmieren/wiki"  # Adjust path
alias nexus-build="cd ~/Programmieren/wiki/infrastructure && nix build .#packages.x86_64-linux.iso"

# Git helpers
alias git-log-nexus="git log --oneline --graph --all"
alias git-tags="git tag -l | sort -V"

# ═══════════════════════════════════════════════════════════════════════════
# COMPLETE WORKFLOW EXAMPLE
# ═══════════════════════════════════════════════════════════════════════════

complete_workflow() {
  echo "📋 Complete Nexus Release & Update Workflow"
  echo ""
  echo "1. Make changes locally on Windows/WSL:"
  echo "   $ cd ~/Programmieren/wiki"
  echo "   $ git add ."
  echo "   $ git commit -m 'Your changes'"
  echo ""
  echo "2. Release new version:"
  echo "   $ ./scripts/release.sh 1.0.2 'New features'"
  echo "   ✓ Builds ISO"
  echo "   ✓ Commits & tags"
  echo "   ✓ Pushes to GitHub"
  echo ""
  echo "3. On NixOS ISO (automatic or manual):"
  echo "   $ update"
  echo "   ✓ Pulls latest from GitHub"
  echo "   ✓ Rebuilds backend"
  echo "   ✓ Restarts services"
  echo ""
  echo "4. Verify:"
  echo "   $ systemctl status nexus-backend"
  echo "   $ curl http://localhost:3001/health"
  echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# TROUBLESHOOTING
# ═══════════════════════════════════════════════════════════════════════════

troubleshoot_update() {
  echo "🔧 Update Troubleshooting"
  echo ""
  echo "1. Check update service status:"
  systemctl status nexus-update.service --no-pager || true
  echo ""
  echo "2. View recent update attempts:"
  journalctl -u nexus-update -n 20 --no-pager
  echo ""
  echo "3. Check Git repo:"
  ls -la /opt/nexus/repo/.git || echo "❌ Repo not cloned"
  echo ""
  echo "4. Manual update test:"
  echo "   $ sudo /opt/nexus/scripts/update-nexus.sh --cron"
}

troubleshoot_release() {
  echo "🔧 Release Troubleshooting"
  echo ""
  echo "1. Check nix is installed:"
  nix --version || echo "❌ Nix not found"
  echo ""
  echo "2. Check git repository:"
  git status
  echo ""
  echo "3. Try minimal release:"
  echo "   $ ./scripts/release.sh 0.0.1 'Test release'"
}

# ═══════════════════════════════════════════════════════════════════════════
# DOCUMENTATION LINKS
# ═══════════════════════════════════════════════════════════════════════════

echo "📚 Documentation:"
echo "   Auto-Update Guide: infrastructure/AUTO_UPDATE_GUIDE.md"
echo "   Deployment Guide:  infrastructure/DEPLOY_NEXUS_TUI.md"
echo ""
echo "💻 Quick commands:"
echo "   release <version> [message]  - Release new version"
echo "   update                       - Manual update on ISO"
echo "   current_version              - Show current version"
echo "   health_check                 - Quick health check"
echo "   follow_logs                  - Follow service logs"
echo "   complete_workflow            - Show full workflow"
