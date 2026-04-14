# v0.2.0 Update - Schritt-für-Schritt Anleitung

Du kannst dein NixOS-System jetzt mit Release v0.2.0 updaten.

## WICHTIG: Welche IP hat dein NixOS-System?

Falls du noch die alte ISO laufen hast (192.168.178.116):
- Die hat die alten Services nicht
- Das ist OK - nach dem Update sind alle Services da

## Option 1: Mit SSH vom Hauptrechner (Empfohlen)

**Auf deinem Windows/Main-PC:**

```powershell
# SSH in dein NixOS-System
ssh nixos@192.168.178.116
# (Passwort eingeben oder Key)
```

**Dann auf der NixOS-Shell:**

```bash
cd /opt/nexus
git fetch origin v0.2.0
git checkout v0.2.0
```

Oder schneller mit dem Script:

```bash
bash /opt/nexus/scripts/update-to-v0.2.0.sh
```

## Option 2: Direkt auf dem NixOS-System (Wenn du am Terminal sitzt)

```bash
cd /opt/nexus
git fetch origin v0.2.0
git checkout v0.2.0
```

## Nach dem Update

Die neue Version ist jetzt heruntergeladen. Dann:

```bash
# 1. Neue NixOS-ISO mit aktualiserter Config bauen (optional)
cd /opt/nexus/infrastructure
nix flake update
nix build .#packages.x86_64-linux.iso

# 2. Mit neuer ISO neu starten (optional)
# Falls du die ISO gebaut hast, nutze sie zum Reboot

# 3. Services starten
sudo systemctl status postgresql neo4j redis nexus-backend nexus-frontend
```

## Jetzt sollte dein Wiki erreichbar sein

```
Browser: http://<deine-IP>:5173
Login: demo / demo123
```

## Was ist neu in v0.2.0?

✅ Frontend UI auf Port 5173 (funktioniert jetzt!)
✅ Alle npm-Packages sind behoben
✅ NixOS-Services richtig konfiguriert
✅ Firewall öffnet Port 5173
✅ Nginx routet Frontend und Backend korrekt

## Fragen?

Wenn Services nicht starten:
```bash
sudo journalctl -u nexus-backend -n 50
sudo systemctl restart nexus-backend
```

---

**Release v0.2.0 ist bereit zum Download auf GitHub!**
