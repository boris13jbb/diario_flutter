import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/category_filter.dart';
import '../../core/utils/form_validators.dart';
import '../../domain/models/diary_entry.dart';
import '../../domain/models/note_category.dart';
import '../viewmodels/diary_viewmodel.dart';
import 'fluent_colors.dart';

class _CreateCategoryResult {
  final String name;
  final int colorValue;

  const _CreateCategoryResult(this.name, this.colorValue);
}

/// Diálogo para filtrar o asignar categorías, con gestión completa.
class CategoryPickerDialog extends ConsumerStatefulWidget {
  final String? selectedCategoryId;
  final bool filterMode;

  const CategoryPickerDialog({
    super.key,
    this.selectedCategoryId,
    this.filterMode = true,
  });

  static Future<String?> show({
    required BuildContext context,
    required WidgetRef ref,
    String? selectedCategoryId,
    bool filterMode = true,
  }) async {
    final notifier = ref.read(diaryViewModelProvider.notifier);
    await notifier.refreshCategories();
    if (!context.mounted) return null;

    return showDialog<String?>(
      context: context,
      builder: (ctx) => CategoryPickerDialog(
        selectedCategoryId: selectedCategoryId,
        filterMode: filterMode,
      ),
    );
  }

  @override
  ConsumerState<CategoryPickerDialog> createState() =>
      _CategoryPickerDialogState();
}

