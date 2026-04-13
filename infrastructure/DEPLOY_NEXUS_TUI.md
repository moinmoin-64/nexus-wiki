# 🚀 Nexus TUI Appliance - Deployment Guide

**Status**: ✅ Production Ready  
**ISO Size**: ~500 MB  
**Boot Time**: ~30 seconds  
**Services**: 6 (PostgreSQL, Neo4j, Redis, Nginx, Backend API, Graph Mirror)  

---

## 📋 Quick Start

### 1. Build ISO (on NixOS host)

```bash
cd infrastructure

# Update dependencies
nix flake update

# Build ISO
nix build .#packages.x86_64-linux.iso -v

# Result: result/iso/nixos-*.iso (~500 MB)
```

### 2. Deploy to Proxmox

**Option A: Via Web UI**
- Upload ISO to storage: /var/lib/vz/template/iso/
- Create VM (4 CPU, 8GB RAM, 50GB disk)
- Attach ISO and boot

**Option B: Via CLI**

```bash
# Copy ISO to Proxmox node
scp result/iso/nixos-*.iso root@proxmox:/var/lib/vz/template/iso/

# Create VM
qm create 100 \
  --name nexus-prod \
  --machine q35 \
  --cores 4 \
  --memory 8192 \
  --net0 virtio,bridge=vmbr0 \
  --bootdisk scsi0 \
  --scsihw virtio-scsi-pci \
  --scsi0 local-lvm:100,size=50G \
  --cdrom local:iso/nixos-*.iso

# Start VM
qm start 100

# Monitor boot
qm terminal 100
```

### 3. First Boot (Automatic)

VM boots → Auto-login `nexus` user → Services auto-start → Ready in ~30s

```
╔════════════════════════════════════════╗
║   Project Nexus - TUI Monitor          ║
╚════════════════════════════════════════╝

🔷 System Status: ✓ OK
🗄️  Services: ✓ All running
📊 Resources: CPU 12%, Mem 2.1G/7.9G

🌐 Web UI:  http://192.168.1.100
🔌 API:     http://192.168.1.100:3001
```

---

## 🎮 Console Access

### SSH Access

```bash
# From any machine with SSH key
ssh -i ~/.ssh/id_rsa nexus@<vm-ip>

# As root (if needed, with sudo)
ssh -i ~/.ssh/id_rsa nexus@<vm-ip>
sudo su -
```

### Adding SSH Keys

**Before first boot** (modify ISO):
Edit `configuration.nix`, line ~45:
```nix
openssh.authorizedKeys.keys = [
  "ssh-rsa AAAAB3Nza... your-key@host"
];
```

**After boot** (via SSH):
```bash
ssh nexus@<vm-ip> -i key
# Edit ~/.ssh/authorized_keys
```

---

## 📊 Service Management

### View Status

```bash
# All services
systemctl status

# Specific service
systemctl status nexus-backend
systemctl status postgresql
systemctl status neo4j

# Real-time logs
journalctl -u nexus-backend -f
```

### Start/Stop Services

```bash
# Stop backend (with database)
sudo systemctl stop nexus-backend

# Restart after config change
sudo systemctl restart nexus-backend

# Enable/disable auto-start
sudo systemctl enable mysql-backend
sudo systemctl disable nexus-backend
```

### Service Order

```
Boot → Network ↓
       PostgreSQL ↓
       Neo4j ↓
       Redis ↓
       ↓
       Backend API (depends on all above)
       Graph Mirror (depends on PostgreSQL, Neo4j)
       Nginx (independent)
```

---

## 🌐 Network Configuration

### Find IP Address

```bash
# On VM console
hostname -I

# Or on host
arp-scan <subnet> | grep "Proxmox KVM"
qm status 100  # If ID is 100
```

### Access Services

| Service | URL | Port | Auth |
|---------|-----|------|------|
| Web UI | http://vm-ip | 80 | API Key |
| API | http://vm-ip:3001 | 3001 | JWT |
| PostgreSQL | localhost:5432 | 5432 | nexus_user |
| Neo4j | localhost:7687 | 7687 | neo4j |
| Redis | localhost:6379 | 6379 | None |

### Configure Static IP

```bash
# Edit network config
sudo vi /etc/nixos/configuration.nix

# Find networking section and change:
# FROM:
networking.useDHCP = true;

# TO:
networking.useDHCP = false;
networking.interfaces.eth0.ipv4.addresses = [
  { address = "192.168.1.100"; prefixLength = 24; }
];
networking.defaultGateway = "192.168.1.1";
networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

# Apply
sudo nixos-rebuild switch
```

---

## 📦 Deployment Flow

```
┌─────────────────────────────────────────────┐
│ Build ISO (nix build .#iso)                │
│ ~5-10 minutes                               │
└──────────────────┬──────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│ Upload to Proxmox                           │
│ result/iso/nixos-*.iso                      │
└──────────────────┬──────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│ Create VM + Attach ISO                      │
│ 4 CPU, 8GB RAM, 50GB disk                   │
└──────────────────┬──────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│ Start VM from ISO                           │
│ Auto-boots, auto-installs, auto-starts      │
└──────────────────┬──────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│ Services Ready (~30 seconds)                │
│ PostgreSQL ✓ Neo4j ✓ Backend ✓              │
│ Access via Web UI / API                     │
└─────────────────────────────────────────────┘
```

---

## 🛠️ Troubleshooting

### Services won't start

