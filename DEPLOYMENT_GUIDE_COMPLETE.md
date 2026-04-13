# Project Nexus - Deployment Guide

## 🚀 NixOS Deployment (Complete)

### Prerequisites
- NixOS flake environment configured
- PostgreSQL 15
- Neo4j 5
- Node.js 18+
- DuckDNS account (for domain)
- GitHub account (for backups)

---

## 📋 Step 1: System Preparation

### 1.1 Generate NixOS ISO
```bash
cd infrastructure
nix flake update
nix build .#nixosConfigurations.nexus-vm.config.system.build.isoImage
# ISO is at result/iso/
```

### 1.2 Boot Proxmox VM from ISO
- Create QEMU VM in Proxmox (4 CPU, 8GB RAM, 50GB storage)
- Boot from ISO
- Follow NixOS installer

### 1.3 Configure System
```bash
sudo nano /etc/nixos/configuration.nix
# Add hostname, networking, users
sudo nixos-rebuild switch
```

---

## 🔐 Step 2: Secrets Management

### 2.1 Generate Required Secrets
```bash
# JWT Secret
openssl rand -base64 32

# PostgreSQL Password
pwgen 20 1

# Neo4j Password
pwgen 20 1

# DuckDNS Token
# Sign up at https://www.duckdns.org

# GitHub SSH Key (for backups)
ssh-keygen -t ed25519 -C "nexus-backup"
```

### 2.2 Set Environment Variables
```bash
# Backend
export JWT_SECRET="<generated-secret>"
export POSTGRES_URL="postgresql://nexus_user:<password>@localhost:5432/nexus_db"
export NEO4J_BOLT_URL="bolt://localhost:7687"
export NEO4J_PASSWORD="<generated-password>"

# Backup
export BACKUP_REPO_URL="git@github.com:yourorg/wiki-backups.git"
```

---

## 📦 Step 3: Deploy Services

### 3.1 Start PostgreSQL
```bash
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Initialize database
psql -U nexus_user -d nexus_db << EOF
CREATE SCHEMA nexus;
GRANT ALL ON SCHEMA nexus TO nexus_user;
EOF
```

### 3.2 Start Neo4j
```bash
sudo systemctl start neo4j
sudo systemctl enable neo4j

# Verify
cypher-shell -u neo4j -p $NEO4J_PASSWORD "RETURN 1"
```

### 3.3 Build Backend
```bash
cd backend
npm ci
npm run build

# Initialize database
npm run migrate
npm run seed

# Start backend
npm start
# Or use: npm run dev (for development)
```

### 3.4 Verify Backend Health
```bash
curl http://localhost:3001/health
# Expected: {"success":true,"status":"healthy",...}
```

### 3.5 Start Graph Mirror Service
```bash
cd backend
python3 services/graph-mirror.py
# Or as systemd service (configured in Nix)
```

---

## 🎨 Step 4: Deploy Frontend

### 4.1 Build Frontend
```bash
cd frontend
npm ci
npm run build
# Output: dist/
```

### 4.2 Configure Nginx (Done in configuration.nix)
```bash
# Already configured with:
# - Reverse proxy to backend (3001)
# - Let's Encrypt SSL/TLS
# - Security headers

sudo systemctl start nginx
sudo systemctl enable nginx
```

### 4.3 Verify Frontend Access
```bash
# Access via domain
open https://wiki.your-domain.duckdns.org
```

---

## 🔧 Step 5: Database Migrations

### 5.1 Run Migrations
```bash
cd backend
npm run migrate

# Output shows:
# - Migration 1: initial schema ✓
# - Migration 2: auth tables ✓
```

### 5.2 Seed Demo Data
```bash
npm run seed

# Creates:
# - admin user (admin123)
# - demo user (demo123)
# - sample documents
```

### 5.3 Verify Database
```bash
psql -U nexus_user -d nexus_db
nexus_db=> SELECT * FROM nexus.users;
nexus_db=> SELECT * FROM nexus.documents;
```

---

## 🧪 Step 6: Testing

### 6.1 Test Authentication
```bash
# Register
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "testpass123"
  }'

# Login
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "testpass123"
  }'

# Response includes: access_token, refresh_token
```

### 6.2 Test Document API
```bash
TOKEN="<access_token_from_login>"

# Create document
curl -X POST http://localhost:3001/api/documents \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Document",
    "content": "<p>Test</p>",
    "markdown_raw": "# Test\n\nMarkdown content",
    "status": "draft"
  }'

# List documents
curl -X GET http://localhost:3001/api/documents \
  -H "Authorization: Bearer $TOKEN"
```

