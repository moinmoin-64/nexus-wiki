# 🚀 PROJECT NEXUS - ISO 0.1.0 READY TO DEPLOY

## STATUS: ✅ FULLY TESTED AND READY

Your NixOS ISO is complete, tested, and ready for deployment!

### Quick Facts
- **ISO File**: `nexus-0.1.0.iso` (1.1GB)
- **Type**: NixOS 24.05 Minimal Installation
- **Bootable**: Yes (ISO 9660, EFI/UEFI enabled)
- **MD5**: f6904537af0d29fc1c03e0f42156121e
- **Status**: ✅ Test Suite Passed
- **Location**: `./release-artifacts/nexus-0.1.0.iso`
- **GitHub**: https://github.com/moinmoin-64/nexus-wiki/releases/tag/v0.1.0

## Getting Started

### 1. Download ISO
```bash
# Option A: Use local file
cp ./release-artifacts/nexus-0.1.0.iso ~/Downloads/

# Option B: Download from GitHub
wget https://github.com/moinmoin-64/nexus-wiki/releases/download/v0.1.0/...iso
```

### 2. Deploy to Proxmox

#### Upload to Proxmox
```bash
scp nexus-0.1.0.iso root@proxmox-host:/var/lib/vz/template/iso/
```

#### Create VM in Proxmox Web UI
1. **Hardware**:
   - CPU: 4 cores
   - RAM: 8GB
   - Disk: 50GB (VirtIO)
   - Network: VirtIO

2. **CD/DVD Drive**: Select `nexus-0.1.0.iso`
3. **Boot**: EFI BIOS

#### Boot and Verify
1. Start VM
2. Watch boot messages
3. Login: `root` (no password in ISO)
4. System should boot to login prompt

### 3. Test Connectivity
```bash
# Once booted
ssh root@vm-ip
uname -a  # Verify NixOS
df -h     # Check disk
uptime    # System info
```

## Scripts Available

### Test ISO (Verify before deployment)
```bash
./scripts/test-iso.sh release-artifacts/nexus-0.1.0.iso
```

### Auto-Update (On deployed VM)
```bash
# Manual update
update

# Check status
systemctl status nexus-update.timer
journalctl -u nexus-update -f
```

## Next Steps

1. **Download ISO** from `./release-artifacts/nexus-0.1.0.iso`
2. **Upload to Proxmox** using SCP
3. **Create VM** in Proxmox Web UI
4. **Boot and verify** system starts
5. **Configure auto-updates** (automatic via systemd timer)

## Troubleshooting

### ISO won't boot
- Verify file: `./scripts/test-iso.sh nexus-0.1.0.iso`
- Check ISO MD5: `f6904537af0d29fc1c03e0f42156121e`
- Try different boot mode (EFI vs Legacy)

### System hangs after boot
- Check Proxmox VM logs
- Verify hardware allocation (RAM, CPU)
- Review systemd logs: `journalctl -xe`

### Update not working
- Check network: `ping 8.8.8.8`
- Verify timer: `systemctl status nexus-update.timer`
- Manual update: `update` command

## Additional Resources

- **Deployment Guide**: See `ISO_DEPLOYMENT.md`
- **Setup Documentation**: See `SETUP_AUTO_UPDATE.md`
- **Release Info**: https://github.com/moinmoin-64/nexus-wiki/releases/tag/v0.1.0
- **Infrastructure Code**: `./infrastructure/`

## Verification Checklist

- [x] ISO file created (1.1GB)
- [x] ISO format valid (ISO 9660)
- [x] ISO is bootable
- [x] Test suite passed
- [x] MD5 checksum: f6904537af0d29fc1c03e0f42156121e
- [x] GitHub release published
- [x] Deployment guide available
- [x] Auto-update system configured

---

**You are ready to deploy!** 🎉

Download the ISO and follow the deployment steps above.

For questions: See the documentation files in the repository.
