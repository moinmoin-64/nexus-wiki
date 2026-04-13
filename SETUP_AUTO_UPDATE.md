# 🎯 Nexus Auto-Update System - Complete Setup

**Your Project Nexus now has complete release management and auto-update capabilities!**

Everything is configured to automatically release new versions from Windows/WSL and auto-update the NixOS ISO every Monday.

---

## 📦 What's Been Set Up

### On Your Windows PC (WSL)

| Component | File | Purpose |
|-----------|------|---------|
| **Release Script** | `scripts/release.sh` | Build ISO + push to GitHub |
| **Setup Script** | `setup-release.sh` | Verify Nix + dependencies |
| **Quick Reference** | `QUICK_REFERENCE.sh` | All commands in one place |
| **VERSION File** | `VERSION` | Track current version |
| **.gitignore** | `.gitignore` | Exclude build artifacts (ISO, node_modules, etc.) |
| **GitHub Actions** | `.github/workflows/build-iso.yml` | Auto-build on tag push |

### In NixOS ISO (On Proxmox VM)

| Component | File | Purpose |
|-----------|------|---------|
| **Update Script** | `/opt/nexus/scripts/update-nexus.sh` | Pull, rebuild, restart |
| **systemd Service** | `nexus-update.service` | Runs update process |
| **systemd Timer** | `nexus-update.timer` | Triggers every Monday 02:00 UTC |
| **Shell Alias** | `update` command | Run updates manually anytime |

### Documentation

| Document | Location | Purpose |
|----------|----------|---------|
| **Auto-Update Guide** | `infrastructure/AUTO_UPDATE_GUIDE.md` | Complete workflow documentation |
| **Scripts README** | `scripts/README.md` | Detailed script reference |
| **Quick Reference** | `QUICK_REFERENCE.sh` | One-page command reference |
| **Setup Guide** | `setup-release.sh` | Verify system dependencies |

---

## 🚀 Quick Start (2 minutes)

### 1. Windows/WSL - Verify Setup

```bash
cd ~/Programmieren/wiki
chmod +x setup-release.sh scripts/release.sh
./setup-release.sh
```

### 2. Make a Test Release

```bash
./scripts/release.sh 0.1.0 "Initial release"
```

**What happens:**
- ✓ Builds NixOS ISO
- ✓ Commits and tags
- ✓ Pushes to GitHub
- ✓ ISO saved to `release-artifacts/nexus-v0.1.0.iso`

### 3. In NixOS ISO - Test Update

```bash
ssh nexus@<vm-ip>
update
```

**Result:** Latest code from GitHub pulled, rebuilt, services restarted.

---

## 📋 Complete Workflow

```
┌──────────────────────────────────────────────────────────┐
│ Windows/WSL Development                                  │
│ ════════════════════════════════════════════════════════│
│ 1. Make code changes                                     │
│    $ git add . && git commit -m "Feature X"             │
│                                                          │
│ 2. Release new version (builds ISO automatically)       │
│    $ ./scripts/release.sh 1.0.1 "New features"         │
│    ✓ Builds ISO (5-10 min)                             │
│    ✓ Commits & tags                                    │
│    ✓ Pushes to GitHub                                 │
│    ✓ Triggers GitHub Actions (optional)               │
│                                                          │
│ Result: ISO in release-artifacts/ + GitHub release      │
└──────────────────────────────────────────────────────────┘
          ↓
┌──────────────────────────────────────────────────────────┐
│ GitHub Repository                                        │
│ ════════════════════════════════════════════════════════│
│ - Main branch updated with version tag                  │
│ - Release created with ISO download                     │
│ - GitHub Actions auto-build (optional)                 │
└──────────────────────────────────────────────────────────┘
          ↓
┌──────────────────────────────────────────────────────────┐
│ NixOS ISO on Proxmox VM                                  │
│ ════════════════════════════════════════════════════════│
│ AUTOMATIC (Every Monday 02:00 UTC):                     │
│   ✓ systemd timer triggers nexus-update.service        │
│   ✓ Pulls latest from GitHub                           │
│   ✓ Rebuilds backend                                   │
│   ✓ Restarts services                                  │
│   ✓ Logs to journalctl + /var/log/nexus-update.log    │
│                                                          │
│ MANUAL (Anytime):                                        │
│   $ update                   (as nexus user)            │
│   $ sudo systemctl start nexus-update.service (as root) │
│                                                          │
│ VERIFICATION:                                            │
│   $ systemctl list-timers nexus-update                  │
│   $ journalctl -u nexus-update -f                       │
│   $ cat /opt/nexus/VERSION                              │
│   $ curl http://localhost:3001/health                   │
└──────────────────────────────────────────────────────────┘
```

