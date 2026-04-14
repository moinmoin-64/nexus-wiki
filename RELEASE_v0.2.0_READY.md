# Release v0.2.0 - Ready to Download

## Status: ✅ RELEASED ON GITHUB

The release v0.2.0 is now available on GitHub with all fixes and improvements.

## How to Update Your NixOS System

### Option 1: Using Auto-Update System (If Configured)

```bash
sudo /opt/nexus/update.sh
```

This will automatically download and install v0.2.0.

### Option 2: Manual Update

On your NixOS system, run:

```bash
cd /opt/nexus
git fetch origin v0.2.0
git checkout v0.2.0
```

Or use the provided script:

```bash
bash /opt/nexus/scripts/update-to-v0.2.0.sh
```

## What v0.2.0 Includes

✅ **Frontend Service** - Vue.js UI on port 5173 (auto-start)
✅ **npm Package Fixes** - All dependencies corrected  
✅ **NixOS Integration** - All services as systemd units
✅ **Firewall Config** - Port 5173 opened
✅ **Nginx Routing** - Frontend and backend properly separated
✅ **Verification Scripts** - Easy health checks
✅ **Complete Documentation** - Setup guides and troubleshooting

## After Update

1. **Download release** (using command above)
2. **Rebuild NixOS ISO** (optional, if on ISO):
   ```bash
   cd infrastructure
   nix flake update
   nix build .#packages.x86_64-linux.iso
   ```
3. **Reboot** (if rebuilt ISO)
4. **Services auto-start** on boot
5. **Access wiki**: `http://<IP>:5173`

## Login Credentials

- **Demo User:** demo / demo123
- **Admin User:** admin / admin123

## Services Running After Update

- PostgreSQL (5432) - Document database
- Redis (6379) - Cache server
- Neo4j (7687) - Graph database
- Backend API (3001) - REST API
- Frontend UI (5173) - Wiki interface
- Nginx (80) - Reverse proxy

---

**Release v0.2.0 is ready for deployment!**

GitHub Release: https://github.com/moinmoin-64/nexus-wiki/releases/tag/v0.2.0
