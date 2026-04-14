# ✅ v0.2.0 Update - Für DICH (Windows Nutzer)

Du sitzt auf **Windows**. Dein NixOS-System läuft auf **192.168.178.116**.

## Der einfachste Weg: Doppelklick!

Gehe im Windows Explorer zu:

```
c:\Users\olist\Programmieren\wiki\update-to-v0.2.0.bat
```

**Doppelklick drauf** → Update läuft automatisch! ✅

Das Script verbindet sich via SSH zu deinem NixOS-System und updated auf v0.2.0.

---

## Oder: Mit PowerShell (für Profis)

```powershell
cd c:\Users\olist\Programmieren\wiki
.\update-to-v0.2.0.ps1
```

---

## Oder: Manuell über SSH

```powershell
ssh nixos@192.168.178.116
```

Passwort eingeben, dann:

```bash
cd /opt/nexus
git fetch origin v0.2.0
git checkout v0.2.0
```

---

## Nach dem Update

```
1. Optional: NixOS neu bauen
   cd /opt/nexus/infrastructure
   nix build .#packages.x86_64-linux.iso

2. NixOS rebooter

3. Wiki öffnen:
   http://192.168.178.116:5173
   
4. Login:
   demo / demo123
```

---

**Probiere es jetzt: Doppelklick auf `update-to-v0.2.0.bat`!**
