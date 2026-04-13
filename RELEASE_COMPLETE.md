# 🚀 PROJECT NEXUS - COMPLETE RELEASE & AUTO-UPDATE SYSTEM

## ⚡ QUICK START (5 Minutes)

### 1. Set Up Release System
```bash
cd /mnt/c/Users/olist/Programmieren/wiki
./scripts/setup-complete-release.sh
```

### 2. Add SSH Key to GitHub
- Copy output from above
- Go to: https://github.com/settings/keys
- Click "New SSH key"
- Paste the key
- Save

### 3. Verify Connection
```bash
./scripts/verify-ssh.sh
```

### 4. Make First Release
```bash
./scripts/release.sh 0.1.0 "Initial release with auto-update system"
```

**That's it!** Your ISO is now on GitHub with automatic weekly updates.

---

## 📋 COMPLETE WORKFLOW

### Phase 1: Local Development
```bash
# Make code changes
git add .
git commit -m "Your changes"

# When ready to release, ensure clean working tree
git status
# Should show "nothing to commit, working tree clean"
```

### Phase 2: Test Release (Optional)
```bash
# Build ISO and test without pushing to GitHub
./scripts/trial-release.sh 0.2.0 "Feature: Added X"

# This builds ISO, creates local git tag, but doesn't push
```

### Phase 3: Production Release
```bash
# Push actual release to GitHub
# This will:
# 1. Build ISO (5-10 minutes)
# 2. Create git commit with VERSION change
# 3. Tag with version
# 4. Push to GitHub
# 5. GitHub Actions auto-builds and creates release
./scripts/release.sh 0.2.0 "Feature: Added X"
```

### Phase 4: Deploy to Proxmox
```bash
# Download ISO from GitHub releases
# Or use local build: ./release-artifacts/nexus-0.2.0.iso

# Upload to Proxmox
# Create VM with ISO
# Boot and start services automatically
```

### Phase 5: Automatic Updates
- **First Time**: Manual `update` command in ISO
- **Weekly**: Automatic Monday 02:00 UTC (systemd timer)
- **Manual Override**: Run `update` command anytime

---

## 🛠️ ALL AVAILABLE SCRIPTS

### Show SSH Key
```bash
./scripts/show-ssh-key.sh
```
- Displays SSH public key for GitHub setup
- Shows key fingerprint for verification
- Step-by-step setup instructions

### Verify SSH Connection
```bash
./scripts/verify-ssh.sh
```
- Tests GitHub SSH authentication
- Shows if you're ready for releases
- Troubleshooting if connection fails

### Trial Release (Test Only)
```bash
./scripts/trial-release.sh VERSION "message"
```
- Example: `./scripts/trial-release.sh 0.1.0 "Test"`
- Builds ISO locally
- Creates git commit and tag
- **Does NOT push to GitHub** (safe for testing)

### Complete Setup
```bash
./scripts/setup-complete-release.sh
```
- One-command setup
- Generates SSH key if needed
- Shows public key
- Verifies GitHub connection
- Tests git configuration

### Production Release
```bash
./scripts/release.sh VERSION "message"
```
- Example: `./scripts/release.sh 0.1.0 "Initial"`
- Builds ISO
- Commits and tags
- **Pushes to GitHub**
- Triggers GitHub Actions CI/CD

### Setup One-Time
```bash
./scripts/setup-release.sh
```
- Verifies all dependencies exist (git, nix, curl)
- Checks git repository state
- Safety checks before release

---

## 🔐 SSH KEY MANAGEMENT

### Prerequisites
- SSH key must be in `~/.ssh/id_rsa` (ed25519 format)
- Public key must be added to GitHub
- SSH agent must be running

### Generate New Key (One-Time)
```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_rsa -N ''
./scripts/show-ssh-key.sh
```

### Add to GitHub
1. Run: `./scripts/show-ssh-key.sh`
2. Copy the entire public key (lines starting with `ssh-ed25519`)
3. Go to: https://github.com/settings/keys
4. Click "New SSH key"
5. Paste the key
6. Click "Add SSH key"

### Verify It Works
```bash
./scripts/verify-ssh.sh
# Should output: "Hi moinmoin-64! You've successfully authenticated"
```

---

## 🔄 VERSION MANAGEMENT

