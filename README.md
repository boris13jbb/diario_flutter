# NotasPro (diario_flutter)

Aplicación Flutter **offline-first** para crear, organizar y sincronizar notas personales.  
Stack: Flutter · Riverpod · go_router · Drift (SQLite) · Firebase Auth · Cloud Firestore.

## Funcionalidades

- Autenticación: registro, login, recuperación y cambio de contraseña
- CRUD de notas con **guardado automático**
- Categorías/carpetas con color
- Etiquetas, prioridad, color de nota, fijadas, favoritos, archivo y **papelera**
- Tareas con casillas, recordatorios, formato Markdown
- Búsqueda por título, contenido, categoría y etiquetas
- Orden por fecha, título, modificación y prioridad
- Historial de versiones (local + Firestore)
- Exportación Markdown / TXT / PDF / Word e impresión
- Copia de seguridad JSON
- Sincronización entre dispositivos (Drift ↔ Firestore)
- Tema claro / oscuro / sistema
- Panel de estadísticas en perfil
- Resumen con IA **opcional** (`AI_API_KEY`)
- PWA (manifest web NotasPro)

## Requisitos

- Flutter SDK compatible con Dart `^3.11.1`
- Proyecto Firebase (Auth + Firestore)
- Windows / Android / iOS / Web / macOS / Linux según plataforma

## Instalación

```bash
cd diario_flutter
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Configuración Firebase

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com/).
2. Activa **Authentication → Email/Password**.
3. Crea una base **Cloud Firestore**.
4. Despliega las reglas de `firestore.rules`.
5. Genera opciones con FlutterFire (`flutterfire configure`) o usa `lib/firebase_options.dart` existente.

Índices: ver `firestore.indexes.json` si Firestore lo solicita.

## Variables de entorno

Ver `.env.example`. Para IA opcional:

```bash
flutter run --dart-define=AI_API_KEY=tu_clave
```

Sin clave de IA la aplicación funciona con normalidad; solo la función de resumen quedará deshabilitada.

## Base de datos local

- Motor: **Drift / SQLite** (`diario.sqlite` en documentos de la app)
- Versión de esquema actual: **3**
- Migración automática desde v2 (añade flags de organización, papelera, tareas, adjuntos, etc.)
- Tabla adicional: `note_versions` (historial)

No requiere migraciones SQL manuales en el dispositivo: Drift las aplica al abrir la app.

## Ejecución en desarrollo

```bash
flutter run
# o plataforma concreta:
flutter run -d windows
flutter run -d chrome
```

## Compilación para producción

```bash
flutter build apk --release
flutter build appbundle --release
flutter build windows --release
flutter build web --release
```

## Pruebas

```bash
flutter test
flutter analyze
```

## Datos de demostración

No hay usuarios demo con contraseñas en el repositorio.  
Crea una cuenta desde **Registro** con tu email.

## Arquitectura

```
lib/
├── core/           # rutas, tema, DI, constantes
├── data/           # Drift, Firestore, repositorios
├── domain/         # modelos
├── presentation/   # pantallas Fluent + viewmodels
└── services/       # export, favoritos, adjuntos, IA, etc.
```

## Solución de errores frecuentes

| Problema | Solución |
|----------|----------|
| Fallo de `build_runner` | `flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs` |
| Índice Firestore faltante | Abre el enlace del error en consola y crea el índice |
| Sync sin notas | Verifica que el `user_id` coincida y que las rules estén desplegadas |
| Export en web | Preferir desktop/móvil; export usa sistema de archivos (`dart:io`) |
| Notificaciones | Requieren permisos del SO; no disponibles en todos los targets |

## Documentación de auditoría

- `AUDITORIA_FUNCIONALIDADES_NOTAS.md`
- `PLAN_IMPLEMENTACION_NOTAS.md`

## Licencia

Uso educativo / proyecto personal.
