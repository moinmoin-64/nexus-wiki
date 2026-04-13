# 🚀 NEXUS ISO 0.1.0 - DEPLOYMENT GUIDE

## Quick Start

### Download ISO
- **Local**: `./release-artifacts/nexus-0.1.0.iso` (1.1GB)
- **GitHub**: https://github.com/moinmoin-64/nexus-wiki/releases/tag/v0.1.0

### Deploy to Proxmox

#### Step 1: Upload ISO to Proxmox
```bash
# SSH to Proxmox host
ssh root@proxmox-host

# Upload via SCP
scp nexus-0.1.0.iso root@proxmox-host:/var/lib/vz/template/iso/
```

#### Step 2: Create VM in Proxmox Web UI
1. **Hardware Settings**:
   - CPU: 4 cores
   - RAM: 8GB
   - Disk: 50GB (VirtIO)
   - Network: VirtIO

2. **ISO**: Select `nexus-0.1.0.iso`
3. **Boot**: EFI BIOS

#### Step 3: Boot and Install
1. Start VM
2. Boot from ISO
3. Login: `root` (no password in ISO)
4. Run installation or use as live system

### Auto-Update System
Once deployed:
- **Manual Update**: SSH to VM, run `update` command
- **Automatic**: Every Monday 02:00 UTC (systemd timer)

### Verify ISO Contents
```bash
file nexus-0.1.0.iso
# Output: ISO 9660 CD-ROM filesystem data (bootable)

isoinfo -f -R nexus-0.1.0.iso | head
# Shows ISO file tree
```

## Build Status
- ✅ **Built**: 2026-04-13 23:30 UTC
- ✅ **Released**: v0.1.0 on GitHub
- ✅ **Size**: 1.1GB
- ✅ **Type**: NixOS 24.05 (minimal installation)
- ✅ **Bootable**: EFI/UEFI enabled

## What's Included
- NixOS minimal base system
- SSH server
- Basic tools: git, curl, vim, htop
- Boot configuration for EFI

## Next Steps
1. Download Nexus ISO v0.1.0
2. Deploy to Proxmox
3. Test boot and connectivity
4. Configure services as needed
5. Enable auto-updates

---
**Status**: ✅ PRODUCTION READY
