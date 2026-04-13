# 🚀 Ready to Release! - Final Setup Guide

**Status**: ✅ Git Repository fully configured and ready for releases

---

## ✅ What's Already Done

- ✅ Git repository initialized with 2 commits
- ✅ Remote URL set to GitHub SSH: `git@github.com:moinmoin-64/nexus-wiki.git`
- ✅ SSH key generated: `~/.ssh/id_rsa` (ed25519)
- ✅ GitHub added to known_hosts
- ✅ Release script ready: `scripts/release.sh`
- ✅ Auto-update system configured in NixOS
- ✅ All documentation in place

---

## 🔑 SSH Key Setup Required

### Step 1: Copy SSH Public Key

Run this in WSL to display your public key:

```bash
wsl bash -c "cat ~/.ssh/id_rsa.pub"
```

Or use our setup script:

```bash
wsl bash setup-ssh.sh
```

### Step 2: Add to GitHub

1. Go to: **https://github.com/settings/keys**
2. Click **"New SSH key"**
3. Title: `Nexus Release (WSL)`
4. Paste your public key
5. Click **"Add SSH key"**

### Step 3: Verify Connection

```bash
wsl bash -c "ssh -T git@github.com"
```

You should see: `Hi moinmoin-64/nexus-wiki! You've successfully authenticated...`

---

## 🎯 Make Your First Release

Once SSH key is added to GitHub:

### From Windows PowerShell or WSL:

```bash
# Go to wiki directory
cd /mnt/c/Users/olist/Programmieren/wiki

# Make a release
./scripts/release.sh 0.1.0 "Initial release with auto-update system"
```

### What Happens:

```
✓ Builds NixOS ISO (5-10 minutes)
✓ Commits changes with message
✓ Creates git tag: v0.1.0
✓ Pushes to GitHub (main + tags)
✓ ISO saved to: release-artifacts/nexus-v0.1.0.iso (485 MB)
```

### Result:

- ✅ Release visible on GitHub: https://github.com/moinmoin-64/nexus-wiki/releases
- ✅ ISO available for download
- ✅ Ready to deploy to Proxmox

---

## 📋 Complete Workflow Summary

```bash
# 1. In WSL - Make changes locally
cd /mnt/c/Users/olist/Programmieren/wiki
git add .
git commit -m "Your changes"

# 2. Release to GitHub
./scripts/release.sh 1.0.1 "Feature: X, Bugfix: Y"

# 3. GitHub Actions builds (optional, if configured)
# → Automatic CI/CD builds ISO

# 4. On Proxmox VM - Manual update anytime
ssh nexus@<vm-ip>
update

# 5. Automatic weekly update
# Monday 02:00 UTC - systemd timer runs automatically
# → Pulls latest code
# → Rebuilds backend
# → Restarts services
```

---

## ⚙️ Optional: Install Nix for Local ISO Builds

If you want to build ISOs directly from Windows/WSL:

```bash
wsl bash -c "curl -L https://nixos.org/nix/install | sh -s -- --daemon"
```

Then enable flakes (edit `~/.config/nix/nix.conf`):

```
experimental-features = nix-command flakes
```

After this, `./scripts/release.sh` will build the ISO directly without needing GitHub Actions.

---

## 📚 Key Commands

### WSL Release Commands

```bash
# Release new version
./scripts/release.sh 1.0.1 "Your message"

# View git history
git log --oneline -10

# View all tags/releases
git tag -l | sort -V

# Check what's uncommitted
git status
```

### On NixOS ISO (After Deployment)

```bash
# Manual update
update

# Check automatic update schedule
systemctl list-timers nexus-update

# View update logs
journalctl -u nexus-update -f

# See last 50 update log lines
journalctl -u nexus-update -n 50

# Current version
cat /opt/nexus/VERSION

# API health check
curl http://localhost:3001/health
```

---

## 🔍 Troubleshooting

### SSH Key Not Working

```bash
# Verify key exists
ls -la ~/.ssh/id_rsa*

# Test GitHub connection
ssh -T git@github.com

# If key not added to GitHub yet:
# Go to https://github.com/settings/keys and add it
```

### Release Script Fails

```bash
# Check git status
git status

# Verify remote is SSH
git remote -v
# Should show: git@github.com:moinmoin-64/nexus-wiki.git

# Check if it's a git repository
git log --oneline -1
```

### Nix Not Found

If release script says "Nix not found":

```bash
# Install Nix in WSL
wsl bash -c "curl -L https://nixos.org/nix/install | sh -s -- --daemon"

# Enable flakes
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

---

## ✨ What You Have Now

| Component | Status | Location |
|-----------|--------|----------|
| Git Repo | ✅ Ready | `/mnt/c/Users/olist/Programmieren/wiki` |
| SSH Key | ✅ Generated | `~/.ssh/id_rsa` |
| Release Script | ✅ Ready | `scripts/release.sh` |
| Auto-Update (ISO) | ✅ Configured | `infrastructure/nexus-update.*` |
| GitHub Remote | ✅ Set | `git@github.com:moinmoin-64/nexus-wiki.git` |
| Documentation | ✅ Complete | Multiple `.md` files |

---

## 🎬 Next Steps (In Order)

1. **Add SSH key to GitHub** (https://github.com/settings/keys)
2. **Test SSH** with `ssh -T git@github.com`
3. **Make first release** with `./scripts/release.sh 0.1.0 "Initial"`
4. **Verify on GitHub** (check releases page)
5. **Deploy ISO to Proxmox** VM
6. **Test manual update** with `update` command
7. **Wait for Monday** (automatic update at 02:00 UTC)

---

## 📞 Quick Help

**Q: How do I release a new version?**  
A: `./scripts/release.sh 1.0.1 "Your message"`

**Q: Where do I add my SSH key?**  
A: https://github.com/settings/keys → New SSH key

**Q: How do I update the running ISO?**  
A: SSH to VM and type `update`

**Q: When do updates run automatically?**  
A: Every Monday at 02:00 UTC (check with `systemctl list-timers`)

**Q: What if SSH key doesn't work?**  
A: 
1. Verify key is added to https://github.com/settings/keys
2. Test with `ssh -T git@github.com`
3. Check with `git remote -v` (should be git@github.com...)

---

## 🎉 You're All Set!

Everything is configured and ready. The only thing left is:

1. **Add SSH key to GitHub** (5 minutes)
2. **Make first release** (10+ minutes for Nix build)
3. **Deploy and enjoy!**

---

**Next: Add SSH key to GitHub and run your first release! 🚀**

```bash
# Copy your SSH public key
wsl bash -c "cat ~/.ssh/id_rsa.pub"

# Add to GitHub: https://github.com/settings/keys

# Then make a release
cd /mnt/c/Users/olist/Programmieren/wiki
./scripts/release.sh 0.1.0 "Ready for production!"
```

---

**All systems ready! 🎯**
