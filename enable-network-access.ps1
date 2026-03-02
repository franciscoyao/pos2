#!/usr/bin/env pwsh
# Enable Network Access for POS System
# This script must be run as Administrator

Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Enable Network Access for POS System    ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "  1. Right-click PowerShell" -ForegroundColor White
    Write-Host "  2. Select 'Run as Administrator'" -ForegroundColor White
    Write-Host "  3. Navigate to: cd 'C:\Pos 2'" -ForegroundColor White
    Write-Host "  4. Run: .\enable-network-access.ps1" -ForegroundColor White
    Write-Host ""
    pause
    exit 1
}

Write-Host "Checking existing firewall rules..." -ForegroundColor Yellow
$existingRule = Get-NetFirewallRule -DisplayName "POS System Server" -ErrorAction SilentlyContinue

if ($existingRule) {
    Write-Host "⚠️  Firewall rule already exists. Removing old rule..." -ForegroundColor Yellow
    Remove-NetFirewallRule -DisplayName "POS System Server"
}

Write-Host "Creating firewall rule for port 3000..." -ForegroundColor Yellow
try {
    New-NetFirewallRule -DisplayName "POS System Server" `
                        -Direction Inbound `
                        -LocalPort 3000 `
                        -Protocol TCP `
                        -Action Allow `
                        -Profile Any `
                        -Description "Allows incoming connections to POS System backend server on port 3000"
    
    Write-Host "✅ Firewall rule created successfully!" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create firewall rule: $_" -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""
Write-Host "════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  Network Access Enabled! ✓" -ForegroundColor Green
Write-Host "════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

# Get IP address
Write-Host "Your server is now accessible at:" -ForegroundColor Cyan
$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*"} | Select-Object -First 1).IPAddress

if ($ipAddress) {
    Write-Host ""
    Write-Host "  Local:   http://localhost:3000" -ForegroundColor White
    Write-Host "  Network: http://$ipAddress:3000" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Other devices on your network can now connect using:" -ForegroundColor Cyan
    Write-Host "  http://$ipAddress:3000" -ForegroundColor Yellow
} else {
    Write-Host "  http://localhost:3000" -ForegroundColor White
    Write-Host ""
    Write-Host "⚠️  Could not detect network IP address" -ForegroundColor Yellow
    Write-Host "Run 'ipconfig' to find your IPv4 address" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Make sure backend is running (it should be)" -ForegroundColor White
Write-Host "  2. Update client devices' config.json with your IP" -ForegroundColor White
Write-Host "  3. Connect from other devices on same network" -ForegroundColor White
Write-Host ""
Write-Host "See NETWORK_ACCESS_GUIDE.md for detailed instructions" -ForegroundColor Gray
Write-Host ""
pause