### Current Version
```bash
cat VERSION
# Outputs: 0.1.0
```

### Version Format
- Format: `MAJOR.MINOR.PATCH` (Semantic Versioning)
- Example: `0.1.0`, `1.0.0`, `1.2.3`
- Update manually before each release

### Files Updated Automatically
When you run a release, these files are updated:
- `VERSION` - Updated to new version
- `flake.nix` - Version in package
- Infrastructure config - If applicable

---

## 🏗️ BUILD SYSTEM DETAILS

### Release Script (`scripts/release.sh`)
```
Input: VERSION + MESSAGE
  ↓
Validate version format (X.Y.Z)
  ↓
Check working directory is clean
  ↓
Verify SSH to GitHub works
  ↓
Update VERSION file
  ↓
Update Nix flake
  ↓
Nix build ISO (5-10 min) ⏱️
  ↓
Create git commit
  ↓
Create git tag (v{VERSION})
  ↓
Push to GitHub (SSH)
  ↓
GitHub Actions triggered (auto-build and release assets)
```

### Update Script (`scripts/update-nexus.sh`)
Runs automatically on ISO every Monday 02:00 UTC:
```
Check /opt/nexus/repo exists
  ↓
git clone or git pull latest
  ↓
npm ci (clean install)
  ↓
npm run build (TypeScript)
  ↓
npm run migrate (database)
  ↓
systemctl restart nexus (backend)
  ↓
Health check (/ healthz endpoint)
```

---

## 📦 BUILD ARTIFACTS

### Locations
- **Local**: `./release-artifacts/nexus-VERSION.iso`
- **GitHub**: https://github.com/moinmoin-64/nexus-wiki/releases/tag/v{VERSION}
- **Nix output**: `./result-iso/iso/nexus-*.iso`

### Size
- Typical ISO: ~500MB (includes all services)
- Compressed: ~200MB (on disk with compression)

### What's Included
- NixOS base system
- PostgreSQL database
- Neo4j graph database
- Redis cache
- Nginx reverse proxy
- Project Nexus backend (Node.js)
- Frontend (Vue.js)
- Auto-update service

---

## 🔧 TROUBLESHOOTING

### SSH Connection Fails
```bash
# Check SSH key exists
ls -la ~/.ssh/id_rsa*

# Verify key is in SSH agent
ssh-add -l

# Test GitHub connection verbosely
ssh -vvv git@github.com
```

### Git Push Fails
```bash
# Check remote URL is SSH
git remote -v
# Should show: git@github.com:moinmoin-64/nexus-wiki.git

# If HTTPS, convert to SSH
git remote set-url origin git@github.com:moinmoin-64/nexus-wiki.git

# Test again
git push origin main
```

### ISO Build Fails
```bash
# Check Nix is installed
nix --version

# Try rebuilding
nix flake update
nix build .#nixosConfigurations.nexusISO.config.system.build.isoImage

# Check for errors
# Common causes: disk space, network issues, flake.lock corruption
```

### GitHub Release Not Created
```bash
# Check if tag was pushed
git tag -l

# Check GitHub Actions workflow
# Go to: https://github.com/moinmoin-64/nexus-wiki/actions

# Re-run manually or check logs
```

---

## 🚀 WORKFLOW EXAMPLES

### Example 1: First Release
```bash
# Ensure you're in the right directory
cd /mnt/c/Users/olist/Programmieren/wiki

# Set up release system
./scripts/setup-complete-release.sh

# Wait for SSH key to be added to GitHub...

# Make first release
./scripts/release.sh 0.1.0 "Initial release with auto-update system"

# Wait 5-10 minutes for ISO build...
# Check GitHub releases: github.com/.../releases
```

### Example 2: Feature Release
```bash
# Make changes in your code
vim backend/src/...
git add .
git commit -m "Added feature X"

# Test locally first
npm run dev

# Release
./scripts/release.sh 0.2.0 "Feature: Added X, fixed Y"

# Deploy to Proxmox
# Download new ISO
# Create VM
# Boot and verify updates work
```

### Example 3: Emergency Fix
```bash
# Fix critical bug
vim backend/src/...
git add .
git commit -m "Fix: Critical bug in X"

# Patch release (0.1.0 -> 0.1.1)
./scripts/release.sh 0.1.1 "Fix: Critical bug"

# Tell users to run `update` command on their VMs
```

