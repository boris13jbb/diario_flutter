import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'fluent_colors.dart';
import '../viewmodels/diary_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../core/constants/app_routes.dart';

/// Barra lateral principal estilo Microsoft Fluent
class FluentSidebar extends ConsumerWidget {
  final String? selectedEntryId;
  
  const FluentSidebar({super.key, this.selectedEntryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diaryState = ref.watch(diaryViewModelProvider);
    final authState = ref.watch(authViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final sidebarBg = isDark ? FluentColors.sidebarDark : FluentColors.sidebarLight;
    final textColor = isDark ? FluentColors.textPrimaryDark : FluentColors.textPrimaryLight;
    final secondaryTextColor = isDark ? FluentColors.textSecondaryDark : FluentColors.textSecondaryLight;
    
    return Container(
      width: 280,
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
          _buildHeader(context, ref, isDark),
          
          // Buscador
          _buildSearchBar(context, isDark),
          
          const SizedBox(height: FluentSpacing.sm),
          
          // Filtros rápidos
          _buildQuickFilters(context, ref, isDark, secondaryTextColor),
          
          const SizedBox(height: FluentSpacing.sm),
          
          // Lista de entradas
          Expanded(
            child: diaryState.entries.isEmpty
                ? _buildEmptyList(isDark, secondaryTextColor)
                : _buildEntryList(context, ref, diaryState.entries, isDark),
          ),
          
          // Footer con info de sync y usuario
          _buildFooter(context, ref, isDark, secondaryTextColor, authState),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isDark) {
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
          // Botón nueva entrada
          Container(
            decoration: BoxDecoration(
              color: FluentColors.primary,
              borderRadius: BorderRadius.circular(FluentRadius.md),
              boxShadow: FluentColors.shadow2,
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              onPressed: () => context.push(AppRoutes.createEntry),
              tooltip: 'Nueva entrada (Ctrl+N)',
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
    bool isDark,
    Color secondaryTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FluentSpacing.lg,
        vertical: FluentSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterChip(context, 'Todas', Icons.list, isDark, secondaryTextColor, true),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildFilterChip(context, 'Favoritos', Icons.star_border, isDark, secondaryTextColor, false),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildFilterChip(context, 'Recientes', Icons.access_time, isDark, secondaryTextColor, false),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    IconData icon,
    bool isDark,
    Color secondaryTextColor,
    bool isSelected,
  ) {
    final bgColor = isSelected
        ? (isDark ? FluentColors.sidebarItemSelectedDark : FluentColors.sidebarItemSelectedLight)
        : Colors.transparent;
    
    final textColor = isSelected
        ? (isDark ? Colors.white : FluentColors.primary)
        : secondaryTextColor;
    
    return GestureDetector(
      onTap: () {
        // TODO: Implementar filtrado
      },
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
    List<dynamic> entries,
    bool isDark,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: FluentSpacing.sm,
        vertical: FluentSpacing.xs,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isSelected = entry.id == selectedEntryId;
        
        return _buildEntryItem(context, ref, entry, isSelected, isDark);
      },
    );
  }

  Widget _buildEntryItem(
    BuildContext context,
    WidgetRef ref,
    dynamic entry,
    bool isSelected,
    bool isDark,
  ) {
    final bgColor = isSelected
        ? (isDark ? FluentColors.sidebarItemSelectedDark : FluentColors.sidebarItemSelectedLight)
        : Colors.transparent;
    
    final hoverBgColor = isDark ? FluentColors.sidebarItemHoverDark : FluentColors.sidebarItemHoverLight;
    final textColor = isDark ? FluentColors.textPrimaryDark : FluentColors.textPrimaryLight;
    final secondaryTextColor = isDark ? FluentColors.textSecondaryDark : FluentColors.textSecondaryLight;
    
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: () {
              context.push('${AppRoutes.entryDetail}/${entry.id}');
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.all(FluentSpacing.md),
              decoration: BoxDecoration(
                color: isHovered ? hoverBgColor : bgColor,
                borderRadius: BorderRadius.circular(FluentRadius.lg),
                border: isSelected
                    ? Border.all(
                        color: isDark ? FluentColors.primaryLight : FluentColors.primary,
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
                          entry.title.isNotEmpty ? entry.title : 'Sin título',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Indicador de sincronización
                      if (entry.synced)
                        Icon(
                          Icons.cloud_done,
                          size: 14,
                          color: FluentColors.success,
                        )
                      else
                        Icon(
                          Icons.cloud_upload,
                          size: 14,
                          color: FluentColors.warning,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.content.isNotEmpty
                        ? entry.content.substring(0, entry.content.length > 60 ? 60 : entry.content.length)
                        : 'Sin contenido',
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                        entry.date,
                        style: TextStyle(
                          fontSize: 11,
                          color: secondaryTextColor,
                        ),
                      ),
                      const Spacer(),
                      // Iconos de multimedia
                      if (entry.audioMarkers.isNotEmpty || entry.drawStrokes.isNotEmpty)
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
      },
    );
  }

  Widget _buildEmptyList(bool isDark, Color secondaryTextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add,
            size: 48,
            color: secondaryTextColor.withOpacity(0.5),
          ),
          const SizedBox(height: FluentSpacing.md),
          Text(
            'No hay notas aún',
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: FluentSpacing.xs),
          Text(
            'Crea tu primera entrada',
            style: TextStyle(
              fontSize: 12,
              color: secondaryTextColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    Color secondaryTextColor,
    dynamic authState,
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
          // Indicador de conexión
          StreamBuilder<bool>(
            stream: _connectionStream(),
            builder: (context, snapshot) {
              final isConnected = snapshot.data ?? false;
              return Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected ? FluentColors.success : FluentColors.error,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isConnected ? 'En línea' : 'Sin conexión',
                    style: TextStyle(
                      fontSize: 11,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              );
            },
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

  Stream<bool> _connectionStream() {
    // TODO: Implementar stream de conexión real
    return Stream.value(true);
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
