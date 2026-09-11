# Dry-run de migración shared_notes contra Firestore Emulator.
# No ejecuta --apply. No toca producción.
#
# `dart run` / `flutter pub run` sobre tool/migrate_shared_notes.dart fallan
# en este proyecto por plugins nativos Firebase/FFI. El comando real de
# verificación en emulador es este harness de test.
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

firebase emulators:exec --only firestore --project diario-notaspro "flutter test test/shared_notes_migration_emulator_dry_run_test.dart"
