# Auditoría de funcionalidades — NotasPro / Diario Flutter

**Fecha:** 2026-07-29  
**Proyecto:** `diario_flutter` (NotasPro)  
**Stack detectado:** Flutter 3.x / Dart 3.11 · Riverpod · go_router · Drift (SQLite) · Firebase Auth · Cloud Firestore · GetIt/Injectable · Freezed  

**Arquitectura:** Clean Architecture (domain / data / presentation) · Offline-first (local Drift + sync Firestore) · UI activa Fluent (`fluent_*`)  

**Autenticación:** Firebase Auth (email/password) · Protección de rutas con `go_router` redirect · Reglas Firestore por `user_id`  

---

## Resumen ejecutivo

| Estado | Cantidad (aprox.) |
|--------|-------------------|
| Implementada | 22 |
| Parcial | 18 |
| No implementada | 35 |
| Con errores / docs desfasadas | 5 |

El núcleo productivo cubre CRUD de notas, categorías, favoritos, búsqueda/orden, sync offline-first, auth básica, tema claro/oscuro y exportación Markdown. Faltan papelera, fijadas, archivo, etiquetas, prioridad, colores de nota, tareas, adjuntos reales, recordatorios, compartición, historial de versiones, exports PDF/Word/TXT/impresión, bloqueo PIN, PWA completa, colaboración y IA.

---

## Tabla de auditoría