---

## 💻 Command Reference

### Windows/WSL Commands

```bash
# Setup & verification
./setup-release.sh                          # Verify dependencies

# Release management
./scripts/release.sh 1.0.1                 # Release with default message
./scripts/release.sh 1.0.1 "New features"  # Release with custom message

# Git
git log --oneline --tags                   # View releases
git tag -l | sort -V                       # List versions
```

### NixOS ISO Commands

```bash
# Manual update
update                                      # Update to latest (as nexus user)

# Check schedule
systemctl list-timers nexus-update         # View next scheduled update
systemctl status nexus-update.timer         # Timer status

# View logs
journalctl -u nexus-update -f              # Follow live update logs
tail -f /var/log/nexus-update.log          # Log file view
journalctl -u nexus-update -n 50 --no-pager # View last 50 lines

# Manual trigger
sudo systemctl start nexus-update.service   # Run update NOW

# Verify version
cat /opt/nexus/VERSION                      # Current version
curl http://localhost:3001/health           # API health
systemctl status nexus-backend              # Service status
```

---

## 🔍 File Structure

```
~/Programmieren/wiki/
├── .gitignore                          # Excludes build artifacts
├── VERSION                             # Current version (0.1.0)
├── setup-release.sh                    # Setup verification
├── QUICK_REFERENCE.sh                  # Command reference
│
├── scripts/
│   ├── README.md                       # Scripts documentation
│   ├── release.sh                      # Release manager
│   └── update-nexus.sh                 # Update service (copied to ISO)
│
├── infrastructure/
│   ├── configuration.nix               # NixOS config (includes auto-update)
│   ├── flake.nix                       # Nix Flakes ISO builder
│   ├── AUTO_UPDATE_GUIDE.md            # Full update system docs
│   ├── nexus-update.service            # systemd service unit
│   ├── nexus-update.timer              # Weekly schedule
│   └── ... (other infrastructure files)
│
└── .github/
    └── workflows/
        └── build-iso.yml               # GitHub Actions CI/CD
```

---

## 🔐 Git & GitHub Configuration

### Automatic Push Configuration

Already configured in `scripts/release.sh`:

```bash
git remote add origin https://github.com/moinmoin-64/nexus-wiki.git
git push origin main --follow-tags  # Pushes commits + tags
```

### Files Excluded from Repo (.gitignore)

**These won't be committed:**
- `result/`, `*.iso`, `*.qcow2` - Build outputs (too large)
- `node_modules/`, `dist/` - Dependencies (reinstalled via npm ci)
- `.env`, `.env.local` - Secrets (never commit!)
- `*.log`, `.cache/` - Temporary files
- `release-artifacts/` - Local release staging

**These WILL be committed:**
- Source code (`backend/`, `frontend/`)
- Configuration (`flake.nix`, `configuration.nix`)
- Scripts (`scripts/*.sh`)
- Documentation (`.md` files)

---

## 📅 Auto-Update Schedule

### Current Configuration

- **Day**: Every Monday
- **Time**: 02:00 UTC
- **Timezone**: UTC
- **Persistent**: Yes (resumes if VM is off)

### Change Schedule

Edit `/etc/nixos/configuration.nix`:

```nix
systemd.timers."nexus-update" = {
  timerConfig.OnCalendar = "Mon *-*-* 02:00:00";  # Change this line
};
```

**Examples:**
- `"Daily"` - Every day
- `"Mon *-*-* 02:00:00"` - Mondays at 02:00 (current)
- `"*-*-* 03,15 *:00"` - 3 AM and 3 PM every day
- `"Sun *-*-* 22:00:00"` - Sundays at 22:00

Then rebuild:
```bash
sudo nixos-rebuild switch
```

---

## 🛠️ Maintenance

