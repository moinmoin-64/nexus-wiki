# ⚡ SCHNELLE LÖSUNG - Ohne neuer ISO

Die ISO-Build hat Probleme. Aber du kannst **sofort** mit deinem aktuellen NixOS-System updaten!

## 🔑 SSH-Alternative: Direkte Passwort-Update

Auf deinem aktuellen NixOS-System (192.168.178.116):

```bash
# Setze Passwort für nixos-Benutzer
sudo passwd nixos
# Gib ein: nexus123
# Bestätige: nexus123

# Dann: Update zu v0.2.0
cd /opt/nexus
git fetch origin v0.2.0
git checkout v0.2.0

# Fertig!
```

## Oder als Single-Command:

```bash
echo "nexus123" | sudo passwd nixos --stdin && cd /opt/nexus && git fetch origin v0.2.0 && git checkout v0.2.0
```

## Danach:

```bash
# Optional: Reboot
sudo reboot

# Wiki öffnen
# http://192.168.178.116:5173
# Login: demo / demo123
```

---

## Wenn du direkt am NixOS-Terminal sitzt:

```bash
sudo passwd nixos
# Passwort: nexus123
cd /opt/nexus
git fetch origin v0.2.0
git checkout v0.2.0
```

---

## FERTIG! 🎉

Dein System hat jetzt v0.2.0 mit:
- ✅ Frontend UI (Port 5173)
- ✅ Alle npm-Fixes  
- ✅ Passwort SSH funktioniert jetzt
- ✅ Autostart für alle Services

**Wiki ist bereit unter:** http://192.168.178.116:5173
