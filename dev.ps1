param(
    [switch]$NoDocker,
    [string]$Device = ""
)

$root = $PSScriptRoot

function Start-App {
    param([string]$Title, [string]$WorkDir, [string]$Command)
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$WorkDir'; $Command" `
        -WindowStyle Normal
    Write-Host "  Started: $Title" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Petalia Dev Environment ===" -ForegroundColor Cyan
Write-Host ""

# --- Docker (DB + Redis) ---
if (-not $NoDocker) {
    Write-Host "[1/4] Starting Docker services (database + redis)..." -ForegroundColor Yellow
    $compose = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $compose) {
        Write-Host "  WARNING: Docker not found, skipping." -ForegroundColor Red
    } else {
        Start-Process powershell -ArgumentList "-NoExit", "-Command", `
            "cd '$root'; Write-Host 'Docker services' -ForegroundColor Cyan; docker compose up database redis" `
            -WindowStyle Normal
        Write-Host "  Started: Docker (database:5432, redis:6380)" -ForegroundColor Green
        Write-Host "  Waiting 5s for DB to be ready..." -ForegroundColor DarkGray
        Start-Sleep -Seconds 5
    }
}

# --- Backend ---
Write-Host "[2/4] Starting Backend (NestJS - http://localhost:3000)..." -ForegroundColor Yellow
Start-App -Title "Backend" `
    -WorkDir "$root\apps\backend" `
    -Command "Write-Host 'Backend - NestJS' -ForegroundColor Cyan; npm run start:dev"

# --- Admin ---
Write-Host "[3/4] Starting Admin (Angular - http://localhost:4200)..." -ForegroundColor Yellow
Start-App -Title "Admin" `
    -WorkDir "$root\apps\admin" `
    -Command "Write-Host 'Admin - Angular' -ForegroundColor Cyan; npm start"

# --- Mobile ---
Write-Host "[4/4] Starting Mobile (Flutter)..." -ForegroundColor Yellow
$flutterCmd = if ($Device) { "flutter run -d $Device" } else { "flutter run" }
Start-App -Title "Mobile" `
    -WorkDir "$root\apps\mobile" `
    -Command "Write-Host 'Mobile - Flutter' -ForegroundColor Cyan; $flutterCmd"

Write-Host ""
Write-Host "All services launched in separate windows." -ForegroundColor Cyan
Write-Host ""
Write-Host "  Backend  -> http://localhost:3000" -ForegroundColor White
Write-Host "  Admin    -> http://localhost:4200" -ForegroundColor White
Write-Host "  DB       -> localhost:5432" -ForegroundColor White
Write-Host "  Redis    -> localhost:6380" -ForegroundColor White
Write-Host ""
Write-Host "Options:" -ForegroundColor DarkGray
Write-Host "  .\dev.ps1 -NoDocker          # skip Docker" -ForegroundColor DarkGray
Write-Host "  .\dev.ps1 -Device chrome     # flutter run on specific device" -ForegroundColor DarkGray
Write-Host "  .\dev.ps1 -Device emulator   # flutter run on emulator" -ForegroundColor DarkGray
Write-Host ""
