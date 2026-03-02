@echo off
echo ========================================
echo   Enable Network Access for POS System
echo ========================================
echo.
echo This will open PowerShell as Administrator
echo.
pause

PowerShell -Command "Start-Process PowerShell -ArgumentList '-NoExit', '-Command', 'cd ''C:\Pos 2''; Write-Host ''Run this command:'' -ForegroundColor Yellow; Write-Host ''New-NetFirewallRule -DisplayName ''''POS System Server'''' -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow -Profile Any'''' -ForegroundColor Green' -Verb RunAs"
