# Prueba automática offline-first contra Auth + Firestore Emulator.
# No despliega reglas ni toca el proyecto remoto.
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

firebase emulators:exec --only auth,firestore --project diario-notaspro "flutter test integration_test/sync_offline_first_test.dart -d windows"
