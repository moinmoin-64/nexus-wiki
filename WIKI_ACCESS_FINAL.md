# Wie komme ich auf die Wiki Seite? - FINAL SOLUTION

## Option A: Direkt im Browser (Wenn System aktuell ist)

Öffne im Browser:
```
http://192.168.178.116:5173
```

**Anmeldedaten:**
- Benutzername: `demo`
- Passwort: `demo123`

---

## Option B: System muss erst aktualisiert werden auf v0.2.0

### Schritt 1: SSH mit NixOS verbinden

```powershell
ssh nixos@192.168.178.116
```

Passwort wenn gefragt: `nexus123`

### Schritt 2: Zu v0.2.0 aktualisieren

Im SSH Terminal eingeben:
```bash
cd /opt/nexus
git fetch origin v0.2.0
git checkout v0.2.0
```

### Schritt 3: Wiki öffnen

Browser: `http://192.168.178.116:5173`

Login: demo / demo123

---

## Alternativ: Automatisches Update von Windows

```powershell
cd C:\Users\olist\Programmieren\wiki
.\update-to-v0.2.0.ps1
```

Das macht alles automatisch per SSH.

---

## Wichtige Infos

| Service | Port | Status |
|---------|------|--------|
| Frontend (Wiki) | 5173 | ✅ v0.2.0 |
| Backend API | 3001 | ✅ v0.2.0 |
| PostgreSQL | 5432 | ✅ Online |
| Redis | 6379 | ✅ Online |
| Neo4j | 7687 | ✅ Online |

**SSH Zugangsdaten:**
- User: `nixos`
- Password: `nexus123`
- Host: `192.168.178.116`
- Port: `22`

---

## Bei Problemen

Wenn die Wiki nicht erreichbar ist:

1. **NixOS ist nicht online:**
   - NixOS System starten/SSH erreichbar machen
   - `ping 192.168.178.116` zum testen

2. **Frontend läuft nicht:**
   - SSH: `systemctl status nexus-frontend`
   - SSH: `systemctl restart nexus-frontend`

3. **Backend läuft nicht:**
   - SSH: `systemctl status nexus-backend`
   - SSH: `systemctl restart nexus-backend`

4. **Datenbank Problem:**
   - SSH: `systemctl status postgresql`
   - SSH: `systemctl status redis`

---

**Zusammenfassung:** Gehe zu `http://192.168.178.116:5173`, melde dich mit demo/demo123 an. Falls nicht erreichbar, führe Option B durch.
