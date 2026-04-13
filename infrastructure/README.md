# Infrastructure - Project Nexus TUI Appliance

**Complete NixOS deployment infrastructure for Project Nexus pure-backend server**

This directory contains everything needed to build and deploy a minimal NixOS ISO that runs only the Project Nexus backend services with automatic startup.

---

## 📁 File Structure

```
infrastructure/
├── flake.nix                    # Nix Flakes config for ISO/QCOW2 building
├── configuration.nix            # Main NixOS system configuration
├── hardware-configuration.nix   # Hardware probing & device config
│
├── build-iso.sh                 # Build ISO script  
├── deploy-to-vm.sh              # Deploy backend to running VM
├── monitor-remote.sh            # SSH-based remote monitoring
├── setup-first-boot.sh          # First-boot initialization
│
├── DEPLOY_NEXUS_TUI.md          # Full deployment guide
├── TUI_APPLIANCE_GUIDE.md       # User & operations manual
└── README.md                    # This file
```

---

## 🚀 Quick Start

### Build ISO

```bash
# 1. Update dependencies
nix flake update

# 2. Build ISO (or QCOW2)
nix build .#packages.x86_64-linux.iso

# Result: result/iso/nixos-*.iso
```

### Deploy to Proxmox

```bash
# 1. Copy ISO to Proxmox node
scp result/iso/nixos-*.iso root@proxmox:/var/lib/vz/template/iso/

# 2. Create VM via Proxmox UI or:
qm create 100 --name nexus-prod --cores 4 --memory 8192 \
  --net0 virtio,bridge=vmbr0 --scsi0 local-lvm:100,size=50G \
  --cdrom local:iso/nixos-*.iso

# 3. Start and boot from ISO
qm start 100
```

### First Boot

VM auto-starts all services and becomes ready in ~30 seconds. SSH into running VM:

```bash
ssh -i ~/.ssh/id_rsa nexus@<vm-ip>
```

---

## 🏗️ What's Included

### Services (Auto-Starting)

| Service | Port | Purpose |
|---------|------|---------|
| **PostgreSQL** | 5432 | OLTP database (relational data) |
| **Neo4j** | 7687 | Graph database (knowledge connections) |
| **Redis** | 6379 | Cache & rate limiting |
| **Backend API** | 3001 | Nexus Node.js REST API |
| **Graph Mirror** | - | PostgreSQL → Neo4j sync service |
| **Nginx** | 80, 443 | Reverse proxy & static files |

### System Features

- **Pure TUI**: No X11, no desktop environment, no GUI
- **Minimal**: ~500 MB ISO, boots in ~30 seconds
- **Headless**: Auto-login, auto-start services
- **Secure**: SSH key-only auth, firewall enabled
- **Self-contained**: All data/config on single VM
- **Observable**: Real-time monitoring via SSH

---

## 🎯 Configuration Files

### flake.nix

Nix Flakes build configuration:
- Inputs: nixpkgs, flake-utils, nixos-generators
- Outputs: ISO image, QCOW2 image, dev shell
- Builds platform: x86_64-linux

**Build commands:**
```bash
nix build .#packages.x86_64-linux.iso     # Build ISO
nix build .#packages.x86_64-linux.qcow2   # Build QCOW2
```

### configuration.nix

Complete NixOS system configuration (700+ lines):

- **Boot**: GRUB bootloader, quiet console
- **Networking**: DHCP + firewall (ports 22, 80, 443, 3001, 7687, 7474, 5432)
- **Users**: `nexus` user (sudoer), `root` (SSH disabled)
- **SSH**: Key-based auth only, no passwords
- **Services**: PostgreSQL, Neo4j, Redis, Nginx, Backend (systemd units with auto-restart)
- **Packages**: Essential CLI tools only (curl, wget, vim, htop, git, etc.)
- **Locale**: UTC timezone, en_US.UTF-8 locale
- **Monitoring**: TUI dashboard service + shell profile startup

### hardware-configuration.nix

VM hardware config:
- Bootloader: x86_64 with UEFI  
- Disk: `/dev/sda` with ext4 + swap
- QEMU virtio optimizations
- Networking predictable interface names

---

## 🛠️ Build & Deployment

### Prerequisites

- NixOS system or `nix` with flakes enabled
- ~10 GB free disk space
- 5-10 minutes build time
- Proxmox or KVM hypervisor for VM

### Build Steps

