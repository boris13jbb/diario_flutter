import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/diary_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/form_validators.dart';
import '../../widgets/fluent_colors.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final diaryState = ref.watch(diaryViewModelProvider);
    final themeMode = ref.watch(themeModeProvider);
    final stats = ref.read(diaryViewModelProvider.notifier).stats;
    final scheme = Theme.of(context).colorScheme;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final email = authState.userEmail ?? 'Usuario';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'U';

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPad),
          children: [
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: FluentSpacing.lg),
            Text(
              email,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (diaryState.lastSyncedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Última sync: ${_formatDateTime(diaryState.lastSyncedAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: FluentSpacing.xl),
            _StatsGrid(stats: stats, scheme: scheme),
            const SizedBox(height: FluentSpacing.lg),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.book_outlined, color: scheme.primary),
                    title: const Text('Mis entradas'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(AppRoutes.home),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.file_download_outlined, color: scheme.primary),
                    title: const Text('Exportar todas las notas'),
                    subtitle: const Text('Guarda un archivo Markdown'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _exportAll(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.backup_outlined, color: scheme.primary),
                    title: const Text('Copia de seguridad JSON'),
                    subtitle: const Text('Exporta todas las notas con metadatos'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _exportBackup(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.lock_outline, color: scheme.primary),
                    title: const Text('Cambiar contraseña'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showChangePasswordDialog(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FluentSpacing.lg),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.brightness_6_outlined, color: scheme.primary),
                    title: const Text('Tema'),
                    subtitle: Text(_themeLabel(themeMode)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('Sistema'),
                          icon: Icon(Icons.brightness_auto, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Claro'),
                          icon: Icon(Icons.light_mode, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Oscuro'),
                          icon: Icon(Icons.dark_mode, size: 16),
                        ),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (value) {
                        ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(value.first);
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.info_outline, color: scheme.primary),
                    title: const Text('Acerca de'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'NotasPro',
                        applicationVersion: '1.0.0',
                        applicationLegalese: 'Diario de Aprendizaje',
                        children: const [
                          Text(
                            'Notas offline-first con sincronización Firebase, categorías y favoritos en la nube.',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: FluentSpacing.lg),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: FluentColors.error),
                title: const Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: FluentColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Cerrar sesión'),
                      content: const Text(
                        '¿Seguro que quieres cerrar sesión en este dispositivo?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Cerrar sesión'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true) return;
                  await ref.read(authViewModelProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go(AppRoutes.login);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Tema claro';
      case ThemeMode.dark:
        return 'Tema oscuro';
      case ThemeMode.system:
        return 'Seguir sistema';
    }
  }

  static String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d/$m/${local.year} $h:$min';
  }

  Future<void> _exportAll(BuildContext context, WidgetRef ref) async {
    final path =
        await ref.read(diaryViewModelProvider.notifier).exportAllEntries();
    if (!context.mounted) return;
    if (path == null) {
      final error = ref.read(diaryViewModelProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'No se pudo exportar'),
          backgroundColor: FluentColors.error,
        ),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: path));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exportado. Ruta copiada:\n$path'),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final path = await ref.read(diaryViewModelProvider.notifier).exportBackup();
    if (!context.mounted) return;
    if (path == null) {
      final error = ref.read(diaryViewModelProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'No se pudo crear el respaldo'),
          backgroundColor: FluentColors.error,
        ),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: path));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Respaldo creado. Ruta copiada:\n$path'),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _showChangePasswordDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final formKey = GlobalKey<FormState>();
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    var obscureCurrent = true;
    var obscureNew = true;
    var autovalidate = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Cambiar contraseña'),
              content: Form(
                key: formKey,
                autovalidateMode: autovalidate
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: currentController,
                        obscureText: obscureCurrent,
                        decoration: InputDecoration(
                          labelText: 'Contraseña actual',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureCurrent
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setLocal(
                              () => obscureCurrent = !obscureCurrent,
                            ),
                          ),
                        ),
                        validator: FormValidators.password,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newController,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          labelText: 'Nueva contraseña',
                          helperText: 'Mínimo 6 caracteres, letra y número',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNew
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setLocal(() => obscureNew = !obscureNew),
                          ),
                        ),
                        validator: FormValidators.passwordStrong,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar nueva contraseña',
                        ),
                        validator: (v) => FormValidators.confirmPassword(
                          v,
                          newController.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    setLocal(() => autovalidate = true);
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(ctx, true);
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    final currentPassword = currentController.text;
    final newPassword = newController.text;
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();

    if (result != true || !context.mounted) return;

    final success = await ref.read(authViewModelProvider.notifier).changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );

    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada'),
          backgroundColor: FluentColors.success,
        ),
      );
    } else {
      final error = ref.read(authViewModelProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'No se pudo cambiar la contraseña'),
          backgroundColor: FluentColors.error,
        ),
      );
    }
  }
}

class _StatsGrid extends StatelessWidget {
  final DiaryStats stats;
  final ColorScheme scheme;

  const _StatsGrid({required this.stats, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: [
        _StatTile(label: 'Notas', value: '${stats.totalNotes}', scheme: scheme),
        _StatTile(label: 'Favoritos', value: '${stats.favorites}', scheme: scheme),
        _StatTile(label: 'Fijadas', value: '${stats.pinned}', scheme: scheme),
        _StatTile(label: 'Archivadas', value: '${stats.archived}', scheme: scheme),
        _StatTile(label: 'Papelera', value: '${stats.trash}', scheme: scheme),
        _StatTile(
          label: 'Categorías',
          value: '${stats.categories}',
          scheme: scheme,
        ),
        _StatTile(
          label: 'Tareas hechas',
          value: '${stats.tasksCompleted}',
          scheme: scheme,
        ),
        _StatTile(
          label: 'Tareas vencidas',
          value: '${stats.tasksOverdue}',
          scheme: scheme,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme scheme;

  const _StatTile({
    required this.label,
    required this.value,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(FluentRadius.xl),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
