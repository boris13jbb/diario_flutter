import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'fluent_colors.dart';
import '../viewmodels/diary_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/diary_list_filter.dart';
import '../../core/constants/layout_breakpoints.dart';
import '../../domain/models/diary_entry.dart';
import '../../domain/models/note_category.dart';
import 'category_picker_dialog.dart';

/// Barra lateral principal estilo Microsoft Fluent
class FluentSidebar extends ConsumerStatefulWidget {
  final String? selectedEntryId;
  
  const FluentSidebar({super.key, this.selectedEntryId});

  @override
  ConsumerState<FluentSidebar> createState() => _FluentSidebarState();
}

class _FluentSidebarState extends ConsumerState<FluentSidebar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diaryState = ref.watch(diaryViewModelProvider);
    final diaryNotifier = ref.read(diaryViewModelProvider.notifier);
    final visibleEntries = diaryNotifier.filteredEntries;
    final authState = ref.watch(authViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final sidebarBg = isDark ? FluentColors.sidebarDark : FluentColors.sidebarLight;
    final secondaryTextColor = isDark ? FluentColors.textSecondaryDark : FluentColors.textSecondaryLight;
    final isCompact = LayoutBreakpoints.isCompact(context);
    
    return Container(
      width: isCompact ? double.infinity : 280,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(
          right: BorderSide(
            color: isDark ? FluentColors.borderDark : FluentColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header con título y botón nuevo
          _buildHeader(context, ref, isDark, diaryState),
          
          // Buscador
          _buildSearchBar(context, isDark),
          
          const SizedBox(height: FluentSpacing.sm),
          
          // Filtros rápidos
          _buildQuickFilters(context, ref, diaryState.listFilter, isDark, secondaryTextColor),

          const SizedBox(height: FluentSpacing.xs),

          _buildCategoryFilter(context, ref, diaryState, isDark, secondaryTextColor),
          
          const SizedBox(height: FluentSpacing.sm),
          
          // Lista de entradas
          Expanded(
            child: diaryState.entries.isEmpty
                ? _buildEmptyList(isDark, secondaryTextColor, diaryState)
                : visibleEntries.isEmpty
                    ? _buildEmptyList(isDark, secondaryTextColor, diaryState)
                    : _buildEntryList(
                        context,
                        ref,
                        visibleEntries,
                        isDark,
                        diaryState.favoriteIds,
                        diaryNotifier,
                      ),
          ),
          
          // Footer con info de sync y usuario
          _buildFooter(context, ref, isDark, secondaryTextColor, authState, diaryState),
        ],
      ),
    );
  }

  Future<void> _manualSync(BuildContext context, WidgetRef ref) async {
    await ref.read(diaryViewModelProvider.notifier).syncPendingEntries();
    if (!context.mounted) return;

    final state = ref.read(diaryViewModelProvider);
    final message = state.error ??
        state.syncMessage ??
        'Notas sincronizadas (${state.entries.length})';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: state.error != null ? FluentColors.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    DiaryState diaryState,
  ) {
    return Container(
      padding: const EdgeInsets.all(FluentSpacing.lg),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? FluentColors.borderDark : FluentColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.book_rounded,
            color: FluentColors.primary,
            size: 24,
          ),
          const SizedBox(width: FluentSpacing.sm),
          Expanded(
            child: Text(
              'NotasPro',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? FluentColors.textPrimaryDark : FluentColors.textPrimaryLight,
              ),
            ),
          ),
          IconButton(
            icon: diaryState.isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: FluentColors.primary,
                    ),
                  )
                : Icon(Icons.sync, color: FluentColors.primary, size: 22),
            tooltip: 'Sincronizar notas',
            onPressed: diaryState.isSyncing ? null : () => _manualSync(context, ref),
          ),
          const SizedBox(width: 4),
          Container(
            decoration: BoxDecoration(
              color: FluentColors.primary,
              borderRadius: BorderRadius.circular(FluentRadius.md),
              boxShadow: FluentColors.shadow2,
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              onPressed: () => context.push(AppRoutes.createEntry),
              tooltip: 'Nueva entrada',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FluentSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? FluentColors.surfaceVariantDark : FluentColors.surfaceVariantLight,
          borderRadius: BorderRadius.circular(FluentRadius.lg),
          border: Border.all(
            color: isDark ? FluentColors.borderDark : FluentColors.borderLight,
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) =>
              ref.read(diaryViewModelProvider.notifier).setSearchQuery(value),
          decoration: InputDecoration(
            hintText: 'Buscar notas...',
            hintStyle: TextStyle(
              color: isDark ? FluentColors.textSecondaryDark : FluentColors.textSecondaryLight,
              fontSize: 13,
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 18,
              color: isDark ? FluentColors.textSecondaryDark : FluentColors.textSecondaryLight,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: FluentSpacing.md,
              vertical: FluentSpacing.sm,
            ),
          ),
          style: TextStyle(
            color: isDark ? FluentColors.textPrimaryDark : FluentColors.textPrimaryLight,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilters(
    BuildContext context,
    WidgetRef ref,
    DiaryListFilter activeFilter,
    bool isDark,
    Color secondaryTextColor,
  ) {
    final notifier = ref.read(diaryViewModelProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FluentSpacing.lg,
        vertical: FluentSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterChip(
              context,
              DiaryListFilter.all,
              Icons.list,
              isDark,
              secondaryTextColor,
              activeFilter == DiaryListFilter.all,
              () => notifier.setListFilter(DiaryListFilter.all),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildFilterChip(
              context,
              DiaryListFilter.favorites,
              Icons.star_border,
              isDark,
              secondaryTextColor,
              activeFilter == DiaryListFilter.favorites,
              () => notifier.setListFilter(DiaryListFilter.favorites),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildFilterChip(
              context,
              DiaryListFilter.recent,
              Icons.access_time,
              isDark,
              secondaryTextColor,
              activeFilter == DiaryListFilter.recent,
              () => notifier.setListFilter(DiaryListFilter.recent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(
    BuildContext context,
    WidgetRef ref,
    DiaryState diaryState,
    bool isDark,
    Color secondaryTextColor,
  ) {
    final notifier = ref.read(diaryViewModelProvider.notifier);
    final isActive = notifier.hasActiveCategoryFilter;
    final label = notifier.categoryFilterLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FluentSpacing.lg),
      child: GestureDetector(
        onTap: () async {
          final result = await CategoryPickerDialog.show(
            context: context,
            ref: ref,
            selectedCategoryId: diaryState.categoryFilterKey,
            filterMode: true,
          );
          if (!context.mounted || result == '__close__') return;
          notifier.setCategoryFilter(result);
        },
        onLongPress: isActive
            ? () => notifier.setCategoryFilter(null)
            : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFFFE8DC)
                : (isDark
                    ? FluentColors.surfaceVariantDark
                    : FluentColors.surfaceVariantLight),
            borderRadius: BorderRadius.circular(FluentRadius.lg),
            border: Border.all(
              color: isActive
                  ? const Color(0xFFE8A87C)
                  : (isDark ? FluentColors.borderDark : FluentColors.borderLight),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.label_outline,
                size: 18,
                color: isActive ? const Color(0xFFB85C38) : secondaryTextColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? const Color(0xFF3D2C24)
                        : secondaryTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.expand_more,
                size: 18,
                color: secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    DiaryListFilter filter,
    IconData icon,
    bool isDark,
    Color secondaryTextColor,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final label = filter.label;
    final bgColor = isSelected
        ? (isDark ? FluentColors.sidebarItemSelectedDark : FluentColors.sidebarItemSelectedLight)
        : Colors.transparent;
    
    final textColor = isSelected
        ? (isDark ? Colors.white : FluentColors.primary)
        : secondaryTextColor;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(FluentRadius.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryList(
    BuildContext context,
    WidgetRef ref,
    List<DiaryEntry> entries,
    bool isDark,
    Set<String> favoriteIds,
    DiaryViewModel diaryNotifier,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: FluentSpacing.sm,
        vertical: FluentSpacing.xs,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isSelected = entry.id == widget.selectedEntryId;
        
        return _SidebarEntryTile(
          entry: entry,
          category: diaryNotifier.categoryForEntry(entry),
          isSelected: isSelected,
          isDark: isDark,
          isFavorite: favoriteIds.contains(entry.id),
          onTap: () => context.push('${AppRoutes.entryDetail}/${entry.id}'),
          onToggleFavorite: () => diaryNotifier.toggleFavorite(entry.id),
        );
      },
    );
  }

  Widget _buildEmptyList(
    bool isDark,
    Color secondaryTextColor,
    DiaryState diaryState,
  ) {
    final IconData icon;
    final String title;
    final String subtitle;

    if (diaryState.categoryFilterKey != null) {
      icon = Icons.label_off_outlined;
      title = 'Sin notas en esta categoría';
      subtitle = 'Cambia el filtro o asigna esta categoría al editar una nota';
    } else {
      switch (diaryState.listFilter) {
        case DiaryListFilter.favorites:
          icon = Icons.star_border;
          title = 'Sin favoritos';
          subtitle =
              'Abre una nota y pulsa la estrella, o mantén pulsada una nota en la lista';
          break;
        case DiaryListFilter.recent:
          icon = Icons.access_time;
          title = 'Sin notas recientes';
          subtitle = 'No hay notas editadas en los últimos $kRecentNotesDays días';
          break;
        case DiaryListFilter.all:
          icon = Icons.note_add;
          title = 'No hay notas aún';
          subtitle =
              'Pulsa ⟳ para sincronizar. Usa el mismo email con el que migraste desde Supabase.';
          break;
      }
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FluentSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: secondaryTextColor.withOpacity(0.5),
            ),
            const SizedBox(height: FluentSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: FluentSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: secondaryTextColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    Color secondaryTextColor,
    dynamic authState,
    DiaryState diaryState,
  ) {
    return Container(
      padding: const EdgeInsets.all(FluentSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? FluentColors.borderDark : FluentColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: diaryState.isSyncing
                ? null
                : () => _manualSync(context, ref),
            borderRadius: BorderRadius.circular(FluentRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
          if (diaryState.isSyncing)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: FluentColors.primary,
                  ),
                )
              else
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: diaryState.lastSyncedAt != null
                        ? FluentColors.success
                        : secondaryTextColor,
                  ),
                ),
              const SizedBox(width: 6),
              Text(
                diaryState.isSyncing
                    ? 'Sincronizando...'
                    : diaryState.lastSyncedAt != null
                        ? 'Sincronizado · Toca para actualizar'
                        : 'Toca para sincronizar',
                style: TextStyle(
                  fontSize: 11,
                  color: secondaryTextColor,
                ),
              ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Avatar del usuario
          GestureDetector(
            onTap: () => context.push(AppRoutes.profile),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: FluentColors.primary,
              child: Text(
                _getUserInitials(authState.userId),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getUserInitials(String? userId) {
    if (userId == null || userId.isEmpty) return 'U';
    // Usar las primeras 2 caracteres del userId
    if (userId.length >= 2) {
      return userId.substring(0, 2).toUpperCase();
    }
    return userId.toUpperCase();
  }
}

/// Ítem de nota en la barra lateral (hover estable con State propio).
class _SidebarEntryTile extends StatefulWidget {
  final DiaryEntry entry;
  final NoteCategory? category;
  final bool isSelected;
  final bool isDark;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _SidebarEntryTile({
    required this.entry,
    this.category,
    required this.isSelected,
    required this.isDark,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  State<_SidebarEntryTile> createState() => _SidebarEntryTileState();
}

class _SidebarEntryTileState extends State<_SidebarEntryTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? (widget.isDark
            ? FluentColors.sidebarItemSelectedDark
            : FluentColors.sidebarItemSelectedLight)
        : Colors.transparent;

    final hoverBgColor = widget.isDark
        ? FluentColors.sidebarItemHoverDark
        : FluentColors.sidebarItemHoverLight;
    final textColor = widget.isDark
        ? FluentColors.textPrimaryDark
        : FluentColors.textPrimaryLight;
    final secondaryTextColor = widget.isDark
        ? FluentColors.textSecondaryDark
        : FluentColors.textSecondaryLight;

    final preview = widget.entry.content.isNotEmpty
        ? (widget.entry.content.length > 60
            ? widget.entry.content.substring(0, 60)
            : widget.entry.content)
        : 'Sin contenido';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onToggleFavorite,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.all(FluentSpacing.md),
          decoration: BoxDecoration(
            color: _isHovered ? hoverBgColor : bgColor,
            borderRadius: BorderRadius.circular(FluentRadius.lg),
            border: widget.isSelected
                ? Border.all(
                    color: widget.isDark
                        ? FluentColors.primaryLight
                        : FluentColors.primary,
                    width: 1.5,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.entry.title.isNotEmpty
                          ? widget.entry.title
                          : 'Sin título',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isFavorite)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.star,
                        size: 14,
                        color: FluentColors.warning,
                      ),
                    ),
                  if (widget.entry.synced)
                    const Icon(
                      Icons.cloud_done,
                      size: 14,
                      color: FluentColors.success,
                    )
                  else
                    const Icon(
                      Icons.cloud_upload,
                      size: 14,
                      color: FluentColors.warning,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                preview,
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryTextColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.category != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(widget.category!.colorValue).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(FluentRadius.sm),
                  ),
                  child: Text(
                    widget.category!.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(widget.category!.colorValue),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: secondaryTextColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.entry.date,
                    style: TextStyle(
                      fontSize: 11,
                      color: secondaryTextColor,
                    ),
                  ),
                  const Spacer(),
                  if (widget.entry.audioMarkers.isNotEmpty ||
                      widget.entry.drawStrokes.isNotEmpty)
                    Icon(
                      Icons.attach_file,
                      size: 12,
                      color: secondaryTextColor,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
