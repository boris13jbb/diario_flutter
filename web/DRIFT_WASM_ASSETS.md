# Assets Drift Web (WasmDatabase)

Archivos oficiales requeridos por `lib/data/local/connection/open_connection_web.dart`.

## sqlite3.wasm

| Campo | Valor |
| --- | --- |
| Origen | https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3_flutter_libs-0.5.42/sqlite3.wasm |
| Versión compatible | sqlite3 2.x (`sqlite3_flutter_libs` 0.5.42; proyecto resuelve `sqlite3` 2.9.4) |
| Tamaño | 744878 bytes |
| SHA256 | `1b3096350a6e58ec7bafa9bf91d840f3631e7b41ea0ad06fb9d1a8c6e8786a5f` |

## drift_worker.js

| Campo | Valor |
| --- | --- |
| Origen | https://github.com/simolus3/drift/releases/download/drift-2.28.2/drift_worker.js |
| Versión | drift 2.28.2 |
| Tamaño | 355547 bytes |
| SHA256 | `6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610` |

No usar `sqlite3.wasm` de la línea sqlite3 3.x con Drift 2.28.x.
