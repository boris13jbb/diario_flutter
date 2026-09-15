import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regresión estática del fix Drift web (WasmDatabase + assets oficiales).
///
/// La apertura real de la base en Chrome se valida con
/// `tool/web_db_repro_main.dart` / `integration_test/web_database_smoke_test.dart`.
void main() {
  test('open_connection_web usa WasmDatabase y no WebDatabase legacy', () {
    final source = File(
      'lib/data/local/connection/open_connection_web.dart',
    ).readAsStringSync();

    expect(source, contains("import 'package:drift/wasm.dart';"));
    expect(source, contains('WasmDatabase.open'));
    expect(source, contains("'notaspro_diario'"));
    expect(source, isNot(contains("import 'package:drift/web.dart';")));
    expect(source, isNot(contains('WebDatabase(')));
  });

  test(
    'assets oficiales sqlite3.wasm y drift_worker.js tienen SHA256 esperado',
    () {
      final wasm = File('web/sqlite3.wasm');
      final worker = File('web/drift_worker.js');

      expect(wasm.existsSync(), isTrue);
      expect(worker.existsSync(), isTrue);
      expect(wasm.lengthSync(), 744878);
      expect(worker.lengthSync(), 355547);

      expect(
        sha256.convert(wasm.readAsBytesSync()).toString(),
        '1b3096350a6e58ec7bafa9bf91d840f3631e7b41ea0ad06fb9d1a8c6e8786a5f',
      );
      expect(
        sha256.convert(worker.readAsBytesSync()).toString(),
        '6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610',
      );
    },
  );
}
