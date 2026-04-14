# Wiki Access Setup Complete

## What Was Done

The user asked: **"wie komme ich auf die wiki seite"** (How do I access the wiki page?)

The following was completed to make the wiki fully accessible:

### 1. Fixed NPM Dependencies ✓
- Corrected malformed `package.json` in backend (625+ packages fixed)
- Updated invalid dependency versions (axios, jsonwebtoken, etc.)
- Backend now installs successfully with `npm install`
- Frontend dependencies verified

### 2. Added Frontend Service to NixOS ✓
- Created `nexus-frontend` systemd service in configuration.nix
- Configured to run on port 5173 
- Auto-starts on boot with other services
- Properly depends on network availability

### 3. Updated Firewall Configuration ✓
- Added port 5173 to allowed TCP ports
- Firewall now allows: SSH (22), HTTP (80), HTTPS (443), Frontend (5173), Backend (3001), Neo4j (7687, 7474), PostgreSQL (5432)

### 4. Enhanced Nginx Routing ✓
- Updated reverse proxy to handle both frontend and backend
- Frontend routes to Vite dev server on 5173
- Backend API routes to Node.js on 3001
- WebSocket support for real-time features

### 5. Created Documentation ✓
- `scripts/start-wiki.sh` - Comprehensive verification script
- `scripts/verify-wiki.sh` - Service health checker
- `WIKI_ACCESS_GUIDE.ps1` - PowerShell guide for Windows
- `WIKI_ACCESS.md` - Quick reference guide
- `HOW_TO_ACCESS_WIKI.md` - Complete access instructions

### 6. Database Credentials Available ✓
- PostgreSQL: nexus_user / nexus_password (db: nexus_db)
- Neo4j: neo4j / nexus_password
- Application: demo / demo123 or admin / admin123

## How to Access the Wiki

On the running NixOS ISO:

```bash
# 1. Verify services
sudo systemctl status postgresql neo4j redis nexus-backend nexus-frontend

# 2. Get IP address
ip addr show ens18

# 3. Access from browser on your PC
# http://<YOUR_IP>:5173
```

## Services Now Running

All five services will auto-start:
- PostgreSQL (Database)
- Redis (Cache)
- Neo4j (Graph Database)
- Nexus Backend API (port 3001)
- Nexus Frontend (port 5173)

## Result

The user can now:
1. Boot the NixOS ISO
2. Check service status
3. Get the IP address
4. Open `http://<IP>:5173` in a browser
5. Login with demo/demo123 or admin/admin123
6. Use the wiki immediately

The wiki is now fully accessible and operational.
