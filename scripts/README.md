# Scripts Directory - Nexus Release & Update

Contains helper scripts for managing Nexus releases and updates.

---

## 📋 Scripts Overview

### `release.sh` - Release Manager (Windows/WSL)

**Location**: `scripts/release.sh`  
**Purpose**: Build ISO and release new version to GitHub  
**Platform**: Windows (WSL) or Linux with Nix

#### Usage

```bash
./scripts/release.sh <version> [message]
```

#### Examples

```bash
# Release version 1.0.1 with default message
./scripts/release.sh 1.0.1

# Release with custom message
./scripts/release.sh 1.0.1 "Bugfixes and performance improvements"

# Release major version
./scripts/release.sh 2.0.0 "Breaking changes - new API"
```

#### What It Does

1. ✓ Validates version number
2. ✓ Updates NixOS flake dependencies
3. ✓ Builds NixOS ISO with nix build
4. ✓ Saves ISO to `release-artifacts/nexus-v${VERSION}.iso`
5. ✓ Commits changes with message
6. ✓ Creates Git tag: `v${VERSION}`
7. ✓ Pushes to GitHub (main branch + tags)

#### Requirements

- Nix package manager (Linux/WSL)
- Git with GitHub access
- ~10 GB free disk space
- 5-10 minutes build time

#### Output Example

```
╔════════════════════════════════════════╗
║   Nexus Release Manager (WSL/Windows)  ║
╚════════════════════════════════════════╝

📋 Release Information:
   Version: 1.0.1
   Message: Bugfixes and optimizations
   Repo:    https://github.com/moinmoin-64/nexus-wiki.git

🏗️  Building NixOS ISO...
   Running: nix flake update
   Running: nix build .#packages.x86_64-linux.iso

📤 Pushing to GitHub...
   ✓ Committed and tagged
   Pushing to remote...

╔════════════════════════════════════════╗
║   ✅ Release v1.0.1 Complete!         ║
╚════════════════════════════════════════╝

📊 Release Summary:
   Version:  v1.0.1
   ISO:      ./release-artifacts/nexus-v1.0.1.iso (485 MB)
   Repo:     https://github.com/moinmoin-64/nexus-wiki.git
   Branch:   main
   Commits:  42
```

---

### `update-nexus.sh` - Update Service (NixOS ISO)

**Location**: `/opt/nexus/scripts/update-nexus.sh`  
**Purpose**: Pull latest code, rebuild, and restart services  
**Platform**: NixOS ISO (runs on Proxmox VM)

#### Usage

```bash
# Manual update (interactive)
update

# Scheduled update (non-interactive logging)
sudo /opt/nexus/scripts/update-nexus.sh --cron
```

#### What It Does

1. ✓ Creates repo directories if needed
2. ✓ Clones or pulls latest from GitHub
3. ✓ Reads version from VERSION file
4. ✓ Installs dependencies via npm ci
5. ✓ Builds backend with TypeScript
6. ✓ Runs database migrations
7. ✓ Stops current services
8. ✓ Deploys built artifacts
9. ✓ Starts services
10. ✓ Waits for backend health check
11. ✓ Logs all actions

#### Output Example

```
╔════════════════════════════════════════╗
║  Project Nexus - Auto Update           ║
║  2026-04-13 14:32:15                   ║
╚════════════════════════════════════════╝

📥 Pulling latest from GitHub...
   ✓ Repository updated

🔨 Building backend (TypeScript)...
   ✓ Backend built successfully

🗄️  Running database migrations...
   ✓ Database migrations completed

🛑 Stopping services...
   ✓ Services stopped

📤 Deploying build artifacts...
   ✓ Build artifacts deployed

🚀 Starting services...
   ✓ Services started

⏳ Waiting for backend health check...
   ✓ Backend is healthy

╔════════════════════════════════════════╗
║   ✅ Update Completed Successfully!   ║
╚════════════════════════════════════════╝

📊 Update Summary:
   Version:  v1.0.1
   Updated:  2026-04-13 14:32:15
   Backend:  active (running)
   Graph:    active (running)
```

#### Manual Update

SSH to running ISO and run:

```bash
ssh -i ~/.ssh/id_rsa nexus@<vm-ip>
update
```

#### Automatic Update

