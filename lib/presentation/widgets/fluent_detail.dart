import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'fluent_colors.dart';
import '../viewmodels/diary_viewmodel.dart';
import '../../domain/models/diary_entry.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/layout_breakpoints.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/diary_entry_display.dart';
import '../../data/repositories/diary_repository.dart';
import '../../services/note_export_service.dart';
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

    final windowCompact = LayoutBreakpoints.isCompact(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () {
            if (windowCompact) {
              context.go(AppRoutes.home);
            } else {
              context.pop();
            }
          },
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
        actions: _buildAppBarActions(
          context,
          isDark,
          textColor,
          isFavorite,
          windowCompact,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final useSideInfo =
              constraints.maxWidth >= LayoutBreakpoints.detailWide;
          final horizontalPad = constraints.maxWidth >= 1200
              ? FluentSpacing.xxl
              : FluentSpacing.lg;
          final bottomPad = FluentSpacing.xxl + 72 + bottomInset;

          if (useSideInfo) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPad,
                      FluentSpacing.lg,
                      FluentSpacing.lg,
                      bottomPad,
                    ),
                    child: _buildMainColumn(
                      isDark,
                      textColor,
                      secondaryTextColor,
                      includeInfo: false,
                    ),
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: isDark
                      ? FluentColors.borderDark
                      : FluentColors.borderLight,
                ),
                SizedBox(
                  width: (constraints.maxWidth * 0.28)
                      .clamp(260.0, 360.0)
                      .toDouble(),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      FluentSpacing.lg,
                      FluentSpacing.lg,
                      horizontalPad,
                      bottomPad,
                    ),
                    child: _buildInfoSection(
                      isDark,
                      textColor,
                      secondaryTextColor,
                    ),
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPad,
              FluentSpacing.lg,
              horizontalPad,
              bottomPad,
            ),
            child: SizedBox(
              width: double.infinity,
              child: _buildMainColumn(
                isDark,
                textColor,
                secondaryTextColor,
                includeInfo: true,
              ),
            ),
          );
        },
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

  Widget _buildMainColumn(
    bool isDark,
    Color textColor,
    Color secondaryTextColor, {
    required bool includeInfo,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMetadata(isDark, secondaryTextColor),
        const SizedBox(height: FluentSpacing.xl),
        if (entry!.title.isNotEmpty) ...[
          Text(
            entry!.title,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: FluentSpacing.lg),
        ],
        _buildContentCard(isDark, textColor),
        if (entry!.tags.isNotEmpty) ...[
          const SizedBox(height: FluentSpacing.lg),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in entry!.tags)
                Chip(
                  label: Text('#$tag'),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],
        if (entry!.tasks.isNotEmpty) ...[
          const SizedBox(height: FluentSpacing.xl),
          Text(
            'Tareas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: FluentSpacing.sm),
          for (final task in entry!.tasks)
            CheckboxListTile(
              value: task.completed,
              onChanged: null,
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                task.title,
                style: TextStyle(
                  decoration:
                      task.completed ? TextDecoration.lineThrough : null,
                  color: textColor,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
        ],
        if (entry!.audioMarkers.isNotEmpty ||
            entry!.drawStrokes.isNotEmpty ||
            entry!.audioFilePath != null ||
            entry!.attachments.isNotEmpty) ...[
          const SizedBox(height: FluentSpacing.xl),
          _buildMultimediaSection(isDark, textColor, secondaryTextColor),
        ],
        if (includeInfo) ...[
          const SizedBox(height: FluentSpacing.xl),
          _buildInfoSection(isDark, textColor, secondaryTextColor),
        ],
      ],
    );
  }

  Widget _buildContentCard(bool isDark, Color textColor) {
    final noteColor = entry!.colorValue != null ? Color(entry!.colorValue!) : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(FluentSpacing.xl),
      decoration: BoxDecoration(
        color: noteColor?.withValues(alpha: isDark ? 0.18 : 0.45) ??
            (isDark
                ? FluentColors.surfaceVariantDark.withValues(alpha: 0.35)
                : FluentColors.surfaceVariantLight.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(FluentRadius.xl),
        border: Border.all(
          color: isDark ? FluentColors.borderDark : FluentColors.borderLight,
        ),
      ),
      child: SelectableText(
        entry!.content.isEmpty ? 'Sin contenido' : entry!.content,
        style: TextStyle(
          fontSize: 16,
          color: entry!.content.isEmpty
              ? (isDark
                  ? FluentColors.textSecondaryDark
                  : FluentColors.textSecondaryLight)
              : textColor,
          height: 1.75,
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
          onSelected: (value) async {
            switch (value) {
              case 'sync':
                _manualSync();
                break;
              case 'edit':
                context.push('${AppRoutes.editEntry}/${entry!.id}');
                break;
              case 'duplicate':
                await _duplicateEntry();
                break;
              case 'pin':
                await ref
                    .read(diaryViewModelProvider.notifier)
                    .togglePin(entry!.id);
                await _loadEntry();
                break;
              case 'archive':
                await ref
                    .read(diaryViewModelProvider.notifier)
                    .archiveEntry(entry!.id, archive: !entry!.isArchived);
                await _loadEntry();
                break;
              case 'export_md':
                await _exportEntry(NoteExportFormat.markdown);
                break;
              case 'export_txt':
                await _exportEntry(NoteExportFormat.txt);
                break;
              case 'export_pdf':
                await _exportEntry(NoteExportFormat.pdf);
                break;
              case 'export_word':
                await _exportEntry(NoteExportFormat.word);
                break;
              case 'share':
                await _shareEntry();
                break;
              case 'print':
                await ref
                    .read(diaryViewModelProvider.notifier)
                    .printEntry(entry!.id);
                break;
              case 'restore':
                await ref
                    .read(diaryViewModelProvider.notifier)
                    .restoreFromTrash(entry!.id);
                if (mounted) context.pop();
                break;
              case 'hard_delete':
                _showHardDeleteDialog();
                break;
              case 'copy':
                await _copyContent();
                break;
              case 'delete':
                _showDeleteDialog();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'sync', child: Text('Sincronizar')),
            const PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(
              value: 'pin',
              child: Text(entry!.isPinned ? 'Quitar fijado' : 'Fijar nota'),
            ),
            PopupMenuItem(
              value: 'archive',
              child: Text(entry!.isArchived ? 'Desarchivar' : 'Archivar'),
            ),
            const PopupMenuItem(value: 'duplicate', child: Text('Duplicar')),
            const PopupMenuItem(value: 'export_md', child: Text('Exportar Markdown')),
            const PopupMenuItem(value: 'export_txt', child: Text('Exportar TXT')),
            const PopupMenuItem(value: 'export_pdf', child: Text('Exportar PDF')),
            const PopupMenuItem(value: 'export_word', child: Text('Exportar Word')),
            const PopupMenuItem(value: 'share', child: Text('Compartir…')),
            const PopupMenuItem(value: 'print', child: Text('Imprimir')),
            const PopupMenuItem(value: 'copy', child: Text('Copiar contenido')),
            if (entry!.isDeleted) ...[
              const PopupMenuItem(value: 'restore', child: Text('Restaurar')),
              const PopupMenuItem(
                value: 'hard_delete',
                child: Text('Eliminar definitivamente',
                    style: TextStyle(color: FluentColors.error)),
              ),
            ] else
              const PopupMenuItem(
                value: 'delete',
                child: Text('Mover a papelera',
                    style: TextStyle(color: FluentColors.error)),
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
          entry!.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
          color: textColor,
        ),
        tooltip: entry!.isPinned ? 'Quitar fijado' : 'Fijar',
        onPressed: () async {
          await ref.read(diaryViewModelProvider.notifier).togglePin(entry!.id);
          await _loadEntry();
        },
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
          color: FluentColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(FluentRadius.md),
          border: Border.all(
            color: FluentColors.error.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: IconButton(
          icon: const Icon(Icons.delete, size: 20, color: FluentColors.error),
          onPressed: entry!.isDeleted ? _showHardDeleteDialog : _showDeleteDialog,
          tooltip: entry!.isDeleted ? 'Eliminar definitivamente' : 'Mover a papelera',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
      ),
      PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: textColor),
        tooltip: 'Más acciones',
        onSelected: (value) async {
          switch (value) {
            case 'duplicate':
              await _duplicateEntry();
              break;
            case 'archive':
              await ref
                  .read(diaryViewModelProvider.notifier)
                  .archiveEntry(entry!.id, archive: !entry!.isArchived);
              await _loadEntry();
              break;
            case 'export_md':
              await _exportEntry(NoteExportFormat.markdown);
              break;
            case 'export_txt':
              await _exportEntry(NoteExportFormat.txt);
              break;
            case 'export_pdf':
              await _exportEntry(NoteExportFormat.pdf);
              break;
            case 'export_word':
              await _exportEntry(NoteExportFormat.word);
              break;
            case 'share':
              await _shareEntry();
              break;
            case 'print':
              await ref
                  .read(diaryViewModelProvider.notifier)
                  .printEntry(entry!.id);
              break;
            case 'restore':
              await ref
                  .read(diaryViewModelProvider.notifier)
                  .restoreFromTrash(entry!.id);
              if (mounted) context.pop();
              break;
            case 'copy':
              await _copyContent();
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'duplicate', child: Text('Duplicar')),
          PopupMenuItem(
            value: 'archive',
            child: Text(entry!.isArchived ? 'Desarchivar' : 'Archivar'),
          ),
          const PopupMenuItem(value: 'export_md', child: Text('Exportar Markdown')),
          const PopupMenuItem(value: 'export_txt', child: Text('Exportar TXT')),
          const PopupMenuItem(value: 'export_pdf', child: Text('Exportar PDF')),
          const PopupMenuItem(value: 'export_word', child: Text('Exportar Word')),
          const PopupMenuItem(value: 'share', child: Text('Compartir…')),
          const PopupMenuItem(value: 'print', child: Text('Imprimir')),
          const PopupMenuItem(value: 'copy', child: Text('Copiar contenido')),
          if (entry!.isDeleted)
            const PopupMenuItem(value: 'restore', child: Text('Restaurar')),
        ],
      ),
    ];
  }

  Widget _buildMetadata(bool isDark, Color secondaryTextColor) {
    return Wrap(
      spacing: FluentSpacing.sm,
      runSpacing: FluentSpacing.sm,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: FluentSpacing.md,
            vertical: FluentSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? FluentColors.surfaceVariantDark
                : FluentColors.surfaceVariantLight,
            borderRadius: BorderRadius.circular(FluentRadius.lg),
            border: Border.all(
              color: isDark ? FluentColors.borderDark : FluentColors.borderLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, size: 16, color: secondaryTextColor),
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
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: FluentSpacing.md,
            vertical: FluentSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: entry!.synced
                ? FluentColors.success.withValues(alpha: 0.1)
                : FluentColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(FluentRadius.lg),
            border: Border.all(
              color: entry!.synced
                  ? FluentColors.success.withValues(alpha: 0.3)
                  : FluentColors.warning.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                entry!.synced ? Icons.cloud_done : Icons.cloud_upload,
                size: 16,
                color:
                    entry!.synced ? FluentColors.success : FluentColors.warning,
              ),
              const SizedBox(width: FluentSpacing.xs),
              Text(
                entry!.synced ? 'Sincronizado' : 'Pendiente',
                style: TextStyle(
                  fontSize: 13,
                  color: entry!.synced
                      ? FluentColors.success
                      : FluentColors.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (entry!.isPinned)
          Chip(
            avatar: const Icon(Icons.push_pin, size: 14),
            label: const Text('Fijada'),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        if (entry!.reminderAt != null)
          Chip(
            avatar: const Icon(Icons.alarm, size: 14),
            label: Text(
              '${entry!.reminderAt!.day}/${entry!.reminderAt!.month} '
              '${entry!.reminderAt!.hour.toString().padLeft(2, '0')}:'
              '${entry!.reminderAt!.minute.toString().padLeft(2, '0')}',
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

    if (entry!.tags.isNotEmpty) {
      rows.add(
        _buildInfoRow(
          icon: Icons.tag,
          label: 'Etiquetas',
          value: entry!.tags.map((t) => '#$t').join(' '),
          labelColor: secondaryTextColor,
          valueColor: textColor,
        ),
      );
    }

    if (entry!.priority > 0) {
      rows.add(
        _buildInfoRow(
          icon: Icons.flag_outlined,
          label: 'Prioridad',
          value: switch (entry!.priority) {
            1 => 'Baja',
            2 => 'Media',
            3 => 'Alta',
            _ => '${entry!.priority}',
          },
          labelColor: secondaryTextColor,
          valueColor: textColor,
        ),
      );
    }

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
          width: double.infinity,
          padding: const EdgeInsets.all(FluentSpacing.lg),
          decoration: BoxDecoration(
            color: isDark
                ? FluentColors.surfaceVariantDark.withValues(alpha: 0.35)
                : FluentColors.surfaceVariantLight.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(FluentRadius.xl),
            border: Border.all(
              color: isDark ? FluentColors.borderDark : FluentColors.borderLight,
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

  Future<void> _duplicateEntry() async {
    if (entry == null) return;
    final newId =
        await ref.read(diaryViewModelProvider.notifier).duplicateEntry(entry!.id);
    if (!mounted) return;
    if (newId == null) {
      final error = ref.read(diaryViewModelProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'No se pudo duplicar'),
          backgroundColor: FluentColors.error,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nota duplicada')),
    );
    context.push('${AppRoutes.entryDetail}/$newId');
  }

  Future<void> _exportEntry([NoteExportFormat format = NoteExportFormat.markdown]) async {
    if (entry == null) return;
    final path = await ref
        .read(diaryViewModelProvider.notifier)
        .exportEntry(entry!.id, format: format);
    if (!mounted) return;
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exportado. Ruta copiada:\n$path'),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _shareEntry() async {
    if (entry == null) return;

    final format = await showDialog<NoteExportFormat>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Compartir en formato'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, NoteExportFormat.markdown),
            child: const Text('Markdown (.md)'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, NoteExportFormat.txt),
            child: const Text('Texto (.txt)'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, NoteExportFormat.pdf),
            child: const Text('PDF (.pdf)'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, NoteExportFormat.word),
            child: const Text('Word (.doc)'),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
          ),
        ],
      ),
    );
    if (format == null || !mounted) return;

    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;

    final ok = await ref.read(diaryViewModelProvider.notifier).shareEntry(
          entry!.id,
          format: format,
          sharePositionOrigin: origin,
        );
    if (!mounted) return;
    if (!ok) {
      final error = ref.read(diaryViewModelProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'No se pudo compartir'),
          backgroundColor: FluentColors.error,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Listo para compartir')),
    );
  }

  Future<void> _copyContent() async {
    if (entry == null) return;
    final text = '${entry!.title}\n\n${entry!.content}'.trim();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contenido copiado al portapapeles')),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mover a papelera'),
        content: const Text(
          'La nota se moverá a la papelera. Podrás restaurarla después.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(diaryViewModelProvider.notifier)
                  .moveToTrash(entry!.id);
              if (mounted) {
                context.pop();
              }
            },
            child: const Text(
              'Mover a papelera',
              style: TextStyle(color: FluentColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showHardDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar definitivamente'),
        content: const Text(
          'Esta acción no se puede deshacer. La nota se borrará por completo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(diaryViewModelProvider.notifier)
                  .permanentlyDelete(entry!.id);
              if (mounted) {
                context.pop();
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: FluentColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
