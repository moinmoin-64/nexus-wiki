# Why Services Not Found - Solution

## What Happened

You're running an **older NixOS ISO** that was built before I added the frontend service and other configurations. The services exist in the configuration files, but not on the ISO itself.

## Solution: Rebuild the ISO

You need to rebuild the NixOS ISO with the updated configuration.

### Step 1: Go Back to Your Windows Machine

Exit the NixOS system (close SSH/VM console).

### Step 2: Rebuild the ISO

On your Windows machine, open PowerShell and run:

```powershell
wsl bash -c "cd /mnt/c/Users/olist/Programmieren/wiki && chmod +x scripts/rebuild-iso.sh && ./scripts/rebuild-iso.sh"
```

Or manually run:

```bash
cd /mnt/c/Users/olist/Programmieren/wiki/infrastructure
nix flake update
nix build .#packages.x86_64-linux.iso
```

**⏱️ This takes 10-20 minutes. Please wait.**

### Step 3: Boot New ISO

Once the build completes:
- Copy the new ISO file to your VM/USB/boot location
- Reboot the system with the new ISO

### Step 4: Verify Services

Once booted, run:

```bash
sudo systemctl status postgresql neo4j redis nexus-backend nexus-frontend
```

All five services should show **● active (running)** in green.

## What Changed in the ISO

The new ISO now includes:
- ✅ PostgreSQL database
- ✅ Redis cache
- ✅ Neo4j graph database  
- ✅ Nexus Backend API (port 3001)
- ✅ **Nexus Frontend UI (port 5173)** ← NEW
- ✅ Auto-startup for all services

## Quick Access After Reboot

```bash
# 1. Get your IP
ip addr show ens18

# 2. Open in browser (from another PC)
http://<YOUR_IP>:5173

# 3. Login
Username: demo
Password: demo123
```

---

**Do you want to rebuild the ISO now?**