### 6.3 Test Graph Queries
```bash
# Get document neighborhood
curl http://localhost:3001/api/graph/neighborhood/doc-uuid?depth=2

# Get centrality hubs
curl http://localhost:3001/api/graph/centrality?limit=20
```

---

## 💾 Step 7: Backup Configuration

### 7.1 Setup GitHub Backup Repository
```bash
# Create private repo: wiki-backups
# Add SSH key to GitHub account

git clone git@github.com:yourorg/wiki-backups.git
```

### 7.2 Enable Automated Backups
```bash
# Backups run automatically via systemd timer (every 12 hours)

# Monitor backup logs
journalctl -u nexus-backup.service -f

# Manual backup
sudo /opt/nexus/backup.sh
```

### 7.3 Verify Backups
```bash
# Check backup repo
cd ~/wiki-backups
ls -la
# Should show: database-*.sql.gz, backup.log

# Test restore (optional)
gunzip -c database-latest.sql.gz | psql -U nexus_user -d nexus_db
```

---

## 🔒 Step 8: Security Hardening

### 8.1 Firewall
```bash
# Already configured in configuration.nix
# Ports allowed: 22 (SSH), 80 (HTTP), 443 (HTTPS)

sudo systemctl status ufw
```

### 8.2 SSH Hardening
```bash
# Already configured:
# - Key-only authentication (no passwords)
# - Disable root login
# - Non-standard port (optional)

# Test SSH
ssh -i ~/.ssh/id_rsa nexus@wiki.your-domain.duckdns.org
```

### 8.3 SSL/TLS Certificates
```bash
# Let's Encrypt configured automatically
# Renewal runs daily via cron

# Check certificate
sudo certbot certificates

# Renew manually
sudo certbot renew --force-renewal
```

### 8.4 Security Headers
```bash
# Configured in nginx.nix:
# X-Frame-Options: DENY
# X-Content-Type-Options: nosniff
# Content-Security-Policy: strict

# Verify
curl -I https://wiki.your-domain.duckdns.org | grep X-
```

---

## 📊 Step 9: Monitoring & Logging

### 9.1 Backend Logs
```bash
# Development
cd backend && npm run dev
# Logs go to console

# Production
journalctl -u nexus-backend.service -f
# Or check: logs/all.log, logs/error.log

# Show structured logs
tail -f backend/logs/all.log | jq .
```

### 9.2 Database Logs
```bash
# PostgreSQL
sudo journalctl -u postgresql.service -f

# Neo4j
sudo journalctl -u neo4j.service -f
```

### 9.3 System Health
```bash
# Check all services
systemctl list-units --type=service --state=running | grep nexus

# Memory/CPU usage
top
htop

# Disk usage
df -h
```

---

## 🚨 Step 10: Troubleshooting

### Issue: Database Connection Failed
```bash
# Check PostgreSQL
sudo systemctl status postgresql
sudo -u postgres psql -l

# Check credentials
echo $POSTGRES_URL

# Verify user exists
psql -U nexus_user -d nexus_db -c "SELECT NOW();"
```

### Issue: Neo4j Not Connecting
```bash
# Restart Neo4j
sudo systemctl restart neo4j

# Check logs
sudo journalctl -u neo4j.service -n 50

# Test connection
cypher-shell -u neo4j -p $NEO4J_PASSWORD "RETURN 1"
```

### Issue: SSL Certificate Error
```bash
# Regenerate certificate
sudo certbot certonly --standalone -d wiki.your-domain.duckdns.org

# Restart nginx
sudo systemctl restart nginx
```

### Issue: API Returns 500 Errors
```bash
# Check backend logs
tail -f backend/logs/error.log

# Check env vars
env | grep -E "POSTGRES|NEO4J|JWT"

# Restart backend
npm run dev
```

---

## ✅ Verification Checklist

- [ ] PostgreSQL running and accessible
- [ ] Neo4j running and accessible
- [ ] Backend API healthy (GET /health returns 200)
- [ ] Frontend accessible via HTTPS
- [ ] Login/Register working
- [ ] Create document working
- [ ] Search working
- [ ] Graph visualization working
- [ ] Backups running (every 12h)
- [ ] SSL certificates valid
- [ ] Firewall rules correct
- [ ] Database migrations executed
- [ ] Demo data seeded

---

## 📞 Support

- Backend logs: `backend/logs/all.log`
- Database logs: `journalctl -u postgresql.service`
- Graph DB logs: `journalctl -u neo4j.service`
- Nginx logs: `/var/log/nginx/access.log`

For updates: Pull latest code and run `npm run migrate` again.

---

**Deployment Complete! 🎉**

Your Nexus instance is now ready for use. Access it at:
`https://wiki.your-domain.duckdns.org`