---

## 🔄 AUTO-UPDATE VERIFICATION

### On NixOS ISO
```bash
# Check if auto-update service is installed
systemctl status nexus-update.service
systemctl status nexus-update.timer

# Check update schedule
systemctl list-timers

# Run update manually
update

# Check for errors
journalctl -u nexus-update -f

# The update command is aliased in /etc/profile
```

### Automatic Weekly Schedule
- **When**: Every Monday at 02:00 UTC
- **What**: Runs `scripts/update-nexus.sh`
- **Action**: git pull → npm ci → TypeScript build → migrations → restart services
- **Logs**: Check with `journalctl -u nexus-update -f`

---

## 📊 SYSTEM ARCHITECTURE

### Release Pipeline
```
Developer PC (Windows/WSL)
  ↓
./scripts/release.sh (Bash)
  ↓
Nix build (Linux)
  ↓
Git commit + tag
  ↓
GitHub Push (SSH)
  ↓
GitHub Actions
  ↓
Release created with ISO artifact
```

### Update Pipeline
```
GitHub Repository (latest changes)
  ↓
NixOS ISO (systemd timer, Monday 02:00 UTC)
  ↓
Auto-update service (scripts/update-nexus.sh)
  ↓
Git pull latest
  ↓
npm ci + npm build
  ↓
Database migrations
  ↓
Service restart
  ↓
Health check
```

---

## 📚 RELATED DOCUMENTATION

- [AUTO_UPDATE_GUIDE.md](AUTO_UPDATE_GUIDE.md) - Technical details of auto-update system
- [SETUP_AUTO_UPDATE.md](SETUP_AUTO_UPDATE.md) - Setup instructions for ISO
- [RELEASE_READY.md](RELEASE_READY.md) - Quick reference guide
- [scripts/README.md](scripts/README.md) - Script documentation
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Full deployment procedures

---

## ✅ CHECKLIST

- [ ] SSH key generated (`~/.ssh/id_rsa`)
- [ ] SSH public key added to GitHub
- [ ] SSH connection verified (`./scripts/verify-ssh.sh`)
- [ ] Git repository configured with correct remote
- [ ] VERSION file updated to 0.1.0
- [ ] First release tested locally (`./scripts/trial-release.sh 0.1.0`)
- [ ] Production release pushed (`./scripts/release.sh 0.1.0`)
- [ ] GitHub release created with ISO artifact
- [ ] ISO deployed to Proxmox VM
- [ ] Manual update tested on VM (`update` command)
- [ ] Waited for Monday 02:00 UTC or manually triggered timer
- [ ] Verified automatic update worked

---

## 🎯 NEXT STEPS

1. **Set up release system**: `./scripts/setup-complete-release.sh`
2. **Add SSH key to GitHub**: Follow on-screen instructions
3. **Verify connection**: `./scripts/verify-ssh.sh`
4. **Make first release**: `./scripts/release.sh 0.1.0 "Initial"`
5. **Deploy to Proxmox**: Download ISO and create VM
6. **Test updates**: Run `update` command manually, then wait for Monday

---

## 💡 TIPS & TRICKS

### Update VERSION Manually
```bash
echo "0.2.0" > VERSION
git add VERSION
git commit -m "Bump version to 0.2.0"
```

### View Release History
```bash
git tag -l
git log --oneline --decorate
```

### Delete a Release
```bash
# Delete local tag
git tag -d v0.1.0-trial

# Delete GitHub tag (via web UI)
# Cannot delete releases easily - create new release instead
```

### Speed Up ISO Build
```bash
# Use cached dependencies
export NIX_CACHE_SHARE=1

# Skip signing
./scripts/release.sh 0.1.0 "Fast" --no-sign
```

### Debug ISO Build
```bash
# Verbose build
nix build .#nixosConfigurations.nexusISO.config.system.build.isoImage -v

# Check what's building
nix build --print-build-logs .#...
```

---

**Status**: ✅ PRODUCTION READY
**Last Updated**: 2025-01-XX
**Version**: 0.1.0

Questions? Check the related documentation files or review the scripts themselves - they're well-commented!
