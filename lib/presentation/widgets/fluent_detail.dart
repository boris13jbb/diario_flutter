import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'fluent_colors.dart';
import '../viewmodels/diary_viewmodel.dart';
import '../../domain/models/diary_entry.dart';
import '../../core/constants/app_routes.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/diary_entry_display.dart';
import '../../data/repositories/diary_repository.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Vista de detalle estilo Notion + Fluent
class FluentDetailScreen extends ConsumerStatefulWidget {
  final String entryId;

  const FluentDetailScreen({super.key, required this.entryId});

  @override
  ConsumerState<FluentDetailScreen> createState() => _FluentDetailScreenState();
}

class _FluentDetailScreenState extends ConsumerState<FluentDetailScreen> {
  DiaryEntry? entry;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadEntry();
  }

  Future<void> _manualSync() async {
    await ref.read(diaryViewModelProvider.notifier).syncPendingEntries();
    if (!mounted) return;

    final state = ref.read(diaryViewModelProvider);
    final message = state.error ??
        state.syncMessage ??
        'Notas sincronizadas';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: state.error != null ? FluentColors.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );

    await _loadEntry();
  }

  Future<void> _loadEntry() async {
    try {
      final state = ref.read(diaryViewModelProvider);
      DiaryEntry? foundEntry;
      for (final e in state.entries) {
        if (e.id == widget.entryId) {
          foundEntry = e;
          break;
        }
      }
      foundEntry ??= await getIt<DiaryRepository>().getEntryById(widget.entryId);

      if (foundEntry == null) {
        throw Exception('Entrada no encontrada');
      }

      setState(() {
        entry = foundEntry;
        isLoading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? FluentColors.surfaceDark
            : FluentColors.surfaceLight,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null || entry == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? FluentColors.surfaceDark
            : FluentColors.surfaceLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: FluentColors.error),
              const SizedBox(height: FluentSpacing.lg),
              Text(
                error ?? 'Entrada no encontrada',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? FluentColors.textPrimaryDark
                      : FluentColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: FluentSpacing.lg),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FluentColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FluentRadius.lg),
                  ),
                ),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? FluentColors.surfaceDark : FluentColors.surfaceLight;
    final textColor = isDark ? FluentColors.textPrimaryDark : FluentColors.textPrimaryLight;
    final secondaryTextColor = isDark ? FluentColors.textSecondaryDark : FluentColors.textSecondaryLight;
    final isFavorite =
        ref.watch(diaryViewModelProvider).favoriteIds.contains(entry!.id);

    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          entry!.title.isNotEmpty ? entry!.title : 'Sin título',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        actions: _buildAppBarActions(context, isDark, textColor, isFavorite, isCompact),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          FluentSpacing.lg,
          FluentSpacing.lg,
          FluentSpacing.lg,
          FluentSpacing.xxl + 72 + bottomInset,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Metadata superior
              _buildMetadata(isDark, secondaryTextColor),
              
              const SizedBox(height: FluentSpacing.xxl),
              
              // Título
              if (entry!.title.isNotEmpty) ...[
                Text(
                  entry!.title,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: FluentSpacing.xl),
              ],
              
              // Contenido
              Container(
                padding: const EdgeInsets.all(FluentSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark 
                      ? FluentColors.surfaceVariantDark.withOpacity(0.3)
                      : FluentColors.surfaceVariantLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(FluentRadius.xl),
                  border: Border.all(
                    color: isDark ? FluentColors.borderDark : FluentColors.borderLight,
                    width: 1,
                  ),
                ),
                child: Text(
                  entry!.content,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    height: 1.8,
                  ),
                ),
              ),
              
              const SizedBox(height: FluentSpacing.xxl),
              
              // Multimedia
              if (entry!.audioMarkers.isNotEmpty || entry!.drawStrokes.isNotEmpty || entry!.audioFilePath != null) ...[
                _buildMultimediaSection(isDark, textColor, secondaryTextColor),
                const SizedBox(height: FluentSpacing.xxl),
              ],
              
              // Información adicional
              _buildInfoSection(isDark, textColor, secondaryTextColor),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('${AppRoutes.editEntry}/${entry!.id}'),
          backgroundColor: FluentColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.edit),
          label: const Text('Editar'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FluentRadius.lg),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions(
    BuildContext context,
    bool isDark,
    Color textColor,
    bool isFavorite,
    bool isCompact,
  ) {
    final isSyncing = ref.watch(diaryViewModelProvider).isSyncing;

    if (isCompact) {
      return [
        IconButton(
          icon: isSyncing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.sync, color: textColor),
          tooltip: 'Sincronizar',
          onPressed: isSyncing ? null : _manualSync,
        ),
        IconButton(
          icon: Icon(
            isFavorite ? Icons.star : Icons.star_border,
            color: FluentColors.warning,
          ),
          onPressed: () =>
              ref.read(diaryViewModelProvider.notifier).toggleFavorite(entry!.id),
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: textColor),
          onSelected: (value) {
            switch (value) {
              case 'sync':
                _manualSync();
                break;
              case 'edit':
                context.push('${AppRoutes.editEntry}/${entry!.id}');
                break;
              case 'delete':
                _showDeleteDialog();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'sync', child: Text('Sincronizar')),
            const PopupMenuItem(value: 'edit', child: Text('Editar')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Eliminar', style: TextStyle(color: FluentColors.error)),
            ),
          ],
        ),
      ];
    }

    return [
      IconButton(
        icon: isSyncing
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.sync, color: textColor),
        tooltip: 'Sincronizar',
        onPressed: isSyncing ? null : _manualSync,
      ),
      IconButton(
        icon: Icon(
          isFavorite ? Icons.star : Icons.star_border,
          color: FluentColors.warning,
        ),
        tooltip: isFavorite ? 'Quitar de favoritos' : 'Marcar como favorita',
        onPressed: () =>
            ref.read(diaryViewModelProvider.notifier).toggleFavorite(entry!.id),
      ),
      Container(
        margin: const EdgeInsets.only(right: FluentSpacing.xs),
        decoration: BoxDecoration(
          color: isDark ? FluentColors.surfaceVariantDark : FluentColors.surfaceVariantLight,
          borderRadius: BorderRadius.circular(FluentRadius.md),
          border: Border.all(
            color: isDark ? FluentColors.borderDark : FluentColors.borderLight,
            width: 1,
          ),
        ),
        child: IconButton(
          icon: Icon(Icons.edit, size: 20, color: textColor),
          onPressed: () => context.push('${AppRoutes.editEntry}/${entry!.id}'),
          tooltip: 'Editar',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
      ),
      Container(
        margin: const EdgeInsets.only(right: FluentSpacing.sm),
        decoration: BoxDecoration(
          color: FluentColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(FluentRadius.md),
          border: Border.all(
            color: FluentColors.error.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: IconButton(
          icon: const Icon(Icons.delete, size: 20, color: FluentColors.error),
          onPressed: _showDeleteDialog,
          tooltip: 'Eliminar',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
      ),
    ];
  }

  Widget _buildMetadata(bool isDark, Color secondaryTextColor) {
    return Row(
      children: [
        // Fecha
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: FluentSpacing.md,
            vertical: FluentSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isDark ? FluentColors.surfaceVariantDark : FluentColors.surfaceVariantLight,
            borderRadius: BorderRadius.circular(FluentRadius.lg),
            border: Border.all(
              color: isDark ? FluentColors.borderDark : FluentColors.borderLight,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: secondaryTextColor,
              ),
              const SizedBox(width: FluentSpacing.sm),
              Text(
                entry!.date,
                style: TextStyle(
                  fontSize: 13,
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: FluentSpacing.sm),
        
        // Estado de sincronización
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: FluentSpacing.md,
            vertical: FluentSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: entry!.synced
                ? FluentColors.success.withOpacity(0.1)
                : FluentColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(FluentRadius.lg),
            border: Border.all(
              color: entry!.synced
                  ? FluentColors.success.withOpacity(0.3)
                  : FluentColors.warning.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                entry!.synced ? Icons.cloud_done : Icons.cloud_upload,
                size: 16,
                color: entry!.synced ? FluentColors.success : FluentColors.warning,
              ),
              const SizedBox(width: FluentSpacing.xs),
              Text(
                entry!.synced ? 'Sincronizado' : 'Pendiente',
                style: TextStyle(
                  fontSize: 13,
                  color: entry!.synced ? FluentColors.success : FluentColors.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMultimediaSection(bool isDark, Color textColor, Color secondaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contenido Multimedia',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: FluentSpacing.md),
        if (entry!.audioMarkers.isNotEmpty)
          _buildMultimediaItem(
            Icons.audiotrack,
            '${entry!.audioMarkers.length} marcador(es) de audio',
            isDark,
            secondaryTextColor,
          ),
        if (entry!.drawStrokes.isNotEmpty)
          _buildMultimediaItem(
            Icons.draw,
            '${entry!.drawStrokes.length} trazo(s) de dibujo',
            isDark,
            secondaryTextColor,
          ),
        if (entry!.audioFilePath != null)
          _buildMultimediaItem(
            Icons.mic,
            'Grabación de audio disponible',
            isDark,
            secondaryTextColor,
          ),
      ],
    );
  }

  Widget _buildMultimediaItem(IconData icon, String text, bool isDark, Color secondaryTextColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FluentSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: secondaryTextColor),
          const SizedBox(width: FluentSpacing.sm),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(bool isDark, Color textColor, Color secondaryTextColor) {
    final auth = ref.watch(authViewModelProvider);
    final attachments = DiaryEntryDisplay.attachmentsSummary(entry!);

    final category = ref.read(diaryViewModelProvider.notifier).categoryForEntry(entry!);

    final rows = <Widget>[
      _buildInfoRow(
        icon: Icons.event,
        label: 'Fecha de la nota',
        value: DiaryEntryDisplay.formatEntryDate(entry!.date),
        labelColor: secondaryTextColor,
        valueColor: textColor,
      ),
      if (category != null)
        _buildInfoRow(
          icon: Icons.label_outline,
          label: 'Categoría',
          value: category.name,
          labelColor: secondaryTextColor,
          valueColor: textColor,
        ),
      _buildInfoRow(
        icon: Icons.person_outline,
        label: 'Cuenta',
        value: DiaryEntryDisplay.authorLabel(auth.userEmail),
        labelColor: secondaryTextColor,
        valueColor: textColor,
      ),
      _buildInfoRow(
        icon: entry!.synced ? Icons.cloud_done : Icons.cloud_upload,
        label: 'Copia en la nube',
        value: DiaryEntryDisplay.syncStatusLabel(entry!.synced),
        labelColor: secondaryTextColor,
        valueColor: textColor,
      ),
      _buildInfoRow(
        icon: Icons.notes,
        label: 'Extensión',
        value: DiaryEntryDisplay.textLengthSummary(entry!.content),
        labelColor: secondaryTextColor,
        valueColor: textColor,
      ),
    ];

    if (attachments != null) {
      rows.add(
        _buildInfoRow(
          icon: Icons.attach_file,
          label: 'Adjuntos',
          value: attachments,
          labelColor: secondaryTextColor,
          valueColor: textColor,
        ),
      );
    }

    if (entry!.createdAt != null) {
      rows.add(
        _buildInfoRow(
          icon: Icons.add_circle_outline,
          label: 'Creada',
          value: DiaryEntryDisplay.formatLongDateTime(entry!.createdAt!),
          labelColor: secondaryTextColor,
          valueColor: textColor,
        ),
      );
    }

    if (entry!.updatedAt != null) {
      rows.add(
        _buildInfoRow(
          icon: Icons.edit_calendar,
          label: 'Última edición',
          value: DiaryEntryDisplay.formatLongDateTime(entry!.updatedAt!),
          labelColor: secondaryTextColor,
          valueColor: textColor,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: FluentSpacing.md),
        Container(
          padding: const EdgeInsets.all(FluentSpacing.lg),
          decoration: BoxDecoration(
            color: isDark
                ? FluentColors.surfaceVariantDark.withOpacity(0.3)
                : FluentColors.surfaceVariantLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(FluentRadius.xl),
            border: Border.all(
              color: isDark ? FluentColors.borderDark : FluentColors.borderLight,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 24),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color labelColor,
    required Color valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: labelColor),
        const SizedBox(width: FluentSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Entrada'),
        content: const Text('¿Estás seguro de que deseas eliminar esta entrada? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(diaryViewModelProvider.notifier).deleteEntry(entry!.id);
              if (mounted) {
                context.pop();
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: FluentColors.error)),
          ),
        ],
      ),
    );
  }
}
