# Plan de implementación — NotasPro / Diario Flutter

**Basado en:** `AUDITORIA_FUNCIONALIDADES_NOTAS.md`  
**Fecha:** 2026-07-29  
**Estrategia:** Extender el modelo `DiaryEntry` y Drift (schema v3+), sincronizar campos a Firestore, ampliar ViewModel/UI Fluent, sin cambiar de stack.

---

## Fase 1 — Corrección de errores existentes

| Ítem | Detalle |
|------|---------|
| Archivos | `README.md`, `test/widget_test.dart`, sync delete en `diary_repository.dart`, docs |
| Tablas/campos | — |
| Endpoints | N/A (Firestore) |
| UI | Splash test alineado |
| Riesgos | Bajo |
| Pruebas | `flutter test`, sync tras delete fallido |

**Trabajo:** Documentación Firebase; test splash; cola de eliminaciones pendientes; no resucitar soft-deleted.

---

## Fase 2 — Seguridad y autenticación

| Ítem | Detalle |
|------|---------|
| Archivos | `auth_service.dart`, `profile_screen.dart`, `firestore.rules`, servicio PIN |
| Campos | `lockPinHash` en nota; perfil `displayName` |
| UI | Diálogo PIN, actualizar nombre |
| Riesgos | PIN en texto plano — usar hash SHA-256 + salt |
| Pruebas | Cambio perfil; bloqueo/desbloqueo |

---

## Fase 3 — Modelo de datos y migraciones

| Ítem | Detalle |
|------|---------|
| Archivos | `diary_entries_table.dart`, `database.dart`, `diary_entry.dart`, DAO, mappers |
| Campos nuevos | `isPinned`, `isArchived`, `isDeleted`, `deletedAt`, `colorValue`, `priority`, `tagsJson`, `tasksJson`, `linksJson`, `attachmentsJson`, `reminderAt`, `lockPinHash`, `folderId` (alias categoría si aplica) |
| Tablas nuevas Drift | `NoteVersions` (historial), opcional `ActivityLogs` |
| Firestore | Mismos campos en documentos; colecciones `note_versions`, `shared_notes`, `note_comments` |
| Riesgos | Migración Drift irreversible parcial — defaults seguros |
| Pruebas | Abrir app con DB v2 → v3 sin pérdida |

---

## Fase 4 — CRUD completo

| Ítem | Detalle |
|------|---------|
| Archivos | Repository, ViewModel, `fluent_editor.dart` |
| UI | Autosave debounce, estados guardado |
| Riesgos | Bucles sync |
| Pruebas | Crear/editar offline/online |

---

## Fase 5 — Organización, filtros y búsqueda

| Ítem | Detalle |
|------|---------|
| Archivos | `diary_list_filter.dart`, `diary_sort_order.dart`, sidebar, ViewModel |
| UI | Filtros fijadas/archivo/tags; búsqueda por categoría y tags |
| Riesgos | Rendimiento listas grandes |
| Pruebas | Combinaciones de filtros |

---

## Fase 6 — Papelera, archivo, favoritos y fijadas

| Ítem | Detalle |
|------|---------|
| Métodos | `archive`, `unarchive`, `pin`, softDelete, restore, hardDelete, emptyTrash |
| UI | Secciones sidebar + confirmaciones |
| Riesgos | Sync de flags |
| Pruebas | Ciclo papelera completo |

---

## Fase 7 — Recordatorios y tareas

| Ítem | Detalle |
|------|---------|
| Archivos | Checklist en editor, `reminder_service.dart` |
| Dependencias | `flutter_local_notifications`, `timezone` |
| Riesgos | Permisos OS |
| Pruebas | Crear tarea, completar, programar reminder |

---

## Fase 8 — Archivos adjuntos

| Ítem | Detalle |
|------|---------|
| Archivos | `attachment_service.dart`, validadores |
| Dependencias | `file_picker`, `path_provider` |
| Límites | 10 MB, tipos whitelist |
| Riesgos | Web/`dart:io` |
| Pruebas | Adjuntar imagen/pdf, eliminar |

---

## Fase 9 — Compartición y permisos

| Ítem | Detalle |
|------|---------|
| Colección | `shared_notes` {noteId, ownerId, sharedWithEmail/uid, permission} |
| Rules | Lectura si owner o compartido |
| UI | Diálogo compartir |
| Riesgos | Seguridad rules |
| Pruebas | Usuario B lee nota compartida; no edita si read-only |

---

## Fase 10 — Historial de versiones

| Ítem | Detalle |
|------|---------|
| Tabla/colección | `note_versions` |
| Trigger | Antes de update significativo |
| UI | Lista versiones + restaurar |
| Riesgos | Volumen storage |
| Pruebas | Editar → historial → restore |

---

## Fase 11 — Exportación e impresión

| Ítem | Detalle |
|------|---------|
| Archivos | `note_export_service.dart` |
| Formatos | MD (existente), TXT, PDF, DOCX simple (HTML/XML), print |
| Dependencias | `pdf`, `printing` |
| Riesgos | Web |
| Pruebas | Export cada formato |

---

## Fase 12 — Sync y offline

| Ítem | Detalle |
|------|---------|
| Archivos | `connectivity_plus`, sync on reconnect, cola deletes |
| PWA | `web/manifest.json` branding |
| Riesgos | Conflictos — LWW por timestamp + UI si conflicto |
| Pruebas | Airplane mode CRUD + reconnect |

---

## Fase 13 — Colaboración

| Ítem | Detalle |
|------|---------|
| Alcance realista | Compartir + comentarios (no CRDT) |
| UI | Comentarios en detalle |
| Documentar | Edición RT colaborativa = mejora futura |
| Pruebas | Comentario de usuario compartido |

---

## Fase 14 — Voz e IA

| Ítem | Detalle |
|------|---------|
| Voz | `speech_to_text` opcional |
| IA | `AiSummaryService` con `AI_API_KEY` / `--dart-define` |
| Riesgos | Sin clave → mensaje claro |
| Pruebas | Sin clave no rompe app |

---

## Fase 15 — Panel de estadísticas

| Ítem | Detalle |
|------|---------|
| Archivos | `DiaryStats`, profile o pantalla stats |
| Métricas | archivadas, papelera, fijadas, tareas done/overdue |
| Pruebas | Contadores coherentes |

---

## Fase 16 — UI/UX, accesibilidad, responsive

| Ítem | Detalle |
|------|---------|
| Archivos | Fluent widgets, Shortcuts, Semantics |
| Calendario | Vista recordatorios |
| Pruebas | Manual móvil/desktop |

---

## Fase 17 — Pruebas y documentación

| Ítem | Detalle |
|------|---------|
| Tests | Auth validators, modelo flags, filtros, export, PIN hash |
| Docs | README, `.env.example`, este plan |
| Comandos | `flutter analyze`, `flutter test`, `flutter build` |

---

## Orden de ejecución inmediata

1. Extender modelo + Drift v3 + regenerar código  
2. Repository/ViewModel (flags, trash, pin, archive, tags, priority, tasks, reminder)  
3. UI sidebar/editor/detail  
4. Autosave, export, attachments, versions, share, notifications, AI stub, PWA, tests, README  

**Nota sobre “endpoints”:** El proyecto no tiene API REST propia; las operaciones equivalentes son métodos de repositorio + colecciones Firestore.