- **Runs**: Every Monday at 02:00 UTC
- **Via**: systemd timer `nexus-update.timer`
- **Logs**: `/var/log/nexus-update.log` + journalctl

**Check timer:**

```bash
systemctl list-timers nexus-update
systemctl status nexus-update.timer
```

**View logs:**

```bash
journalctl -u nexus-update -f
tail -f /var/log/nexus-update.log
```

**Trigger manually:**

```bash
sudo systemctl start nexus-update.service
```

---

## 🔧 Setup

### Initial Setup

```bash
# 1. Clone repository
git clone https://github.com/moinmoin-64/nexus-wiki.git
cd nexus-wiki

# 2. Make scripts executable
chmod +x scripts/release.sh

# 3. Install Nix (on WSL if needed)
curl -L https://nixos.org/nix/install | sh -s -- --daemon

# 4. Test release script
./scripts/release.sh --help  # (doesn't exist yet, but validates setup)
```

### For ISO Updates

Updates are configured automatically in the NixOS system.

Access the `update` command in the ISO:

```bash
ssh nexus@<vm-ip>
update
```

---

## 📋 Configuration

### Repositories & URLs

**Main Repo:** `https://github.com/moinmoin-64/nexus-wiki.git`

Configured in:
- `scripts/release.sh` (REPO_URL)
- `scripts/update-nexus.sh` (REPO_URL)

### Build Configuration

**Nix Build Config**: `infrastructure/flake.nix`

- Builds: x86_64-linux ISO + QCOW2
- Uses: nixos-generators for ISO image generation
- Output: `result/iso/nixos-*.iso`

### Update Schedule

**Configured in**: `infrastructure/nexus-update.timer`

```
OnCalendar=Mon *-*-* 02:00:00  # Every Monday at 02:00 UTC
Persistent=true                # Resume if missed
AccuracySec=1min               # Accuracy within 1 minute
```

**To change schedule (edit configuration.nix):**

```nix
systemd.timers."nexus-update" = {
  timerConfig.OnCalendar = "Daily";  # or "Fri *-*-* 22:00:00"
};
```

---

## 🚀 Workflow

### Step 1: Develop (Windows/WSL)

```bash
# Make code changes
git add .
git commit -m "Your changes"
```

### Step 2: Release (Windows/WSL)

```bash
# Test locally
npm run build
npm test

# Release to GitHub
./scripts/release.sh 1.0.2 "New features"
```

### Step 3: Auto-Update (NixOS ISO)

**Option A: Wait for Monday**
- Systemd timer triggers automatic update at 02:00 UTC
- Logs recorded in journalctl + `/var/log/nexus-update.log`

**Option B: Manual Update**
```bash
ssh nexus@<vm-ip>
update
```

### Step 4: Verify

```bash
ssh nexus@<vm-ip>
curl http://localhost:3001/health
systemctl status nexus-backend
```

---

## 🐛 Troubleshooting

### Release Script Fails

**Problem**: `nix: command not found`

**Solution**:
```bash
# Install Nix in WSL
curl -L https://nixos.org/nix/install | sh -s -- --daemon

# Enable flakes in ~/.config/nix/nix.conf
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

**Problem**: `cannot find flake.lock`

**Solution**:
```bash
cd infrastructure
nix flake update
./scripts/release.sh 1.0.0
```

### Update Script Fails on ISO

**Problem**: Backend won't start after update

**Solution**:
```bash
ssh nexus@<vm-ip>
journalctl -u nexus-backend -n 50 -p err
systemctl restart nexus-backend
```

**Problem**: Git repository not found

**Solution**:
```bash
ssh nexus@<vm-ip>
mkdir -p /opt/nexus/repo
cd /opt/nexus/repo
git clone https://github.com/moinmoin-64/nexus-wiki.git .
update
```

---

## 📚 Additional Resources

- **Auto-Update Guide**: [AUTO_UPDATE_GUIDE.md](../infrastructure/AUTO_UPDATE_GUIDE.md)
- **Deployment Guide**: [DEPLOY_NEXUS_TUI.md](../infrastructure/DEPLOY_NEXUS_TUI.md)
- **Nix Flakes Docs**: https://nixos.wiki/wiki/Flakes
- **systemd timers**: https://www.freedesktop.org/software/systemd/man/systemd.timer.html

---

**Scripts are ready to use! 🚀**