```bash
# 1. Enter directory
cd infrastructure

# 2. Update Nix dependencies
nix flake update

# 3. Build ISO (choose one):
nix build .#packages.x86_64-linux.iso -v      # ISO for USB/DVD/Proxmox
nix build .#packages.x86_64-linux.qcow2 -v    # QCOW2 for KVM

# 4. Find output
ls -lh result/iso/
```

### Deploy to Proxmox

```bash
# Copy to Proxmox storage
scp result/iso/nixos-*.iso root@proxmox:/var/lib/vz/template/iso/

# Create VM with required specs:
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

# Start VM from ISO
qm start 100

# Monitor boot (about 30 seconds)
qm terminal 100
```

---

## 📋 Service Architecture

### Startup Sequence

```
NixOS Boot
  ↓
systemd system-generators loaded
  ↓
Network initialization (DHCP)
  ↓
PostgreSQL starts (port 5432)
  ↓
Neo4j starts (port 7687)
  ↓
Redis starts (port 6379)
  ↓
Nginx starts (port 80/443)
  ↓
Backend API starts (depends on PG, Neo4j, Redis)
  ↓
Graph Mirror starts (sync service)
  ↓
~30 seconds → Ready for connections
  ↓
Auto-login nexus user
  ↓
TUI monitor displays on console
```

### Service Dependencies

```
nexus-backend.service
  ├─ network.target
  ├─ postgresql.service
  ├─ neo4j.service
  └─ redis.service

nexus-graph-mirror.service
  ├─ postgresql.service
  └─ neo4j.service

nginx.service
  ├─ network.target
  └─ (reverse proxy on :80 → :3001)
```

---

## 💻 Accessing the System

### SSH Access

```bash
# Get VM IP
ssh nexus@<vm-ip> -i ~/.ssh/id_rsa

# As root (with sudo)
sudo su -

# View system status
systemctl status

# Monitor backend
journalctl -u nexus-backend -f
```

### Adding SSH Keys

**Pre-boot** (modify configuration.nix):
```nix
openssh.authorizedKeys.keys = [
  "ssh-rsa AAAAB3Nza... your-public-key"
];
```

**Post-boot** (via SSH):
```bash
ssh nexus@<vm-ip>
echo "ssh-rsa AAAAB3Nza..." >> ~/.ssh/authorized_keys
```

### Web Access

```bash
# Web UI (reverse proxy)
http://<vm-ip>

# Direct API
http://<vm-ip>:3001/api/v1/docs
```

---

## 🔧 Operations

### Monitor Services

```bash
# Real-time dashboard
./monitor-remote.sh <vm-ip>

# Manual check
ssh nexus@<vm-ip> systemctl status
ssh nexus@<vm-ip> systemctl status nexus-backend
ssh nexus@<vm-ip> journalctl -u nexus-backend -f
```

### Deploy Backend Updates

```bash
./deploy-to-vm.sh <vm-ip> ~/.ssh/id_rsa
```

Builds backend, uploads, installs, restarts service.

### Manage Services

```bash
ssh nexus@<vm-ip>

# Restart backend after config change
sudo systemctl restart nexus-backend

# Stop all Nexus services
sudo systemctl stop nexus-backend nexus-graph-mirror

# View recent logs
journalctl -u nexus-backend -n 20
```

---

## 📈 Performance & Tuning

### VM Specs (Recommended)

| Resource | Minimum | Recommended | Maximum |
|----------|---------|-------------|---------|
| CPU | 2 cores | 4 cores | 16 cores |
| RAM | 4 GB | 8 GB | 32 GB |
| Disk | 20 GB | 50 GB | 500 GB |
| Network | 1 Gbps | 10 Gbps | - |

### Scale VM Resources

```bash
# After VM is stopped (in Proxmox)
qm set 100 --cores 8        # More CPU
qm set 100 --memory 16384   # More RAM

# Then start and continue
qm start 100
```

### Database Tuning

Edit `configuration.nix`:

```nix
services.postgresql.settings = {
  shared_buffers = "512MB";        # Higher for more RAM
  work_mem = "32MB";
  maintenance_work_mem = "256MB";  # For large operations
};

services.neo4j.settings = {
  "server.memory.heap.max_size" = "2048m";  # More for large graphs
};
```

Then rebuild: `sudo nixos-rebuild switch`

---

## 🔐 Security

### Default Configuration

- ✅ SSH key-based auth only (no passwords)
- ✅ Root SSH disabled
- ✅ Firewall enabled (specific ports only)
- ✅ No X11 or network services
- ✅ systemd hardening applied

