/// Intervalo entre sincronizaciones automáticas en segundo plano.
const Duration kAutoSyncInterval = Duration(seconds: 30);

/// Evita lanzar varias sincronizaciones seguidas al abrir la app.
const Duration kMinSyncGap = Duration(seconds: 8);
