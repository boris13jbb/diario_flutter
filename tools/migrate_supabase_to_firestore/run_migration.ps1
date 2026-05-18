# Ejecuta la migración Supabase → Firestore en Windows
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Test-Path ".env") -and -not (Test-Path "migracion.env")) {
    Write-Host "Creando migracion.env (archivo visible)..." -ForegroundColor Yellow
    Copy-Item ".env.example" "migracion.env"
    Write-Host "Edita migracion.env y pega tu SUPABASE_SERVICE_ROLE_KEY." -ForegroundColor Yellow
    notepad migracion.env
    exit 1
}

if (-not (Test-Path ".env") -and (Test-Path "migracion.env")) {
    Write-Host "Usando migracion.env (no se encontro .env)" -ForegroundColor Cyan
}

if (-not (Test-Path "serviceAccountKey.json")) {
    Write-Host "Falta serviceAccountKey.json en esta carpeta." -ForegroundColor Red
    Write-Host "Firebase Console → diario-notaspro → Configuración → Cuentas de servicio → Generar clave"
    exit 1
}

if (-not (Test-Path "node_modules")) {
    Write-Host "Instalando dependencias npm..."
    npm install
}

Write-Host "`n--- Simulación (dry-run) ---`n"
$env:DRY_RUN = "true"
node migrate.mjs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$confirm = Read-Host "`n¿Ejecutar migración REAL en Firestore? (s/N)"
if ($confirm -ne "s" -and $confirm -ne "S") {
    Write-Host "Cancelado."
    exit 0
}

Write-Host "`n--- Migración real ---`n"
$env:DRY_RUN = "false"
node migrate.mjs