| Nº | Funcionalidad | Estado | Archivos relacionados | Evidencia encontrada | Trabajo necesario | Prioridad |
|----|---------------|--------|----------------------|----------------------|-------------------|-----------|
| 1 | Crear notas | Implementada | `fluent_editor.dart`, `diary_viewmodel.dart`, `diary_repository.dart` | `createEntry` local+remoto | Mantener; añadir autosave | Alta |
| 2 | Consultar notas | Implementada | `fluent_sidebar.dart`, `diary_dao.dart` | Lista + stream Drift | Mantener | Alta |
| 3 | Editar notas | Implementada | `fluent_editor.dart`, `updateEntry` | Edición título/contenido/categoría | Autosave + campos nuevos | Alta |
| 4 | Eliminar notas | Parcial | `fluent_detail.dart`, `deleteEntry` | Eliminación **definitiva** (hard delete) | Soft-delete → papelera | Alta |
| 5 | Guardado automático | No implementada | `fluent_editor.dart` | Solo guardado manual (botón / tooltip Ctrl+S sin atajo) | Debounce + estados UI | Alta |
| 6 | Título y contenido | Implementada | `diary_entry.dart`, editor | Campos `title`/`content` | Mantener | Alta |
| 7 | Editor con formato | No implementada | `fluent_editor.dart` | Texto plano `TextField` | Toolbar Markdown básico + preview | Media |
| 8 | Fechas creación/modificación | Implementada | `diary_entry.dart`, tabla Drift | `createdAt`, `updatedAt`, `lastUpdated`, `date` | Mostrar ambas en UI de forma clara | Media |
| 9 | Categorías | Implementada | `note_category.dart`, `categories_repository.dart`, `category_picker_dialog.dart` | CRUD + color + filtro | Mejorar sync errores silenciosos | Alta |
| 10 | Carpetas | Parcial | Categorías como organización | No hay jerarquía de carpetas | Modelo `folderId` o alias carpetas=categorías documentado + UI “Carpetas” | Media |
| 11 | Etiquetas | No implementada | — | Sin campo tags | Campo `tags` JSON + UI chips + búsqueda | Alta |
| 12 | Buscador título/contenido/categoría/etiquetas | Parcial | `diary_viewmodel.filteredEntries` | Busca título/contenido/fecha; no categoría por nombre ni tags | Extender búsqueda | Alta |
| 13 | Notas favoritas | Implementada | `favorites_service.dart`, sidebar/detail | Prefs + Firestore `user_settings` | Mantener; limpiar huérfanos | Alta |
| 14 | Notas fijadas | No implementada | — | Sin `isPinned` | Campo + filtro + UI pin | Alta |
| 15 | Notas archivadas | No implementada | — | Sin `isArchived` | Campo + filtro Archivo | Alta |
| 16 | Papelera de reciclaje | No implementada | — | Hard delete | Soft-delete `isDeleted`/`deletedAt` + vista Papelera | Alta |
| 17 | Restauración | No implementada | — | — | `restoreEntry` | Alta |
| 18 | Eliminación definitiva | Parcial | `deleteEntry` | Es la única eliminación hoy | Separar soft vs hard | Alta |
| 19 | Vaciar papelera con confirmación | No implementada | — | — | Acción + diálogo | Alta |
| 20 | Ordenamiento título/fecha/modificación/prioridad | Parcial | `diary_sort_order.dart` | dateAsc/Desc, titleAsc, updatedDesc; **sin prioridad** | Añadir `priorityDesc` | Media |
| 21 | Filtros combinados | Parcial | ViewModel | Filtro lista + categoría + búsqueda se combinan | Incluir pinned/archived/tags/prioridad | Media |
| 22 | Colores personalizados de notas | Parcial | Solo color en categoría | Sin `colorValue` en nota | Campo + picker en editor | Media |
| 23 | Nivel de prioridad | No implementada | — | — | Enum 0–3 + UI | Media |
| 24 | Listas de tareas con casillas | No implementada | — | — | JSON `tasks` + checklist UI | Alta |
| 25 | Adjuntar imágenes | No implementada | Modelos audio/dibujo sin UI | `record` comentado en pubspec | Adjuntos locales + metadatos | Media |
| 26 | Adjuntar documentos | No implementada | — | — | `file_picker` + validación | Media |
| 27 | Adjuntar audio | Parcial | Campos `audioFilePath`/`audioMarkers` | Persistencia sin captura UI | Reactivar o adjunto de archivo audio | Baja |
| 28 | Agregar enlaces | No implementada | — | — | Lista `links` o detección URL | Media |
| 29 | Descargar/eliminar adjuntos | No implementada | — | — | Gestión de archivos locales | Media |
| 30 | Recordatorios fecha/hora | No implementada | — | — | Campo `reminderAt` + UI | Alta |
| 31 | Notificaciones de recordatorios | No implementada | — | — | `flutter_local_notifications` | Alta |
| 32 | Compartir notas | No implementada | — | — | Colección `shared_notes` + UI | Media |
| 33 | Permisos lectura/edición | No implementada | Rules solo owner | — | Rules + campo `permission` | Media |
| 34 | Exportar PDF | No implementada | Solo `.md` | `NoteExportService` | Paquete `pdf`/`printing` | Media |
| 35 | Exportar Word | No implementada | — | — | Export `.docx` o RTF/HTML compatible | Baja |
| 36 | Exportar TXT | No implementada | — | — | Escritura `.txt` | Media |
| 37 | Imprimir notas | No implementada | — | — | `printing` package | Media |
| 38 | Registro de usuarios | Implementada | `register_screen.dart`, `auth_service.dart` | Firebase `createUserWithEmailAndPassword` | Mantener | Alta |
| 39 | Inicio y cierre de sesión | Implementada | login, profile, `signOut` | Real | Mantener | Alta |
| 40 | Recuperación de contraseña | Implementada | `forgot_password_screen.dart` | `sendPasswordResetEmail` | Mantener | Alta |
| 41 | Cambio de contraseña | Implementada | `profile_screen.dart` | Reauth + `changePassword` | Mantener | Alta |
| 42 | Perfil del usuario | Implementada | `profile_screen.dart` | Email, stats, tema, export | Ampliar datos personales | Media |
| 43 | Actualización datos personales | Parcial | Solo password | Sin displayName | `updateProfile` Firebase | Media |
| 44 | Notas privadas por usuario | Implementada | `userId` + rules | Filtrado por usuario | Mantener | Alta |
| 45 | Impedir acceso a notas ajenas | Implementada | Firestore rules + queries por `userId` | Rules OK | Extender a compartidas | Alta |
| 46 | Bloqueo PIN/contraseña | No implementada | — | — | Hash PIN + diálogo desbloqueo | Media |
| 47 | Cifrado información sensible | Parcial | Firebase Auth hashes passwords | PIN/notas sin cifrado local | Hash PIN; cifrado opcional contenido bloqueado | Media |
| 48 | Control de sesiones | Parcial | Stream auth Firebase | Sin lista de dispositivos | Documentar límites Firebase; opción revoke | Baja |
| 49 | Cerrar sesión otros dispositivos | No implementada | — | Firebase no lo expone fácilmente en cliente | Mensaje + `signOut` local; mejora futura Admin SDK | Baja |
| 50 | Protección rutas/endpoints | Implementada | `app_router.dart` redirect + rules | Guards auth | Mantener | Alta |
| 51 | Validación archivos adjuntos | No implementada | — | — | Extensión, MIME, tamaño | Media |
| 52 | Límite tamaño/tipos | No implementada | — | — | Constantes + rechazo | Media |
| 53 | Protección SQLi/XSS/CSRF/authz | Parcial | Drift parametrizado; Firestore rules | Sin HTML renderizado (bajo XSS); sin CSRF típico REST | Sanitizar Markdown; validar inputs | Media |
| 54 | Registro de actividades | No implementada | — | — | Colección/tabla `activity_log` | Baja |
| 55 | Copias de seguridad | Parcial | Sync Firestore = backup nube | Sin export backup ZIP | Export JSON backup + restore | Media |
| 56 | Historial de versiones | No implementada | — | — | Guardar snapshot al editar | Media |
| 57 | Restaurar versión anterior | No implementada | — | — | UI historial + restore | Media |
| 58 | Sync entre dispositivos | Implementada | `syncAll`, auto-sync 30s | Offline-first real | Mejorar conflictos delete | Alta |
| 59 | Actualizaciones tiempo real | Parcial | Stream local Drift; sync periódico | No listeners Firestore live | Opcional snapshots Firestore | Baja |
| 60 | Funcionamiento sin conexión | Implementada | Drift local | CRUD offline | Mantener + cola deletes | Alta |
| 61 | Sync al recuperar conexión | Parcial | Auto-sync + resume | Sin `connectivity_plus` explícito | Detectar red y sync | Media |
| 62 | PWA | Parcial | `web/manifest.json` genérico | Nombre `diario_flutter` | Branding NotasPro + icons | Media |
| 63 | Notas colaborativas | No implementada | — | — | Compartir + multi-editor | Baja |
| 64 | Edición colaborativa RT | No implementada | — | — | Fuera de alcance realista sin CRDT; documentar | Baja |
| 65 | Comentarios en notas | No implementada | — | — | Subcolección comments | Baja |
| 66 | Asignación tareas a usuarios | No implementada | — | — | Campo `assigneeId` en tasks | Baja |
| 67 | Calendario recordatorios | No implementada | — | — | Vista calendario mensual | Media |
| 68 | Dictado por voz | No implementada | — | — | `speech_to_text` | Baja |
| 69 | Voz a texto | No implementada | — | — | Mismo servicio configurable | Baja |
| 70 | Escaneo/captura documentos | No implementada | — | — | Cámara/`image_picker` como adjunto | Baja |
| 71 | Corrección ortográfica | Parcial | SO/teclado nativo | Sin corrector in-app | Documentar dependencia del SO | Baja |
| 72 | Resumen IA | No implementada | — | — | Servicio opcional + env | Media |
| 73 | Modo claro y oscuro | Implementada | `theme_viewmodel.dart`, profile | light/dark/system | Mantener | Alta |
| 74 | Configuración apariencia | Parcial | Solo tema | Sin densidad/fuente | Ampliar settings | Baja |
| 75 | Panel principal con estadísticas | Parcial | Profile stats básicas | total, favoritos, categorías, palabras | Dashboard ampliado | Media |
| 76 | Stats creadas/archivadas/eliminadas/pendientes | Parcial | Solo total/favoritos/unsynced | — | Ampliar `DiaryStats` | Media |
| 77 | Stats tareas completadas/vencidas | No implementada | Sin tasks | — | Tras implementar tasks | Media |
| 78 | Accesible + teclado | Parcial | Semantics básicos; tooltips Ctrl+S | Sin Shortcuts reales | CallbackShortcuts + labels | Media |
| 79 | Estados carga/vacío/error | Implementada | Sidebar, detail, sync | Presentes | Completar en nuevas vistas | Alta |
| 80 | Confirmaciones operaciones delicadas | Parcial | Delete, logout | Falta vaciar papelera, hard delete | Ampliar diálogos | Alta |

---

## Hallazgos transversales

1. **README y `MIGRACION_ESTADO.md` obsoletos** — aún mencionan Supabase; el código usa Firebase.
2. **Pantallas legacy** (`HomeScreen`, `EditorScreen`, `EntryDetailScreen`) no están en el router.
3. **Multimedia** modelada pero sin UI; paquetes de audio deshabilitados.
4. **Tests** mínimos (`form_validators_test`, `widget_test` desalineado con splash).
5. **Delete hard** puede resucitar notas si falla el delete remoto antes del próximo sync.
6. **Export** usa `dart:io` (limitado en web).

---

## Criterio de implementación posterior

Se respetará el stack Flutter + Drift + Firebase. No se introducirá backend REST nuevo. Las “migraciones” serán Drift `schemaVersion` + campos Firestore compatibles (merge) + actualización de `firestore.rules`.
