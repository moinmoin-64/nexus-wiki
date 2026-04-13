# Project Nexus - Complete Deployment Guide

## Overview

This guide walks through deploying Project Nexus from scratch to a production Proxmox environment. Total deployment time: ~1-2 hours.

---

## Prerequisites

### Proxmox Setup
- [ ] Proxmox VE 7.x+ installed and accessible at `https://proxmox.local:8006`
- [ ] Network connectivity to VM subnet (typically `192.168.100.0/24`)
- [ ] Admin credentials for Proxmox
- [ ] Internet connectivity on Proxmox (for package downloads)

### DNS
- [ ] DuckDNS account created (https://www.duckdns.org)
- [ ] Dynamic DNS record: `wiki-oliver.duckdns.org`
- [ ] DuckDNS token secured

### GitHub
- [ ] Repository created: `github.com/YOUR_USERNAME/nexus`
- [ ] Repository created: `github.com/YOUR_USERNAME/nexus-backups` (private)
- [ ] GitHub Personal Access Token created (for GitHub Actions)

### Local Requirements
- [ ] Nix installed (`curl -L https://nixos.org/nix | sh`)
- [ ] Git installed
- [ ] SSH client (Windows: Git Bash or WSL)

---

## Step 1: Prepare NixOS ISO Locally

### 1.1 Clone Repository
```bash
git clone https://github.com/YOUR_USERNAME/nexus.git
cd nexus
```

### 1.2 Update Infrastructure Configuration
Edit `infrastructure/configuration.nix` and other files with your settings:

```bash
# Update domain in nginx.nix
sed -i 's/wiki-oliver.duckdns.org/YOUR-DOMAIN.duckdns.org/g' infrastructure/services/nginx.nix

# Update email for Let's Encrypt
sed -i 's/nexus@wiki-oliver.duckdns.org/your-email@example.com/g' infrastructure/services/nginx.nix
```

### 1.3 Build ISO Locally
```bash
cd infrastructure

# Update flake lock file
nix flake update

# Build ISO
nix build .#packages.x86_64-linux.isoImage -L 2>&1 | tee build.log

# ISO location: result/iso/nixos-*.iso
ls -lh result/iso/
```

Build time: ~30-45 minutes depending on internet speed.

### 1.4 Test ISO (Optional)
```bash
# Create test VM
nix build .#packages.x86_64-linux.qcowImage -L

# Boot in QEMU
qemu-system-x86_64 -enable-kvm -m 4096 result/*.qcow2
```

---

## Step 2: Upload ISO to Proxmox

### 2.1 Copy ISO to Proxmox
```bash
# From your local machine
ISO_FILE=$(ls result/iso/nixos-*.iso | head -1)
scp "$ISO_FILE" root@proxmox.local:/var/lib/vz/dump/template/

# Or via SCP GUI if preferred
```

### 2.2 Verify Upload
```bash
ssh root@proxmox.local "ls -lh /var/lib/vz/dump/template/nixos-*.iso"
```

---

## Step 3: Create Proxmox VM

### 3.1 Create VM via Proxmox UI
1. Go to **Datacenter → Create VM**
2. Set these parameters:

| Setting | Value |
|---------|-------|
| VM ID | 100 |
| Name | nexus-wiki |
| Node | (your Proxmox node) |
| BIOS | OVMF (UEFI) |
| Machine | q35 |

### 3.2 Hardware Config
| Setting | Value |
|---------|-------|
| CPU Cores | 4 |
| RAM | 4096 MB |
| Boot Disk | 40 GB (VirtIO) |
| Network | VirtIO (Bridged) |

### 3.3 Mount ISO
1. Go to **VM → Hardware → CD/DVD Drive**
2. Select ISO file: `nixos-xxx.iso`
3. Click **Save**

### 3.4 Boot VM
1. **Start** the VM
2. GUI should show NixOS boot screen
3. Wait for boot to complete (~2 minutes)

---

## Step 4: First-Boot Configuration

### 4.1 Console Access
1. In Proxmox: **VM → Console**
2. Or: SSH to VM (after network is configured)

### 4.2 User Login
```bash
# Login as root
# Password: changeme (set in configuration.nix)

# Change root password
passwd

# Create SSH key for root
ssh-keygen -t ed25519 -f ~/.ssh/id_rsa -N ""
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### 4.3 Network Configuration
```bash
# Check IP address
ip a

# Note the IP (e.g., 192.168.100.50)
# Test connectivity
ping 8.8.8.8
```

### 4.4 Configure DuckDNS
```bash
# Install DuckDNS
sudo nix-env -i duck

# Update DuckDNS
duck www.duckdns.org YOUR_TOKEN

# Test
nslookup wiki-oliver.duckdns.org
```

### 4.5 Generate Backup SSH Key
```bash
# Create SSH key for automated backups
ssh-keygen -t ed25519 -f ~/.ssh/nexus-backup-key -N ""

# Copy public key to GitHub
cat ~/.ssh/nexus-backup-key.pub
# Add to GitHub Deploy Keys: Settings → Deploy Keys → Add Key
```

### 4.6 Initialize Backup Repository
```bash
# Clone backup repository
git clone git@github.com:YOUR_USERNAME/nexus-backups.git /var/backups/nexus
cd /var/backups/nexus

# Configure Git
git config user.name "Nexus Backup"
git config user.email "nexus@wiki-oliver.duckdns.org"

# Create initial commit
echo "# Nexus Backup Repository" > README.md
git add README.md
git commit -m "Initial commit"
git push -u origin main
```

### 4.7 Copy Backup Encryption Key
```bash
# Generate encryption key
echo "your-secure-random-key-32-chars" > /etc/nexus/backup.key
chmod 600 /etc/nexus/backup.key
```

---

## Step 5: System Services Startup

### 5.1 Check Service Status
```bash
# PostgreSQL
systemctl status postgresql.service
sudo -u postgres psql -d nexus_db -c "SELECT version();"

# Neo4j
systemctl status neo4j.service
curl -u neo4j:neo4j http://localhost:7474/

# Nginx
systemctl status nginx.service
curl -I http://localhost/

# Backup timer
systemctl status nexus-backup.timer
systemctl list-timers nexus-backup
```

### 5.2 Verify Database Schema
```bash
# Check database
sudo -u postgres psql nexus_db

# Inside psql:
\dt nexus.*
SELECT COUNT(*) FROM nexus.documents;
\l  # List all databases
\q  # Quit
```

### 5.3 SSL Certificate Setup
```bash
# Check ACME service
systemctl status acme-wiki-oliver.duckdns.org.service

# Check certificate
ls -la /var/lib/acme/

# Test HTTPS
curl -I https://wiki-oliver.duckdns.org/  # Should work after ~5min
```

---

## Step 6: Deploy Frontend & Backend

### 6.1 Clone Repository on VM
```bash
# SSH into VM
ssh root@NEXUS_IP

# Clone repo
git clone https://github.com/YOUR_USERNAME/nexus.git /opt/nexus
cd /opt/nexus
```

### 6.2 Build Backend
```bash
cd backend

# Install Node.js dependencies
npm install

# Install Python dependencies (for graph-mirror)
pip install psycopg2-binary neo4j python-dotenv

# Start services with screen/tmux
screen -S backend
npm start
# Ctrl+A, then D to detach
```

### 6.3 Build Frontend (Optional in VM)
```bash
cd frontend
npm install
npm run build

# Serve from Nginx
cp -r dist/* /var/www/nexus/
```

Or build locally and SCP to VM:
```bash
# On local machine
cd frontend
npm run build
scp -r dist/ root@NEXUS_IP:/var/www/nexus/
```

---

## Step 7: Verify All Services

### 7.1 Health Check Endpoints
```bash
# API health
curl https://wiki-oliver.duckdns.org/api/health

# Database connection
curl https://wiki-oliver.duckdns.org/api/documents?limit=1

# Graph connection
curl https://wiki-oliver.duckdns.org/api/graph/centrality
```

Expected response:
```json
{
  "status": "healthy",
  "postgres": "connected",
  "neo4j": "connected"
}
```

### 7.2 Log Monitoring
```bash
# View all logs
journalctl -xe

# Follow specific service
journalctl -u wiki-js -f
journalctl -u nexus-api -f
journalctl -u postgresql -f
journalctl -u neo4j -f
```

### 7.3 Frontend Access
```bash
# Open browser
https://wiki-oliver.duckdns.org

# Should see Nexus login/welcome screen
```

---

## Step 8: Initial Setup & Configuration

### 8.1 Create Admin User
```bash
# SSH into VM
ssh root@NEXUS_IP

# Create admin user via PostgreSQL
sudo -u postgres psql nexus_db << 'EOF'
INSERT INTO nexus.users (uuid, username, email, password_hash, role, created_at)
VALUES (
  gen_random_uuid(),
  'admin',
  'admin@example.com',
  'TODO_HASH_PLACEHOLDER',  -- implement bcrypt
  'admin',
  NOW()
);
EOF
```

### 8.2 Configure Git Backend
```bash
# Initialize Git for changelog
cd /var/lib/nexus
git init
git config user.name "Nexus System"
git config user.email "nexus@system"

# Add remote
git remote add origin git@github.com:YOUR_USERNAME/nexus-git-history.git
```

### 8.3 Test Backup Service
```bash
# Manually trigger backup
systemctl start nexus-backup.service

# Check backup file
ls -lh /var/backups/nexus/

# Verify Git push
cd /var/backups/nexus
git log --oneline
```

---

## Step 9: Production Hardening

### 9.1 Security Baseline
```bash
# Disable root password login
passwd -l root

# Update /etc/ssh/sshd_config
echo "PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config
echo "PermitRootLogin no" | sudo tee -a /etc/ssh/sshd_config
systemctl reload sshd

# Enable firewall
sudo ufw enable
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### 9.2 Kernel Hardening
Already configured in `configuration.nix`, verify:
```bash
# Check sysctl parameters
sysctl kernel.sysrq
sysctl kernel.dmesg_restrict
sysctl vm.panic_on_oom
```

### 9.3 Database Backups
```bash
# Verify automatic backups run
systemctl status nexus-backup.timer

# Check log
tail -f /var/log/nexus-backup.log
```

---

## Step 10: Monitoring & Maintenance

### 10.1 Set Up Monitoring (Optional)
```bash
# Install Prometheus node exporter
sudo nix-env -i prometheus-node-exporter

# Start service
systemctl enable prometheus-node-exporter
systemctl start prometheus-node-exporter

# Test
curl http://localhost:9100/metrics
```

### 10.2 Log Rotation
```bash
# Already configured via NixOS, verify
ls -l /etc/logrotate.d/

# Manual rotation
systemctl status logrotate.timer
```

### 10.3 Scheduled Health Checks
```bash
# Create cron job for health checks
crontab -e

# Add:
# */5 * * * * curl -s https://wiki-oliver.duckdns.org/health > /dev/null || echo "NEXUS DOWN" | mail -s "Alert" root@localhost
```

---

## Troubleshooting

### Issue: Nginx returns 502 Bad Gateway

**Solution:**
```bash
# Check backend service
systemctl status nexus-api.service
journalctl -u nexus-api -n 50

# Restart
systemctl restart nexus-api.service
```

### Issue: PostgreSQL won't start

**Solution:**
```bash
# Check data directory
ls -la /var/lib/postgresql/15/main/

# Check logs
journalctl -u postgresql -n 100

# Reset if corrupted
systemctl stop postgresql
rm -rf /var/lib/postgresql/15/main/*
systemctl start postgresql
```

### Issue: SSL certificate not renewing

**Solution:**
```bash
# Check ACME service
systemctl status acme-wiki-oliver.duckdns.org.service

# Manual dry-run
certbot renew --dry-run

# Troubleshoot
journalctl -u acme-* -f
```

### Issue: Backups not pushing to GitHub

**Solution:**
```bash
# Check SSH key
ssh -i ~/.ssh/nexus-backup-key -T git@github.com

# Test Git push
cd /var/backups/nexus
git push -u origin main

# Check logs
tail -f /var/log/nexus-backup.log
```

---

## Rollback & Recovery

### Restore from Backup
```bash
# Download latest backup
cd /tmp
git clone git@github.com:YOUR_USERNAME/nexus-backups.git

# Decrypt backup
cd nexus-backups
BACKUP=$(ls -t *.sql.gz* | head -1)
openssl enc -aes-256-cbc -d \
  -in "$BACKUP" \
  -out backup.sql.gz \
  -K $(cat /etc/nexus/backup.key | xxd -p -c 256)

# Restore database
systemctl stop postgresql
sudo -u postgres rm -rf /var/lib/postgresql/15/main/*
systemctl start postgresql

# Import backup
gunzip -c backup.sql.gz | sudo -u postgres psql
```

---

## Next Steps

1. **Create first document** in the UI
2. **Test wikilinks** by creating interconnected documents
3. **Monitor logs** for first 24 hours
4. **Set up external monitoring** (Prometheus/Grafana)
5. **Document custom workflows** for your team

---

## Support

- Check logs: `journalctl -xe`
- Neo4j browser: `http://localhost:7474` (local only)
- PostgreSQL client: `psql -h localhost -U nexus_user -d nexus_db`
- API docs: See `/backend/README.md`

---

**Deployment completed!** Your Nexus instance is live at `https://wiki-oliver.duckdns.org`
