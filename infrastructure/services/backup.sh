#!/bin/bash
set -e

# Nexus Backup Script
# Backs up PostgreSQL database and pushes to GitHub repository

LOG_FILE="/var/log/nexus-backup.log"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/nexus}"
BACKUP_REPO="${BACKUP_REPO:-git@github.com:YOUR_GITHUB_USERNAME/nexus-backups.git}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-nexus_user}"
DB_NAME="${DB_NAME:-nexus_db}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ENCRYPTION_KEY="${ENCRYPTION_KEY:-/etc/nexus/backup.key}"

# Logging function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $@" | tee -a "$LOG_FILE"
}

log "============================================"
log "Starting Nexus backup at $(date)"
log "============================================"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR"

# Initialize git repo if needed
if [ ! -d ".git" ]; then
  log "Initializing git repository..."
  git init
  git config user.name "Nexus Backup"
  git config user.email "nexus@wiki-oliver.duckdns.org"
  git remote add origin "$BACKUP_REPO" || true
fi

# PostgreSQL Dump
log "Creating PostgreSQL dump..."
BACKUP_FILE="$BACKUP_DIR/nexus_db_$TIMESTAMP.sql.gz"
PGPASSWORD="$DB_USER" pg_dump \
  -h "$DB_HOST" \
  -p "$DB_PORT" \
  -U "$DB_USER" \
  -d "$DB_NAME" \
  --verbose \
  --format=plain | gzip > "$BACKUP_FILE"

log "PostgreSQL dump created: $BACKUP_FILE (size: $(du -h "$BACKUP_FILE" | cut -f1))"

# Encrypt backup if encryption key exists
if [ -f "$ENCRYPTION_KEY" ]; then
  log "Encrypting backup..."
  openssl enc -aes-256-cbc \
    -in "$BACKUP_FILE" \
    -out "$BACKUP_FILE.enc" \
    -K $(cat "$ENCRYPTION_KEY" | xxd -p -c 256) \
    -iv $(openssl rand -hex 16)
  rm "$BACKUP_FILE"
  BACKUP_FILE="$BACKUP_FILE.enc"
  log "Backup encrypted"
fi

# Git commit and push
log "Committing to git..."
git add "nexus_db_$TIMESTAMP.sql.gz"*
git commit -m "Nexus backup - $TIMESTAMP" || log "No new changes to commit"

log "Pushing to remote..."
git push origin main -u || git push origin master -u || log "Could not push to remote (may not be configured)"

# Cleanup old backups (keep last 10)
log "Cleaning up old backups (keeping last 10)..."
ls -1t nexus_db_*.sql.gz* 2>/dev/null | tail -n +11 | xargs -r rm

log "============================================"
log "Backup completed successfully at $(date)"
log "============================================"