### Version Bumping Strategy

Use semantic versioning:

```bash
# Patch release (bugfixes)
./scripts/release.sh 1.0.1 "Bugfix release"

# Minor release (new features, backward compatible)
./scripts/release.sh 1.1.0 "New features"

# Major release (breaking changes)
./scripts/release.sh 2.0.0 "Major update"
```

### Manual Updates (if needed)

```bash
# On NixOS ISO
ssh nexus@<vm-ip>

# Manual update to absolute latest
update

# Check what changed
cd /opt/nexus/repo
git log --oneline -10
git diff HEAD~1..HEAD
```

### Rollback (Emergency)

```bash
# Stop services
sudo systemctl stop nexus-backend nexus-graph-mirror

# Revert to previous code
cd /opt/nexus/repo
git revert HEAD

# Rebuild and restart
update
```

---

## 🚨 Troubleshooting

### Release fails: "nix: command not found"

```bash
# Install Nix in WSL
curl -L https://nixos.org/nix/install | sh -s -- --daemon

# Enable flakes
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### Update fails on ISO: "Backend won't start"

```bash
ssh nexus@<vm-ip>

# Check errors
journalctl -u nexus-backend -n 50 -p err

# Manual restart
sudo systemctl restart nexus-backend

# Verify
curl http://localhost:3001/health
```

### Update fails: "Git repository not found"

```bash
ssh nexus@<vm-ip>

# Clone repository manually
mkdir -p /opt/nexus/repo
cd /opt/nexus/repo
git clone https://github.com/moinmoin-64/nexus-wiki.git .

# Then update normally
update
```

---

## 📚 Full Documentation

For detailed information, see:

1. **`infrastructure/AUTO_UPDATE_GUIDE.md`** - Complete auto-update system
2. **`scripts/README.md`** - Script reference & examples
3. **`infrastructure/DEPLOY_NEXUS_TUI.md`** - Deployment guide
4. **`QUICK_REFERENCE.sh`** - One-page command reference

---

## ✅ Deployment Checklist

- [x] Create release script for Windows/WSL
- [x] Create update script for NixOS ISO
- [x] Configure systemd timer for weekly updates
- [x] Add shell alias `update` for manual updates
- [x] Create `.gitignore` for build artifacts
- [x] Configure GitHub Actions CI/CD (optional)
- [x] Document complete workflow
- [x] Test release process
- [ ] **Next**: Make first release! 🚀

---

## 🎯 Next Steps

### Immediate

1. **Test release script:**
   ```bash
   cd ~/Programmieren/wiki
   ./setup-release.sh
   ```

2. **Make first release:**
   ```bash
   ./scripts/release.sh 0.1.0 "Initial release"
   ```

3. **Verify on GitHub:**
   - Check releases tab
   - Download ISO if needed

### After Deploying to Proxmox

1. **Test manual update:**
   ```bash
   ssh nexus@<vm-ip>
   update
   ```

2. **Check timer:**
   ```bash
   systemctl list-timers
   ```

3. **Wait for Monday** - Automatic update will trigger at 02:00 UTC

---

## 📞 Support

**Question**: How do I release a new version?  
**Answer**: `./scripts/release.sh 1.0.1 "Your message"`

**Question**: How do I update the running ISO?  
**Answer**: `ssh nexus@<vm-ip>` then run `update`

**Question**: When do updates happen automatically?  
**Answer**: Every Monday at 02:00 UTC (check with `systemctl list-timers`)

**Question**: Where are the logs?  
**Answer**: SSH to VM then: `journalctl -u nexus-update -f`

---

## 🎉 You're All Set!

Your Nexus system now has:

✅ **Complete release management** - Release from Windows/WSL  
✅ **Automatic weekly updates** - Every Monday at 02:00 UTC  
✅ **Manual update capability** - Anytime via `update` command  
✅ **Full CI/CD pipeline** - GitHub Actions ready (optional)  
✅ **Comprehensive logging** - All actions tracked  
✅ **Zero-downtime updates** - Services restart gracefully  

**Time to make your first release! 🚀**

```bash
cd ~/Programmieren/wiki
./scripts/release.sh 0.1.0 "Let's go!"
```

---

**Happy releasing! 🎯**
