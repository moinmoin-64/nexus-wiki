# Services Not Found - Next Steps

## Your Current Situation

✅ You booted the NixOS ISO successfully  
❌ The services (postgresql, neo4j, redis, nexus-backend, nexus-frontend) are not found  

**Reason:** The ISO you're running was built BEFORE I added the frontend service to the configuration.

## What You Need to Do

### Option A: Rebuild ISO (Recommended)

**On your Windows PC in PowerShell:**

```powershell
wsl bash -c "cd /mnt/c/Users/olist/Programmieren/wiki/infrastructure && nix flake update && nix build .#packages.x86_64-linux.iso"
```

**Time required:** 10-20 minutes

**After build completes:**
1. Find the ISO file in: `result/iso/nixos-*.iso`
2. Reboot your NixOS VM/machine with the new ISO
3. Services will auto-start

### Option B: Manual Service Setup (Advanced)

If you don't want to rebuild, you can manually start services on the current ISO:

```bash
# Check what services are available
sudo systemctl list-unit-files | grep nexus

# If services exist but are not running
sudo systemctl start postgresql
sudo systemctl start redis  
sudo systemctl start neo4j
sudo systemctl start nexus-backend

# Check status
sudo systemctl status postgresql redis neo4j nexus-backend
```

## Recommended: Rebuild Now

The easiest and most reliable path is to **rebuild the ISO with the updated configuration**.

1. **Exit NixOS** (close the terminal/SSH session)
2. **On Windows, open PowerShell and run:**

```powershell
wsl bash -c "cd /mnt/c/Users/olist/Programmieren/wiki/infrastructure && nix flake update && nix build .#packages.x86_64-linux.iso && echo 'Build complete! ISO is ready.'"
```

3. **Wait for completion** (you'll see "Build complete!" when done)
4. **Copy the new ISO** and reboot your NixOS system
5. **Run on the new ISO:**

```bash
sudo systemctl status postgresql neo4j redis nexus-backend nexus-frontend
ip addr show ens18
```

6. **Access the wiki:**

Open browser: `http://<YOUR_IP>:5173`  
Login: `demo` / `demo123`

## After Reboot with New ISO

All services will:
- ✅ Be installed and configured
- ✅ Auto-start on boot
- ✅ Be accessible immediately

---

**Ready to proceed? Run the rebuild command on your Windows machine.**