```bash
# Check service status
systemctl list-units --failed

# View error logs
journalctl -u nexus-backend -n 100
journalctl -u postgresql -n 50
journalctl -u neo4j -n 50

# Restart database services first
sudo systemctl restart postgresql
sudo systemctl restart neo4j
sleep 5
sudo systemctl restart nexus-backend
```

### Backend can't connect to database

```bash
# Test PostgreSQL
sudo -u postgres psql
SELECT datname FROM pg_database;
\q

# Test Neo4j connectivity
cypher-shell -u neo4j -p neo4j_password "RETURN 1"

# Check backend environment
cat /etc/nexus/backend.env | grep POSTGRES
```

### Low disk space

```bash
# Check usage
df -h

# Clean old logs
sudo journalctl --vacuum=7d

# Clean Nix store
sudo nix-collect-garbage -d

# Check what's using space
du -sh /* | sort -hr
```

### Network not working

```bash
# Check interfaces
ip addr show

# Test DHCP
sudo dhclient eth0

# Restart networking
sudo systemctl restart networking

# Check firewall
sudo ufw status
```

---

## 🚀 Production Deployment Checklist

- [ ] Build ISO on trusted machine
- [ ] Verify ISO integrity (SHA256)
- [ ] Upload to Proxmox
- [ ] Create VM with secure settings
- [ ] Boot and verify all services start
- [ ] Add SSH authorized keys  
- [ ] Change JWT_SECRET in `/etc/nexus/backend.env`
- [ ] Change database passwords
- [ ] Configure static IP
- [ ] Set up DNS records
- [ ] Enable SSL/TLS (Let's Encrypt)
- [ ] Configure backup strategy
- [ ] Set up monitoring/alerting
- [ ] Document access procedures
- [ ] Test disaster recovery

---

## 🔐 Security Hardening

### SSH Key Authentication (Required)

Remove password auth - edit `configuration.nix`:

```nix
services.openssh.settings = {
  PasswordAuthentication = false;  # ← Must be false
  PubkeyAuthentication = true;     # ← Must be true
  PermitRootLogin = "no";          # ← Root disabled
  AllowUsers = "nexus";            # ← Only nexus user
};
```

### Change Passwords

```bash
# PostgreSQL
export PGPASSWORD=
```

```sql
ALTER USER nexus_user WITH PASSWORD 'strong-random-password';
```

```bash
# Neo4j
cypher-shell -u neo4j
:switch system
ALTER USER neo4j SET PASSWORD 'strong-random-password';
```

### Firewall Rules

```bash
# View current
sudo ufw status

# Restrict to SSH only (if no web access needed)
sudo ufw allow 22
sudo ufw default deny incoming
sudo ufw enable
```

---

## 📈 Performance Tuning

### VM Resources

Adjust Proxmox VM:

```bash
# More CPU cores (4 → 8)
qm set 100 --cores 8

# More RAM (8GB → 16GB) 
qm stop 100
qm set 100 --memory 16384
qm start 100

# More disk
lvresize -L +50G /dev/mapper/pve-vm--100--disk--0
pvresize /dev/vda
```

### Database Tuning

Edit `/etc/nixos/configuration.nix`:

```nix
services.postgresql.settings = {
  shared_buffers = "512MB";        # Default: 256MB
  work_mem = "32MB";               # Default: 16MB
  maintenance_work_mem = "256MB";  # Default: 64MB
};
```

```bash
# Apply
sudo nixos-rebuild switch
```

---

## 📡 Logs & Monitoring

### View All Logs

```bash
# Live streaming
journalctl -f -u nexus-backend -u postgresql -u neo4j

# Since specific time
journalctl --since "2 hours ago"
journalctl --since "2026-04-13 10:00:00"

# Export to file
journalctl -u nexus-backend > backend-logs.txt
```

### Log Storage

```bash
# Check disk usage
du -sh /var/log

# Limit log retention
sudo journalctl --vacuum=30d

# Edit retention policy
sudo vi /etc/systemd/journald.conf
# MaxRetentionSec=30day
```

### Remote Logging

Forward logs to external server:

```bash
sudo vi /etc/systemd/journald.conf

# Add:
# ForwardToSyslog=yes
# SystemMaxUse=1G
```

---

## 🔄 Updates & Maintenance

### Update NixOS

```bash
# Check available updates
sudo nix flake update

# Apply updates
sudo nixos-rebuild switch --upgrade

# Revert if needed
sudo nixos-rebuild switch --rollback
```

### Backup Strategy

```bash
# PostgreSQL backup
pg_dump -U nexus_user nexus_db > backup-$(date +%Y%m%d).sql

# Full VM snapshot (Proxmox)
qm snapshot 100 -snapname backup-2026-04-13

# Restore from backup
psql -U nexus_user nexus_db < backup-20260413.sql
```

---

## 📞 Support & Debugging

### Collect Debug Information

```bash
# System info
uname -a
hostnamectl
systemctl --version

# Service status
systemctl status
journalctl -p err -n 100

# Network
ip addr show
netstat -tulnp

# Disk
df -h
du -sh /var/lib/{postgresql,neo4j,nexus}

# Export for analysis
journalctl -u nexus-backend -n 1000 > /tmp/debug.log
tar czf nexus-debug-$(date +%s).tar.gz /tmp/debug.log /etc/nexus/
```

### Build Custom ISO

Modify `configuration.nix` for your needs:

```bash
# Add packages
environment.systemPackages = with pkgs; [
  # existing packages...
  tree       # Add tree utility
  iftop      # Network monitoring
];

# Rebuild ISO
nix flake update
nix build .#packages.x86_64-linux.iso
```

---

**Ready to deploy! 🎯**
