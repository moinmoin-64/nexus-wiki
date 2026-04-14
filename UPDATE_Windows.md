# v0.2.0 Update - Für Windows Nutzer

Du sitzt auf Windows, nicht auf NixOS. So updatest du richtig:

## Option 1: Mit PowerShell Script (Einfachste Methode)

Auf deinem Windows-PC, öffne PowerShell und führe aus:

```powershell
cd c:\Users\olist\Programmieren\wiki
.\update-to-v0.2.0.ps1
```

Das Script verbindet sich via SSH zu deinem NixOS-System und updated automatisch.

## Option 2: Manuell via SSH

```powershell
# Verbinde zu NixOS
ssh nixos@192.168.178.116

# Dann auf der NixOS-Shell:
cd /opt/nexus
git fetch origin v0.2.0
git checkout v0.2.0

# Fertig! Update erfolgreich wenn du siehst: v0.2.0
```

## Option 3: Mit WSL

```powershell
wsl bash -c "ssh nixos@192.168.178.116 'cd /opt/nexus && git fetch origin v0.2.0 && git checkout v0.2.0'"
```

## Nach dem Update

```bash
# Optional: Neue NixOS-ISO bauen
cd /opt/nexus/infrastructure
nix build .#packages.x86_64-linux.iso

# Dann: System mit neuer ISO rebootern
# Wiki ist verfügbar unter: http://192.168.178.116:5173
```

## Probleme?

**SSH funktioniert nicht?**
- Überprüfe, ob dein NixOS-System läuft (IP: 192.168.178.116)
- Überprüfe das SSH-Passwort
- Versuche: `ping 192.168.178.116`

**Du kennst deine NixOS-IP nicht?**
- Auf dem NixOS-System eingeben: `ip addr show ens18`
- Die IP steht neben "inet"

---

**Starten Sie das Update jetzt!**
