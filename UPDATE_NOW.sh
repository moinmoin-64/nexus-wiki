#!/bin/bash
# QUICK START: Update to v0.2.0 jetzt sofort
# Führe diesen Command auf deinem NixOS-System aus:

echo "Project Nexus Wiki - v0.2.0 Update"
echo "===================================="
echo ""
echo "Schritt 1: Repository aktualisieren"
cd /opt/nexus 2>/dev/null || { echo "ERROR: /opt/nexus nicht gefunden"; exit 1; }
git fetch origin v0.2.0 || { echo "ERROR: Git fetch fehlgeschlagen"; exit 1; }

echo ""
echo "Schritt 2: Zu v0.2.0 wechseln"
git checkout v0.2.0 || { echo "ERROR: Git checkout fehlgeschlagen"; exit 1; }

echo ""
echo "Schritt 3: Verifikation"
if git describe --tags | grep -q v0.2.0; then
    echo "✓ v0.2.0 erfolgreich aktualisiert!"
    echo ""
    echo "Neue Features:"
    echo "  • Frontend UI auf Port 5173"
    echo "  • Alle npm-Packages behoben"
    echo "  • Systemd-Services konfiguriert"
    echo ""
else
    echo "✗ Update fehlgeschlagen"
    exit 1
fi

echo ""
echo "Nächster Schritt:"
echo "1. NixOS ISO neu bauen (optional):"
echo "   cd infrastructure && nix build .#packages.x86_64-linux.iso"
echo ""
echo "2. System mit neuer ISO rebootern"
echo ""
echo "3. Wiki öffnen unter:"
echo "   http://<deine-IP>:5173"
echo "   Login: demo / demo123"
echo ""
