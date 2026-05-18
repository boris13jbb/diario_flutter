# 📱 Diario de Aprendizaje - Flutter

Aplicación Flutter desarrollada como migración del proyecto Android nativo (Kotlin/Jetpack Compose). Registra anotaciones diarias de aprendizaje con soporte para audio y dibujo.

## 🚀 Características Implementadas

- ✅ **Estructura del proyecto** configurada con Clean Architecture
- ✅ **Modelos de dominio** migrados (DiaryEntry, AudioMarker, DrawStroke, DrawPoint)
- ✅ **Tema Material 3** con soporte para modo claro/oscuro
- ✅ **Supabase** configurado para autenticación y base de datos
- ✅ **Inyección de dependencias** con GetIt + Injectable
- ✅ **Gestión de estado** con Riverpod
- ⏳ Autenticación completa (Login, Registro, Recuperación)
- ⏳ Base de datos local con Drift (SQLite)
- ⏳ Repositorios (Auth, Diary)
- ⏳ Pantallas de autenticación
- ⏳ Pantalla principal (Home)
- ⏳ Editor avanzado con audio y dibujo
- ⏳ Navegación con go_router

## 📋 Requisitos Previos

- Flutter SDK 3.41.4 o superior
- Dart 3.11.1 o superior
- Cuenta de Supabase
- Android Studio / VS Code con extensiones de Flutter

## ⚙️ Configuración

### 1. Instalar Dependencias

```bash
cd diario_flutter
flutter pub get
```

### 2. Generar Código Automático

El proyecto usa code generation para modelos inmutables (freezed) y serialización JSON:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Para desarrollo continuo con watch mode:

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 3. Configurar Supabase

Las credenciales de Supabase están configuradas en `lib/main.dart`:

```dart
await Supabase.initialize(
  url: 'https://swirjlhuxcpcfuvketcv.supabase.co',
  anonKey: 'sb_publishable_cVlswOY8djMMTWsdV222Hw_hJRUOmba',
);
```

**Importante**: Reemplaza estas credenciales con las de tu propio proyecto de Supabase.

### 4. Configurar Base de Datos en Supabase

Ejecuta este SQL en el SQL Editor de Supabase:

```sql
-- Crear tabla para las entradas del diario
CREATE TABLE diary_entries (
    id TEXT PRIMARY KEY,
    date TEXT NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    last_updated BIGINT NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    synced BOOLEAN DEFAULT false,
    audio_markers JSONB DEFAULT '[]',
    draw_strokes JSONB DEFAULT '[]',
    audio_file_path TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Habilitar Row Level Security (RLS)
ALTER TABLE diary_entries ENABLE ROW LEVEL SECURITY;

-- Política: Los usuarios solo pueden ver sus propias entradas
CREATE POLICY "Users can view own entries"
    ON diary_entries FOR SELECT
    USING (auth.uid() = user_id);

-- Política: Los usuarios solo pueden insertar sus propias entradas
CREATE POLICY "Users can insert own entries"
    ON diary_entries FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Política: Los usuarios solo pueden actualizar sus propias entradas
CREATE POLICY "Users can update own entries"
    ON diary_entries FOR UPDATE
    USING (auth.uid() = user_id);

-- Política: Los usuarios solo pueden eliminar sus propias entradas
CREATE POLICY "Users can delete own entries"
    ON diary_entries FOR DELETE
    USING (auth.uid() = user_id);

-- Índices para mejorar consultas
CREATE INDEX idx_diary_entries_date ON diary_entries(date DESC);
CREATE INDEX idx_diary_entries_user_id ON diary_entries(user_id);
CREATE INDEX idx_diary_entries_synced ON diary_entries(synced);
```

### 5. Ejecutar la Aplicación

```bash
flutter run
```

## 🏗️ Arquitectura

El proyecto sigue Clean Architecture con las siguientes capas:

```
lib/
├── core/                      # Núcleo de la aplicación
│   ├── constants/            # Constantes
│   ├── theme/                # Tema Material 3
│   ├── utils/                # Utilidades
│   └── di/                   # Inyección de dependencias
│
├── data/                      # Capa de datos
│   ├── local/                # Base de datos local (Drift)
│   │   ├── dao/
│   │   └── entities/
│   ├── remote/               # Servicios Supabase
│   └── repositories/         # Implementación de repositorios
│
├── domain/                    # Capa de dominio
│   ├── models/               # Modelos de negocio
│   └── usecases/             # Casos de uso
│
└── presentation/              # Capa de presentación
    ├── screens/              # Pantallas
    ├── viewmodels/           # ViewModels (Riverpod)
    └── widgets/              # Widgets reutilizables
```

## 📦 Dependencias Principales

### UI & Diseño
- **google_fonts**: Tipografía Roboto
- **Material 3**: Sistema de diseño moderno

### Gestión de Estado
- **flutter_riverpod**: Gestión de estado reactivo
- **hooks_riverpod**: Hooks para Riverpod

### Navegación
- **go_router**: Navegación declarativa y type-safe

### Backend & Base de Datos
- **supabase_flutter**: Cliente de Supabase
- **drift**: Base de datos SQLite reactiva
- **sqlite3_flutter_libs**: Librerías nativas de SQLite

### Multimedia
- **record**: Grabación de audio
- **audioplayers**: Reproducción de audio
- **permission_handler**: Gestión de permisos

### Utilidades
- **get_it**: Service locator
- **injectable**: Inyección de dependencias automática
- **freezed**: Clases inmutables con code generation
- **json_serializable**: Serialización JSON
- **intl**: Internacionalización y formato de fechas
- **uuid**: Generación de IDs únicos

## 🔧 Scripts Útiles

### Obtener dependencias
```bash
flutter pub get
```

### Generar código automático
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Ejecutar tests
```bash
flutter test
```

### Analizar código
```bash
flutter analyze
```

### Formatear código
```bash
dart format .
```

### Construir APK (Android)
```bash
flutter build apk --release
```

### Construir IPA (iOS)
```bash
flutter build ios --release
```

## 🎯 Próximos Pasos

1. **Implementar autenticación**: Login, registro y recuperación de contraseña
2. **Configurar base de datos local**: Drift con DAOs y entidades
3. **Crear repositorios**: AuthRepository y DiaryRepository
4. **Implementar ViewModels**: Con Riverpod para gestión de estado
5. **Crear pantallas**: Auth, Home, Editor, Profile
6. **Configurar navegación**: Con go_router
7. **Implementar editor avanzado**: Soporte para audio y dibujo
8. **Agregar tests**: Unit tests e integration tests

## 📝 Notas de Desarrollo

### Diferencias con el Proyecto Android

| Android Nativo | Flutter |
|----------------|---------|
| Kotlin | Dart |
| Jetpack Compose | Flutter Widgets |
| Room | Drift (SQLite) |
| Hilt | GetIt + Injectable |
| StateFlow | Riverpod |
| Navigation Compose | go_router |
| Coroutines | async/await |

### Decisiones de Diseño

1. **Freezed para modelos**: Proporciona inmutabilidad, pattern matching y copyWith automáticamente
2. **Riverpod para estado**: Más flexible que Provider y mejor integración con Flutter
3. **Drift para base de datos**: Reactivo, type-safe y con excelente soporte para migrations
4. **GetIt + Injectable**: Inyección de dependencias automática y type-safe

## 🐛 Solución de Problemas

### Error de build_runner
Si encuentras errores al generar código:

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Error de Supabase
Verifica que las credenciales sean correctas y que la tabla exista en Supabase.

### Error de permisos (audio)
Asegúrate de configurar los permisos en AndroidManifest.xml e Info.plist

## 📄 Licencia

Este proyecto es de código abierto y está disponible para uso educativo.

## 👨‍💻 Autor

Migración del proyecto Android nativo a Flutter como ejemplo de desarrollo multiplataforma.

---

**¡Feliz desarrollo! 🚀**