class _CategoryPickerDialogState extends ConsumerState<CategoryPickerDialog> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await ref.read(diaryViewModelProvider.notifier).refreshCategories();
    if (mounted) setState(() => _loading = false);
  }

  Map<String, int> _noteCounts(List<DiaryEntry> entries) {
    final counts = <String, int>{
      CategoryFilterTokens.uncategorized: 0,
    };
    for (final entry in entries) {
      final id = entry.categoryId;
      if (id == null || id.trim().isEmpty) {
        counts[CategoryFilterTokens.uncategorized] =
            (counts[CategoryFilterTokens.uncategorized] ?? 0) + 1;
      } else {
        counts[id] = (counts[id] ?? 0) + 1;
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final diaryState = ref.watch(diaryViewModelProvider);
    final notifier = ref.read(diaryViewModelProvider.notifier);
    final categories = diaryState.categories;
    final counts = _noteCounts(diaryState.entries);
    final totalNotes = diaryState.entries.length;
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? categories
        : categories
            .where((c) => c.name.toLowerCase().contains(query))
            .toList();
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.5;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FluentRadius.xxl),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 12 + bottomInset * 0.1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.filterMode
                              ? 'Filtrar por categoría'
                              : 'Categoría de la nota',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.filterMode
                              ? 'Elige cómo ver tus notas'
                              : 'Organiza esta nota en una categoría',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Actualizar',
                    onPressed: _loading ? null : _refresh,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.refresh_rounded,
                            color: scheme.onSurfaceVariant,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: FluentSpacing.lg),
              FilledButton.icon(
                onPressed: () => _showCreateCategoryDialog(notifier),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Nueva categoría'),
              ),
              if (categories.length >= 5) ...[
                const SizedBox(height: FluentSpacing.md),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar categoría…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                    isDense: true,
                  ),
                ),
              ],
              const SizedBox(height: FluentSpacing.lg),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxListHeight),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionLabel(label: widget.filterMode ? 'Filtros' : 'Opciones'),
                      const SizedBox(height: FluentSpacing.sm),
                      if (widget.filterMode)
                        _CategoryTile(
                          label: 'Todas las notas',
                          subtitle: '$totalNotes notas',
                          icon: Icons.layers_outlined,
                          selected: widget.selectedCategoryId == null,
                          onTap: () => Navigator.pop(context, null),
                        ),
                      _CategoryTile(
                        label: 'Sin categoría',
                        subtitle:
                            '${counts[CategoryFilterTokens.uncategorized] ?? 0} notas',
                        icon: Icons.inbox_outlined,
                        selected: widget.selectedCategoryId ==
                                CategoryFilterTokens.uncategorized ||
                            (!widget.filterMode &&
                                (widget.selectedCategoryId == null ||
                                    widget.selectedCategoryId!.isEmpty)),
                        onTap: () => Navigator.pop(
                          context,
                          widget.filterMode
                              ? CategoryFilterTokens.uncategorized
                              : '',
                        ),
                      ),
                      const SizedBox(height: FluentSpacing.md),
                      _SectionLabel(
                        label: 'Mis categorías',
                        trailing: categories.isEmpty
                            ? null
                            : '${categories.length}',
                      ),
                      const SizedBox(height: FluentSpacing.sm),
                      if (categories.isEmpty)
                        _EmptyCategoriesCard(
                          onCreate: () => _showCreateCategoryDialog(notifier),
                          onQuickCreate: (name, color) =>
                              _quickCreate(notifier, name, color),
                        )
                      else if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No hay categorías que coincidan con “$_query”.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        )
                      else
                        ...filtered.map(
                          (category) => _CategoryTile(
                            label: category.name,
                            subtitle: '${counts[category.id] ?? 0} notas',
                            icon: Icons.label_outline,
                            colorDot: Color(category.colorValue),
                            selected: widget.selectedCategoryId == category.id,
                            onTap: () => Navigator.pop(context, category.id),
                            onEdit: () =>
                                _showEditCategoryDialog(notifier, category),
                            onDelete: () =>
                                _confirmDeleteCategory(notifier, category),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: FluentSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, '__close__'),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _quickCreate(
    DiaryViewModel notifier,
    String name,
    int color,
  ) async {
    final created = await notifier.createCategory(name, color);
    if (!mounted || created == null) return;
    Navigator.pop(context, created.id);
  }

  Future<void> _showCreateCategoryDialog(DiaryViewModel notifier) async {
    final result = await showDialog<_CreateCategoryResult>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const _CreateCategoryDialog(),
    );

    if (result == null) return;

    final created =
        await notifier.createCategory(result.name, result.colorValue);
    if (!mounted || created == null) {
      final error = ref.read(diaryViewModelProvider).error;
      if (mounted && error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: FluentColors.error,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Categoría “${created.name}” creada'),
        backgroundColor: FluentColors.success,
      ),
    );
    Navigator.pop(context, created.id);
  }

  Future<void> _showEditCategoryDialog(
    DiaryViewModel notifier,
    NoteCategory category,
  ) async {
    final result = await showDialog<_CreateCategoryResult>(
      context: context,
      builder: (ctx) => _CreateCategoryDialog(
        initialName: category.name,
        initialColor: category.colorValue,
        title: 'Editar categoría',
        submitLabel: 'Guardar',
      ),
    );
    if (result == null) return;

    final updated = await notifier.updateCategory(
      category.copyWith(name: result.name, colorValue: result.colorValue),
    );
    if (!mounted) return;
    if (updated == null) {
      final error = ref.read(diaryViewModelProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'No se pudo actualizar'),
          backgroundColor: FluentColors.error,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Categoría actualizada'),
        backgroundColor: FluentColors.success,
      ),
    );
  }

  Future<void> _confirmDeleteCategory(
    DiaryViewModel notifier,
    NoteCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
          '¿Eliminar “${category.name}”?\n\n'
          'Las notas asociadas quedarán sin categoría. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: FluentColors.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await notifier.deleteCategory(category.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Categoría “${category.name}” eliminada'
              : (ref.read(diaryViewModelProvider).error ??
                  'No se pudo eliminar'),
        ),
        backgroundColor: ok ? FluentColors.success : FluentColors.error,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final String? trailing;

  const _SectionLabel({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              trailing!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyCategoriesCard extends StatelessWidget {
  final VoidCallback onCreate;
  final void Function(String name, int color) onQuickCreate;

  const _EmptyCategoriesCard({
    required this.onCreate,
    required this.onQuickCreate,
  });

  static const _suggestions = <(String, int)>[
    ('Trabajo', 0xFF0EA5E9),
    ('Personal', 0xFF22C55E),
    ('Estudio', 0xFF8B5CF6),
    ('Ideas', 0xFFF59E0B),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(FluentSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(FluentRadius.xl),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(Icons.category_outlined, size: 36, color: scheme.primary),
          const SizedBox(height: FluentSpacing.sm),
          Text(
            'Organiza tus notas',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Crea categorías para filtrar y encontrar ideas más rápido.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: FluentSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _suggestions
                .map(
                  (s) => ActionChip(
                    avatar: CircleAvatar(
                      backgroundColor: Color(s.$2),
                      radius: 6,
                    ),
                    label: Text(s.$1),
                    onPressed: () => onQuickCreate(s.$1, s.$2),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: FluentSpacing.sm),
          TextButton(
            onPressed: onCreate,
            child: const Text('Crear con nombre personalizado'),
          ),
        ],
      ),
    );
  }
}

class _CreateCategoryDialog extends StatefulWidget {
  final String? initialName;
  final int? initialColor;
  final String title;
  final String submitLabel;

  const _CreateCategoryDialog({
    this.initialName,
    this.initialColor,
    this.title = 'Nueva categoría',
    this.submitLabel = 'Crear',
  });

  @override
  State<_CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<_CreateCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late int _pickedColor;
  bool _autovalidate = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _pickedColor = widget.initialColor ?? NoteCategoryColors.presets.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _autovalidate = true);
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _CreateCategoryResult(_nameController.text.trim(), _pickedColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        autovalidateMode: _autovalidate
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomInset > 0 ? 8 : 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej. Trabajo, Personal…',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: FormValidators.categoryName,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: FluentSpacing.lg),
              Text(
                'Color',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: FluentSpacing.sm),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: NoteCategoryColors.presets.map((color) {
                  final selected = _pickedColor == color;
                  return InkWell(
                    onTap: () => setState(() => _pickedColor = color),
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Color(color),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? scheme.onSurface
                              : Colors.white.withValues(alpha: 0.8),
                          width: selected ? 3 : 2,
                        ),
                        boxShadow: selected ? FluentColors.shadow2 : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? colorDot;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.colorDot,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.12)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(FluentRadius.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FluentRadius.xl),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected
                        ? scheme.primary.withValues(alpha: 0.18)
                        : scheme.surface,
                    borderRadius: BorderRadius.circular(FluentRadius.lg),
                    border: Border.all(
                      color: selected
                          ? scheme.primary.withValues(alpha: 0.35)
                          : scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: colorDot != null
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: colorDot,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : Icon(
                          icon,
                          size: 18,
                          color: selected
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: scheme.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded,
                      size: 20, color: scheme.primary),
                if (onEdit != null || onDelete != null)
                  PopupMenuButton<String>(
                    tooltip: 'Gestionar',
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                    onSelected: (value) {
                      if (value == 'edit') onEdit?.call();
                      if (value == 'delete') onDelete?.call();
                    },
                    itemBuilder: (context) => [
                      if (onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.edit_outlined, size: 20),
                            title: Text('Editar'),
                          ),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: FluentColors.error,
                            ),
                            title: Text(
                              'Eliminar',
                              style: TextStyle(color: FluentColors.error),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
