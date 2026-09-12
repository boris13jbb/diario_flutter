import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Conexión Drift web moderna (WasmDatabase).
///
/// Requiere `web/sqlite3.wasm` y `web/drift_worker.js` servidos junto a la app.
/// Sin COOP/COEP, Drift puede usar fallback IndexedDB.
QueryExecutor openConnection() {
  return DatabaseConnection.delayed(
    Future(() async {
      final result = await WasmDatabase.open(
        databaseName: 'notaspro_diario',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );

      if (result.missingFeatures.isNotEmpty) {
        // ignore: avoid_print
        print(
          'Drift web usa ${result.chosenImplementation} por features '
          'faltantes: ${result.missingFeatures}',
        );
      }

      return result.resolvedExecutor;
    }),
  );
}
