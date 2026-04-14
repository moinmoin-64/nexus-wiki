@echo off
REM Update Project Nexus to v0.2.0 via SSH
REM Run this on Windows to update your NixOS system

setlocal enabledelayedexpansion

echo.
echo ╔════════════════════════════════════════╗
echo ║  NixOS Wiki Update zu v0.2.0          ║
echo ╚════════════════════════════════════════╝
echo.

set IP=192.168.178.116
set USER=nixos

echo Verbinde zu %USER%@%IP%...
echo.

REM SSH Command zum Updaten
ssh %USER%@%IP% "cd /opt/nexus && git fetch origin v0.2.0 && git checkout v0.2.0 && echo Update erfolgreich!"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Update zu v0.2.0 erfolgreich!
    echo.
    echo Nachster Schritt:
    echo   1. NixOS-System rebootern
    echo   2. Wiki offnen: http://%IP%:5173
    echo   3. Login: demo / demo123
) else (
    echo.
    echo Update fehlgeschlagen
    echo.
    echo Mogliche Losungen:
    echo   * SSH-Passwort uberpruefen
    echo   * IP-Adresse uberpruefen
    echo   * Manuell SSH eingeben: ssh %USER%@%IP%
)

pause
