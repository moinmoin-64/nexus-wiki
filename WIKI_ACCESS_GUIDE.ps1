# Project Nexus Wiki - Quick Access Guide
# For users running the NixOS ISO

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Project Nexus Wiki Access Guide" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "STEP 1: On the NixOS ISO Terminal" -ForegroundColor Yellow
Write-Host "Run this command to verify all services:" -ForegroundColor White
Write-Host ""
Write-Host "sudo systemctl status postgresql neo4j redis nexus-backend" -ForegroundColor Green
Write-Host ""

Write-Host "STEP 2: Get Your IP Address" -ForegroundColor Yellow
Write-Host "Run this command:" -ForegroundColor White
Write-Host ""
Write-Host "ip addr show" -ForegroundColor Green
Write-Host ""
Write-Host "Look for 'inet' under 'ens18:' - this is your IP (e.g., 192.168.178.116)" -ForegroundColor White
Write-Host ""

Write-Host "STEP 3: Access the Wiki" -ForegroundColor Yellow
Write-Host "Open your browser on your main PC and go to:" -ForegroundColor White
Write-Host ""
Write-Host "http://<YOUR_IP>:5173" -ForegroundColor Green
Write-Host ""
Write-Host "(Replace <YOUR_IP> with the actual IP from Step 2)" -ForegroundColor White
Write-Host ""

Write-Host "STEP 4: Login" -ForegroundColor Yellow
Write-Host "Use these credentials:" -ForegroundColor White
Write-Host ""
Write-Host "Demo User:" -ForegroundColor Cyan
Write-Host "  Username: demo" -ForegroundColor Green
Write-Host "  Password: demo123" -ForegroundColor Green
Write-Host ""
Write-Host "Admin User:" -ForegroundColor Cyan
Write-Host "  Username: admin" -ForegroundColor Green
Write-Host "  Password: admin123" -ForegroundColor Green
Write-Host ""

Write-Host "STEP 5: Verify Backend API (Optional)" -ForegroundColor Yellow
Write-Host "On NixOS, run:" -ForegroundColor White
Write-Host ""
Write-Host "curl http://localhost:3001/health" -ForegroundColor Green
Write-Host ""
Write-Host "You should see a JSON response confirming the API is running" -ForegroundColor White
Write-Host ""

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Services Running:" -ForegroundColor Cyan
Write-Host "  • PostgreSQL (Database)" -ForegroundColor Green
Write-Host "  • Redis (Cache)" -ForegroundColor Green
Write-Host "  • Neo4j (Graph DB)" -ForegroundColor Green
Write-Host "  • Nexus Backend API (port 3001)" -ForegroundColor Green
Write-Host "  • Frontend (port 5173)" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
