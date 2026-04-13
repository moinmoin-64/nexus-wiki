# Project Nexus - TUI Appliance ISO Guide

## 🎯 What This Is

A **minimal, dedicated NixOS ISO** that runs **only Project Nexus**. Pure TUI, no GUI, everything auto-starts on boot.

- **Size**: ~500MB ISO
- **RAM**: 8GB recommended
- **Disk**: 50GB+ (for data)
- **Boot Time**: ~30 seconds to full operational
- **Console**: Direct terminal access

---

## 🏗️ Building the ISO

### Prerequisites
- NixOS system OR `nix` package manager installed
- ~10 GB free disk space
- 5-10 minutes build time

### Build Steps

```bash
cd infrastructure

# Update dependencies
nix flake update

# Build ISO
nix build .#packages.x86_64-linux.iso

# Result at: result/iso/nixos-*.iso
```

### Or Build QCOW2 for Proxmox

```bash
nix build .#packages.x86_64-linux.qcow2
```

---

## 🚀 Deploying to Proxmox

### 1. Upload ISO to Proxmox

```bash
# Copy to Proxmox node
scp result/iso/nixos-*.iso root@proxmox:/var/lib/vz/template/iso/

# Or upload via web UI
```

### 2. Create VM

```bash
# Proxmox CLI
qm create 100 \
  --name nexus-server \
  --machine q35 \
  --cores 4 \
  --memory 8192 \
  --net0 virtio,bridge=vmbr0 \
  --bootdisk scsi0 \
  --scsihw virtio-scsi-pci \
  --scsi0 local:100/vm-disk.qcow2,size=50G \
  --cdrom local:iso/nixos-*.iso

qm start 100
```

### 3. Boot and Install

- VM boots directly into Nexus
- Auto-login as `nexus` user
- All services auto-start
- Ready to use immediately

---

## 📊 Services Auto-Started

| Service | Port | Status |
|---------|------|--------|
| PostgreSQL | 5432 | ✅ Auto-start |
| Neo4j | 7687 | ✅ Auto-start |
| Redis | 6379 | ✅ Auto-start |
| Backend API | 3001 | ✅ Auto-start |
| Graph Mirror | - | ✅ Auto-start |
| Nginx | 80, 443 | ✅ Auto-start |

---

## 🎮 First Boot Experience

```
╔════════════════════════════════════════╗
║   Project Nexus - TUI Monitor          ║
║   2026-04-13 14:32:15                  ║
╚════════════════════════════════════════╝

🔷 System Status:
─────────────────────────────────────────
● nexus-backend.service - Project Nexus Backend API
  Loaded: loaded (/etc/systemd/system/nexus-backend.service; enabled)
  Active: active (running) since ...

🗄️  Services:
─────────────────────────────────────────
● postgresql.service - ✓ running
● neo4j.service - ✓ running  
● nginx.service - ✓ running

📊 Resources:
─────────────────────────────────────────
Uptime: 2 min
Disk:   8% used
Memory: 1.2G / 7.9G

🌐 Web UI:  http://localhost
🔌 API:     http://localhost:3001
📝 Logs: journalctl -u nexus-backend -f
🛑 Shutdown: systemctl poweroff
```

---

## 💻 Console Commands

### Monitor System

```bash
# Live service status
systemctl status nexus-backend

# Backend logs
journalctl -u nexus-backend -f

# All Nexus logs
journalctl | grep nexus

# System resources
htop
```

### Access Services

```bash
# Check API health
curl http://localhost:3001/health

# Neo4j shell
cypher-shell

# PostgreSQL CLI
psql -U nexus_user -d nexus_db
```

### Admin Tasks

```bash
# Stop all services
systemctl stop nexus-backend
systemctl stop nexus-graph-mirror

# Restart backend
systemctl restart nexus-backend

# View environment
cat /etc/nexus/backend.env

# Backup database
pg_dump -U nexus_user nexus_db > backup.sql
```

---

## 🔐 Security

- **No password login** (SSH key only)
- **Root access disabled** (use `sudo`)
- **Firewall enabled** (SSH, HTTP/HTTPS, APIs only)
- **Auto-updates**: Enabled via systemd
- **SSH hardening**: Key-only auth

---

## 🌐 Network Access

### From another computer

```bash
# SSH (with key)
ssh -i ~/.ssh/id_rsa nexus@<vm-ip>

# Web UI
open http://<vm-ip>

# API
curl http://<vm-ip>:3001/health

# PostgreSQL (port forward)
ssh -L 5432:localhost:5432 nexus@<vm-ip>
psql -h localhost -U nexus_user nexus_db
```

---

## 📈 Performance Tuning

### Resize Storage

```bash
# Proxmox UI or CLI
lvresize -L +20G /dev/mapper/pve-vm--disk
pvresize /dev/sda
```

### Increase Memory

```bash
# Stop VM
qm stop 100

# Increase RAM
qm set 100 --memory 16384

# Start VM
qm start 100
```

### Increase CPUs

```bash
# Hot-add (while running)
qm set 100 --cores 8
```

---

## 🐛 Troubleshooting

### Services not starting

```bash
# Check status
systemctl list-units --failed

# View service logs
journalctl -u nexus-backend -n 100

# Manual service test
/opt/nexus/backend/bin/server.js
```

### Database connection issue

```bash
# Check PostgreSQL
sudo -u postgres psql
SELECT datname FROM pg_database;

# Check Neo4j
cypher-shell -u neo4j "RETURN 1"
```

### Low disk space

```bash
# Check usage
df -h
du -sh /*

# Clean log files
journalctl --vacuum=30d
```

---

## 📝 Customization

Edit `/etc/nixos/configuration.nix` to modify:

- Network settings
- Service ports
- Resource limits
- SSH configuration
- Installed packages

Then rebuild:

```bash
sudo nixos-rebuild switch
```

---

## 🔄 Updates

The system checks for NixOS updates daily. To update manually:

```bash
sudo nix flake update
sudo nixos-rebuild switch --upgrade
```

---

## 📞 Logs & Debugging

### All system logs
```bash
journalctl -f
```

### Only Nexus services
```bash
journalctl -u nexus-backend -u nexus-graph-mirror -u postgresql -u neo4j -f
```

### Save logs to file
```bash
journalctl --since "2 hours ago" > nexus-logs.txt
```

---

## 🎯 Production Checklist

Before deploying to production:

- [ ] Change JWT_SECRET in `/etc/nexus/backend.env`
- [ ] Change database passwords
- [ ] Configure firewall rules (only needed ports)
- [ ] Enable SSL/TLS (Let's Encrypt)
- [ ] Set up automated backups
- [ ] Configure monitoring/alerts
- [ ] Add SSH authorized keys
- [ ] Test disaster recovery

---

**Your Nexus server is ready to deploy! 🚀**
