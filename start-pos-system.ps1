#!/usr/bin/env pwsh
# POS System Startup Script
# This script starts the complete POS system on your local machine

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  POS System Server Startup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if a command exists
function Test-Command {
    param($Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# Function to check if Docker Desktop is running
function Test-DockerRunning {
    try {
        docker ps 2>&1 | Out-Null
        return $?
    } catch {
        return $false
    }
}

# Step 1: Check Docker
Write-Host "[1/6] Checking Docker..." -ForegroundColor Yellow
if (-not (Test-Command docker)) {
    Write-Host "❌ Docker is not installed!" -ForegroundColor Red
    Write-Host "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop" -ForegroundColor Red
    exit 1
}

if (-not (Test-DockerRunning)) {
    Write-Host "❌ Docker Desktop is not running!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please start Docker Desktop and wait for it to fully start." -ForegroundColor Yellow
    Write-Host "You'll see the Docker icon in your system tray when it's ready." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "After Docker Desktop is running, run this script again." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Docker is running" -ForegroundColor Green

# Step 2: Check Node.js
Write-Host "[2/6] Checking Node.js..." -ForegroundColor Yellow
if (-not (Test-Command node)) {
    Write-Host "❌ Node.js is not installed!" -ForegroundColor Red
    Write-Host "Please install Node.js from: https://nodejs.org/" -ForegroundColor Red
    exit 1
}
$nodeVersion = node --version
Write-Host "✅ Node.js $nodeVersion installed" -ForegroundColor Green

# Step 3: Start PostgreSQL Database
Write-Host "[3/6] Starting PostgreSQL database..." -ForegroundColor Yellow
Push-Location backend
try {
    $result = docker-compose up -d postgres 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ PostgreSQL database started" -ForegroundColor Green
        Write-Host "Waiting for database to be ready..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    } else {
        Write-Host "❌ Failed to start database" -ForegroundColor Red
        Write-Host $result
        exit 1
    }
} finally {
    Pop-Location
}

# Step 4: Install Backend Dependencies
Write-Host "[4/6] Installing backend dependencies..." -ForegroundColor Yellow
Push-Location backend
try {
    if (-not (Test-Path "node_modules")) {
        npm install
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "✅ Dependencies already installed" -ForegroundColor Green
    }
} finally {
    Pop-Location
}

# Step 5: Run Database Migrations
Write-Host "[5/6] Setting up database schema..." -ForegroundColor Yellow
Push-Location backend
try {
    npm run migrate
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Database schema created" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Migration may have already run (this is OK)" -ForegroundColor Yellow
    }
} finally {
    Pop-Location
}

# Step 6: Start Backend Server
Write-Host "[6/6] Starting backend server..." -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Backend Server Starting" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Backend API: http://localhost:3000" -ForegroundColor Cyan
Write-Host "WebSocket: ws://localhost:3000/ws" -ForegroundColor Cyan
Write-Host ""
Write-Host "Default Admin Credentials:" -ForegroundColor Yellow
Write-Host "  Email: admin@pos.com" -ForegroundColor White
Write-Host "  Password: admin123" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

Push-Location backend
try {
    npm start
} finally {
    Pop-Location
}
