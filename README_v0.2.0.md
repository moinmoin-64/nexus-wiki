# 🎉 v0.2.0 Release - Ready Now!

## Status: ✅ BEREIT ZUM DOWNLOAD

Der Release v0.2.0 ist jetzt auf GitHub und kann sofort heruntergeladen werden!

---

## 🚀 JETZT UPDATEN - 3 Simple Schritte

### Auf deinem NixOS-System:

```bash
cd /opt/nexus
git fetch origin v0.2.0
git checkout v0.2.0
```

**Fertig!** Version v0.2.0 ist jetzt aktiv.

---

## 📋 Was ist neu in v0.2.0?

- ✅ **Frontend UI** - Vue.js auf Port 5173 (funktioniert jetzt!)
- ✅ **NPM Fixes** - Alle Packages behoben (backend + frontend)
- ✅ **NixOS Integration** - Systemd-Services vollständig konfiguriert
- ✅ **Firewall** - Port 5173 offen
- ✅ **Nginx Routing** - Frontend und Backend richtig geroutet
- ✅ **Scripts & Docs** - Verification und Update-Guides

---

## 🔧 Nach dem Update

```bash
# Optional: NixOS-ISO mit neuer Config bauen
cd infrastructure
nix flake update
nix build .#packages.x86_64-linux.iso

# Danach: Mit neuer ISO rebootern
# Services starten automatisch!
```

---

## 🌐 Wiki öffnen

Nach dem Update:

```
Browser: http://<deine-IP>:5173
Login:   demo / demo123
```

---

## 📚 Weitere Infos

- Detaillierte Anleitung: [UPDATE_INSTRUCTIONS_DE.md](UPDATE_INSTRUCTIONS_DE.md)
- Schnelles Update-Script: [UPDATE_NOW.sh](UPDATE_NOW.sh)
- GitHub Release: https://github.com/moinmoin-64/nexus-wiki/releases/tag/v0.2.0

---

**Version v0.2.0 ist bereit. Starten Sie das Update jetzt!**
