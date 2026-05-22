/// Intervalo entre sincronizaciones automáticas en segundo plano.
const Duration kAutoSyncInterval = Duration(minutes: 1);

/// Evita lanzar varias sincronizaciones seguidas al abrir la app.
const Duration kMinSyncGap = Duration(seconds: 15);
