import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/category_filter.dart';
import '../../domain/models/note_category.dart';
import '../viewmodels/diary_viewmodel.dart';

/// Resultado del diálogo de creación de categoría.
class _CreateCategoryResult {
  final String name;
  final int colorValue;

  const _CreateCategoryResult(this.name, this.colorValue);
}

/// Diálogo para elegir filtro de categoría o asignar categoría a una nota.
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(diaryViewModelProvider.notifier).refreshCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    const dialogBg = Color(0xFFFFF5F0);
    const accent = Color(0xFFB85C38);
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.45;
    final categories = ref.watch(diaryViewModelProvider).categories;
    final notifier = ref.read(diaryViewModelProvider.notifier);

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.filterMode ? 'Seleccionar categoría' : 'Categoría de la nota',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3D2C24),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => _showCreateCategoryDialog(accent, notifier),
                icon: const Icon(Icons.add, color: accent),
                label: const Text(
                  'Crear nueva categoría',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxListHeight),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.filterMode)
                        _CategoryTile(
                          label: 'Todas las categorías',
                          icon: Icons.layers,
                          selected: widget.selectedCategoryId == null,
                          accent: accent,
                          onTap: () => Navigator.pop(context, null),
                        ),
                      _CategoryTile(
                        label: 'Sin categoría',
                        icon: Icons.label_off_outlined,
                        selected: widget.selectedCategoryId ==
                                CategoryFilterTokens.uncategorized ||
                            (!widget.filterMode &&
                                (widget.selectedCategoryId == null ||
                                    widget.selectedCategoryId!.isEmpty)),
                        accent: accent,
                        onTap: () => Navigator.pop(
                          context,
                          widget.filterMode
                              ? CategoryFilterTokens.uncategorized
                              : '',
                        ),
                      ),
                      if (categories.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Aún no tienes categorías.\nCrea una con el botón de arriba.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.brown.shade400,
                            ),
                          ),
                        ),
                      ...categories.map(
                        (category) => _CategoryTile(
                          label: category.name,
                          icon: Icons.label_outline,
                          colorDot: Color(category.colorValue),
                          selected: widget.selectedCategoryId == category.id,
                          accent: accent,
                          onTap: () => Navigator.pop(context, category.id),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, '__close__'),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(color: accent, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateCategoryDialog(
    Color accent,
    DiaryViewModel notifier,
  ) async {
    final result = await showDialog<_CreateCategoryResult>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _CreateCategoryDialog(accent: accent),
    );

    if (result == null) return;

    final created = await notifier.createCategory(result.name, result.colorValue);
    if (!mounted || created == null) return;

    Navigator.pop(context, created.id);
  }
}

/// Diálogo interno con controlador de texto con ciclo de vida correcto.
class _CreateCategoryDialog extends StatefulWidget {
  final Color accent;

  const _CreateCategoryDialog({required this.accent});

  @override
  State<_CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<_CreateCategoryDialog> {
  late final TextEditingController _nameController;
  int _pickedColor = NoteCategoryColors.presets.first;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, _CreateCategoryResult(name, _pickedColor));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFFF5F0),
      title: const Text('Nueva categoría'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej. Trabajo, Personal…',
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: NoteCategoryColors.presets.map((color) {
                final selected = _pickedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _pickedColor = color),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? widget.accent : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: widget.accent),
          onPressed: _submit,
          child: const Text('Crear'),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final Color? colorDot;

  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.colorDot,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? const Color(0xFFFFE8DC) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                if (colorDot != null)
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: colorDot,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  Icon(icon, size: 20, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: const Color(0xFF3D2C24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
