#!/bin/powershell
# SSH zu NixOS und Update zu v0.2.0
# Führe dieses Script auf Windows aus

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  NixOS Wiki Update zu v0.2.0          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# IP Adresse
$IP = "192.168.178.116"
$USER = "nixos"

Write-Host "Verbinde zu $USER@$IP..." -ForegroundColor Yellow
Write-Host ""

# SSH Command zum Updaten
$COMMAND = @'
cd /opt/nexus && git fetch origin v0.2.0 && git checkout v0.2.0 && echo "✓ Update erfolgreich!" && git describe --tags
'@

# SSH ausführen
ssh "$USER@$IP" "$COMMAND"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Update zu v0.2.0 erfolgreich!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Nächster Schritt:" -ForegroundColor Yellow
    Write-Host "  1. NixOS-System rebootern" -ForegroundColor White
    Write-Host "  2. Wiki öffnen: http://$IP:5173" -ForegroundColor White
    Write-Host "  3. Login: demo / demo123" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "❌ Update fehlgeschlagen" -ForegroundColor Red
    Write-Host ""
    Write-Host "Mögliche Lösungen:" -ForegroundColor Yellow
    Write-Host "  • SSH-Passwort überprüfen" -ForegroundColor White
    Write-Host "  • IP-Adresse überprüfen" -ForegroundColor White
    Write-Host "  • Manuell SSH eingeben: ssh nixos@$IP" -ForegroundColor White
}