### Production Hardening

1. **Change database passwords**
   ```bash
   ALTER USER nexus_user WITH PASSWORD 'strong-random';  # PostgreSQL
   ALTER USER neo4j SET PASSWORD 'strong-random';         # Neo4j
   ```

2. **Change JWT secret** in `/etc/nexus/backend.env`

3. **Enable SSL/TLS** (Let's Encrypt)
   ```bash
   # Add to configuration.nix
   services.nginx.enableReload = true;
   security.acme.acceptTerms = true;
   ```

4. **Restrict firewall**
   ```bash
   sudo ufw default deny incoming
   sudo ufw allow 22/tcp  # SSH only
   sudo ufw enable
   ```

5. **Harden SSH**
   ```bash
   # Edit configuration.nix
   services.openssh.settings.PubkeyAuthentication = true;
   services.openssh.settings.PasswordAuthentication = false;
   services.openssh.settings.PermitEmptyPasswords = false;
   ```

---

## 🐛 Troubleshooting

### Services won't start

```bash
# Check failed units
ssh nexus@<vm-ip> systemctl list-units --failed

# View error
ssh nexus@<vm-ip> journalctl -u nexus-backend -p err
```

### Database connection errors

```bash
# Test PostgreSQL
ssh nexus@<vm-ip> sudo -u postgres psql -c "SELECT 1"

# Test Neo4j
ssh nexus@<vm-ip> cypher-shell -u neo4j "RETURN 1"
```

### Disk space low

```bash
ssh nexus@<vm-ip>
df -h
# Clean logs if needed
sudo journalctl --vacuum=7d
```

See [DEPLOY_NEXUS_TUI.md](DEPLOY_NEXUS_TUI.md) for detailed troubleshooting.

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [DEPLOY_NEXUS_TUI.md](DEPLOY_NEXUS_TUI.md) | Complete deployment guide with examples |
| [TUI_APPLIANCE_GUIDE.md](TUI_APPLIANCE_GUIDE.md) | User manual & operations |
| [../backend/README.md](../backend/README.md) | Backend API documentation |
| [../frontend/README.md](../frontend/README.md) | Frontend documentation |

---

## 📦 Files Reference

### Build Scripts

- **build-iso.sh** - Build Nix ISO (run: `nix build .#iso`)
- **deploy-to-vm.sh** - Deploy backend to running VM (run: `./deploy-to-vm.sh <vm-ip>`)
- **monitor-remote.sh** - Real-time SSH monitoring dashboard
- **setup-first-boot.sh** - First-boot initialization (auto-runs on ISO boot)

### Configuration Files

| File | Lines | Purpose |
|------|-------|---------|
| flake.nix | 35 | Nix Flakes build config |
| configuration.nix | 400+ | Complete system configuration |
| hardware-configuration.nix | 35 | VM hardware probing |

### Documentation

| File | Size | Purpose |
|------|------|---------|
| DEPLOY_NEXUS_TUI.md | 600+ lines | Complete deployment guide |
| TUI_APPLIANCE_GUIDE.md | 400+ lines | User manual |
| README.md | This file | Overview |

---

## 🎯 Deployment Checklist

- [ ] Prerequisites: NixOS host, ~10 GB disk, Proxmox
- [ ] Clone/pull latest code
- [ ] `nix flake update` (update dependencies)
- [ ] `nix build .#iso -v` (build ISO, ~10 min)
- [ ] Copy ISO to Proxmox
- [ ] Create VM (4 CPU, 8 GB RAM, 50 GB disk)
- [ ] Boot from ISO (auto-installs)
- [ ] Verify services started (`systemctl status`)
- [ ] SSH access working
- [ ] Update database passwords
- [ ] Update JWT_SECRET
- [ ] Configure static IP (if needed)
- [ ] Set up backups
- [ ] Test restoration procedure
- [ ] Document access procedures
- [ ] Production deployment complete ✅

---

## 🚀 Next Steps

1. **Build**: `nix build .#packages.x86_64-linux.iso`
2. **Deploy**: Upload ISO to Proxmox, create VM, boot
3. **Access**: SSH to VM, check services, monitor
4. **Customize**: Edit `configuration.nix`, rebuild as needed
5. **Backup**: Set up automated database backups
6. **Monitor**: Use `./monitor-remote.sh` for ongoing health

---

**Project Nexus TUI Appliance - Ready for Production** 🎯
