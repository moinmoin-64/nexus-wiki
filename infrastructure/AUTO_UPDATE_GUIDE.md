# Nexus Auto-Update System

**Automatic Release Management & Weekly Updates**

This system allows you to:
- **Release new versions** from Windows/WSL with a single command
- **Auto-update the ISO** every Monday at 02:00 UTC
- **Manually update** the ISO anytime via `update` command

---

## 📋 Setup

### 1. Initial Configuration

**On Windows/WSL (your release machine):**

```bash
# Clone the Nexus repository
git clone https://github.com/moinmoin-64/nexus-wiki.git
cd nexus-wiki

# Make release script executable
chmod +x scripts/release.sh

# Install nix in WSL (if not already installed)
curl -L https://nixos.org/nix/install | sh -s -- --daemon
```

### 2. GitHub Configuration

**Add Deploy Key to GitHub** (for auto-updates in ISO):

```bash
# Generate SSH key
ssh-keygen -t ed25519 -f ~/.ssh/nexus-deploy -N ""

# Add to GitHub:
# Settings → Deploy keys → Add deploy key
# - Paste public key: cat ~/.ssh/nexus-deploy.pub
# - Allow write access: ✓ (for future CI/CD)
```

---

## 🚀 Releasing New Versions (Windows/WSL)

### Release Script

```bash
./scripts/release.sh <version> "[optional message]"
```

**Example:**

```bash
./scripts/release.sh 1.0.1 "Bugfixes and performance improvements"
```

**What it does:**

1. Validates version number
2. Builds NixOS ISO with `nix build`
3. Saves ISO to `./release-artifacts/`
4. Commits with message: `Release v1.0.1: ...`
5. Tags commit: `v1.0.1`
6. Pushes to GitHub (main + tags)

**Result:**

```
✅ Release v1.0.1 Complete!

📊 Release Summary:
   Version:  v1.0.1
   ISO:      ./release-artifacts/nexus-v1.0.1.iso (485 MB)
   Repo:     https://github.com/moinmoin-64/nexus-wiki.git
   Branch:   main
   Commits:  42

🚀 Next: Pull on ISO to get latest version
   In NixOS VM: $ update
```

---

## 🔄 Auto-Updates (In ISO)

### Manual Update

Run anytime in the NixOS terminal:

```bash
# Update to latest version from GitHub
update
```

**What happens:**

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

### Automatic Update

**Every Monday at 02:00 UTC:**

1. Systemd timer triggers
2. Update service pulls latest from GitHub  
3. Rebuilds backend
4. Restarts services
5. Logs to `/var/log/nexus-update.log`

**View scheduled updates:**

```bash
# List timers
systemctl list-timers nexus-update

# View timer status
systemctl status nexus-update.timer

# View next run
systemctl list-timers nexus-update --all
```

**View update logs:**

```bash
# Recent update logs
tail -f /var/log/nexus-update.log

# Full journal
journalctl -u nexus-update -f
journalctl -u nexus-update -n 100
```

---

## 📦 Release Files & .gitignore

### Files Excluded from GitHub

These files are in `.gitignore` and WON'T be pushed:

```
result/               # NixOS build outputs
*.iso                 # ISO images (too large)
*.qcow2              # VM images
node_modules/        # Dependencies (reinstalled via npm ci)
dist/                # Compiled code (regenerated)
.env                 # Environment variables
.env.local           # Local config
*.log                # Log files
.cache/              # Build cache
build/               # Build artifacts
release-artifacts/   # Release staging directory
```

### Files Included in GitHub

These ARE pushed to the repository:

```
flake.nix                  # Nix build config
configuration.nix          # System config
backend/src/**/*.ts        # Source code
frontend/src/**/*.vue      # Frontend code
scripts/release.sh         # Release script
scripts/update-nexus.sh    # Update script
package.json               # Dependencies
VERSION                    # Version file
.gitignore                 # This exclusion file
```

---

## 🔐 GitHub Actions (Optional)

Add automatic ISO builds for each release:

**`.github/workflows/build-iso.yml`**

```yaml
name: Build NixOS ISO on Release

on:
  push:
    tags:
      - v*

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: cachix/install-nix-action@v20
      
      - name: Build ISO
        run: |
          cd infrastructure
          nix build .#packages.x86_64-linux.iso
          
      - name: Upload Release Asset
        uses: actions/upload-release-asset@v1
        with:
          upload_url: ${{ github.event.release.upload_url }}
          asset_path: ./result/iso/nixos-*.iso
          asset_name: nexus-${{ github.ref_name }}.iso
```

---

## 📋 Workflow Summary

### For Developers (Windows/WSL)

```bash
# 1. Make changes locally
# ... edit files, test, commit ...

# 2. Release new version
./scripts/release.sh 1.0.2 "New features & fixes"

# 3. Script automatically:
#    ✓ Builds ISO
#    ✓ Pushes to GitHub
#    ✓ Tags release
```

### For Production (NixOS ISO)

```bash
# Monday at 02:00 UTC: Automatic update
# (systemd timer pulls & rebuilds)

# Manual anytime:
update

# Verify:
systemctl status nexus-backend
journalctl -u nexus-backend -f
```

---

## 🚨 Troubleshooting

### Release script fails on nix build

```bash
# Ensure nix flakes is enabled in WSL
nix --version  # Should be >= 2.13.0

# Enable flakes
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Try again
./scripts/release.sh 1.0.3 "Fix release script"
```

### Update on ISO fails

```bash
# Check connectivity
ssh nexus@<vm-ip> curl -I https://github.com

# Manual git check
ssh nexus@<vm-ip>
cd /opt/nexus/repo
git fetch origin
git log --oneline -5

# View error logs
journalctl -u nexus-update -p err --no-pager
```

### Backend won't restart after update

```bash
# Check backend status
systemctl status nexus-backend

# View errors
journalctl -u nexus-backend -n 50 -p err

# Manually restart
sudo systemctl restart nexus-backend

# Verify health
curl http://localhost:3001/health
```

---

## 🔄 Version Management

### Checking Current Version

**On ISO:**

```bash
cat /opt/nexus/VERSION
```

**On GitHub:**

```bash
# Latest release tag
git describe --tags --latest

# View releases
git tag -l
```

### Version Bumping Strategy

Use semantic versioning:

- `v1.0.0` - Major (breaking changes)
- `v1.0.1` - Patch (bugfixes)
- `v1.1.0` - Minor (features, backward compatible)

---

## 📚 Additional Resources

- [Nix Flakes Guide](https://nixos.wiki/wiki/Flakes)
- [systemd Timers](https://www.freedesktop.org/software/systemd/man/systemd.timer.html)
- [Git Tags](https://git-scm.com/book/en/v2/Git-Basics-Tagging)

---

**Your Nexus release system is ready to go! 🎯**

Next steps:
1. Test local setup: `./scripts/release.sh --help` (or just run it!)
2. Make a release: `./scripts/release.sh 0.1.0 "Initial release"`
3. SSH to ISO and run: `update`
4. Verify: `systemctl status nexus-backend`
