import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'fluent_colors.dart';
import '../viewmodels/diary_viewmodel.dart';
import 'category_picker_dialog.dart';

/// Editor mejorado estilo Notion + Fluent
class FluentEditorScreen extends ConsumerStatefulWidget {
  final bool isEditing;
  final String? entryId;

  const FluentEditorScreen({
    super.key,
    required this.isEditing,
    this.entryId,
  });

  @override
  ConsumerState<FluentEditorScreen> createState() => _FluentEditorScreenState();
}

class _FluentEditorScreenState extends ConsumerState<FluentEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.entryId != null) {
      _loadEntry();
    }
  }

  void _loadEntry() {
    final diaryState = ref.read(diaryViewModelProvider);
    final entry = diaryState.entries.firstWhere(
      (e) => e.id == widget.entryId,
      orElse: () => throw Exception('Entrada no encontrada'),
    );

    _titleController.text = entry.title;
    _contentController.text = entry.content;
    _selectedCategoryId = entry.categoryId;

    try {
      final dateParts = entry.date.split('-');
      if (dateParts.length == 3) {
        _selectedDate = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
        );
      }
    } catch (e) {
      print('Error al parsear fecha: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String? _normalizeCategoryId(String? id) {
    if (id == null || id.isEmpty) return null;
    return id;
  }

  String _categoryLabel(DiaryState state) {
    final id = _selectedCategoryId;
    if (id == null || id.isEmpty) return 'Sin categoría';
    for (final c in state.categories) {
      if (c.id == id) return c.name;
    }
    return 'Categoría';
  }

  Future<void> _pickCategory() async {
    final result = await CategoryPickerDialog.show(
      context: context,
      ref: ref,
      selectedCategoryId: _selectedCategoryId ?? '',
      filterMode: false,
    );
    if (!mounted || result == null || result == '__close__') return;
    setState(() => _selectedCategoryId = result.isEmpty ? null : result);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveEntry() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El título es requerido'),
          backgroundColor: FluentColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final notifier = ref.read(diaryViewModelProvider.notifier);
    bool success;

    try {
      if (widget.isEditing) {
        final diaryState = ref.read(diaryViewModelProvider);
        final existingEntry = diaryState.entries.firstWhere(
          (e) => e.id == widget.entryId,
          orElse: () => throw Exception('Entrada no encontrada'),
        );

        final updatedEntry = existingEntry.copyWith(
          date: _selectedDate.toIso8601String().split('T')[0],
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          categoryId: _normalizeCategoryId(_selectedCategoryId),
        );

        success = await notifier.updateEntry(updatedEntry);
      } else {
        success = await notifier.createEntry(
          date: _selectedDate.toIso8601String().split('T')[0],
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          categoryId: _normalizeCategoryId(_selectedCategoryId),
        );
      }

      if (success && mounted) {
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar'),
            backgroundColor: FluentColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: FluentColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? FluentColors.surfaceDark : FluentColors.surfaceLight;
    final textColor = isDark ? FluentColors.textPrimaryDark : FluentColors.textPrimaryLight;
    final diaryState = ref.watch(diaryViewModelProvider);

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
          widget.isEditing ? 'Editar entrada' : 'Nueva entrada',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        actions: [
          // Botón guardar
          Container(
            margin: const EdgeInsets.only(right: FluentSpacing.sm),
            decoration: BoxDecoration(
              color: FluentColors.primary,
              borderRadius: BorderRadius.circular(FluentRadius.md),
              boxShadow: FluentColors.shadow2,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.check, color: Colors.white, size: 20),
                    onPressed: _saveEntry,
                    tooltip: 'Guardar (Ctrl+S)',
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Área principal del editor
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(FluentSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fecha
                    _buildDateSelector(context, isDark),

                    const SizedBox(height: FluentSpacing.md),

                    _buildCategorySelector(context, isDark, diaryState),
                    
                    const SizedBox(height: FluentSpacing.lg),
                    
                    // Título estilo Notion
                    _buildTitleField(context, isDark, textColor),
                    
                    const SizedBox(height: FluentSpacing.lg),
                    
                    // Contenido
                    _buildContentField(context, isDark, textColor),
                    
                    const SizedBox(height: FluentSpacing.xl),
                    
                    // Herramientas multimedia
                    _buildMediaTools(context, isDark),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(
    BuildContext context,
    bool isDark,
    DiaryState diaryState,
  ) {
    return GestureDetector(
      onTap: _pickCategory,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: FluentSpacing.md,
          vertical: FluentSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F0),
          borderRadius: BorderRadius.circular(FluentRadius.lg),
          border: Border.all(color: const Color(0xFFE8A87C)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.label_outline, size: 16, color: Color(0xFFB85C38)),
            const SizedBox(width: FluentSpacing.sm),
            Text(
              _categoryLabel(diaryState),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF3D2C24),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 16, color: Color(0xFFB85C38)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: isDark ? FluentColors.textSecondaryDark : FluentColors.textSecondaryLight,
            ),
            const SizedBox(width: FluentSpacing.sm),
            Text(
              '${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? FluentColors.textSecondaryDark : FluentColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField(BuildContext context, bool isDark, Color textColor) {
    return TextField(
      controller: _titleController,
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textColor,
        height: 1.2,
      ),
      decoration: InputDecoration(
        hintText: 'Título de la entrada',
        hintStyle: TextStyle(
          color: (isDark ? FluentColors.textSecondaryDark : FluentColors.textSecondaryLight)
              .withOpacity(0.5),
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      maxLines: null,
    );
  }

  Widget _buildContentField(BuildContext context, bool isDark, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? FluentColors.surfaceVariantDark.withOpacity(0.3) : FluentColors.surfaceVariantLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(FluentRadius.xl),
        border: Border.all(
          color: isDark ? FluentColors.borderDark : FluentColors.borderLight,
          width: 1,
        ),
      ),
      child: TextField(
        controller: _contentController,
        style: TextStyle(
          fontSize: 16,
          color: textColor,
          height: 1.6,
        ),
        decoration: InputDecoration(
          hintText: 'Escribe tu contenido aquí... (Markdown soportado)',
          hintStyle: TextStyle(
            color: (isDark ? FluentColors.textSecondaryDark : FluentColors.textSecondaryLight)
                .withOpacity(0.5),
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(FluentSpacing.lg),
        ),
        maxLines: null,
        minLines: 15,
        keyboardType: TextInputType.multiline,
      ),
    );
  }

  Widget _buildMediaTools(BuildContext context, bool isDark) {
    final secondaryTextColor = isDark ? FluentColors.textSecondaryDark : FluentColors.textSecondaryLight;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Herramientas',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: secondaryTextColor,
          ),
        ),
        const SizedBox(height: FluentSpacing.md),
        Wrap(
          spacing: FluentSpacing.sm,
          runSpacing: FluentSpacing.sm,
          children: [
            _buildMediaButton(
              context,
              Icons.mic,
              'Grabar audio',
              isDark,
              secondaryTextColor,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Función de audio en desarrollo')),
                );
              },
            ),
            _buildMediaButton(
              context,
              Icons.draw,
              'Dibujar',
              isDark,
              secondaryTextColor,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Función de dibujo en desarrollo')),
                );
              },
            ),
            _buildMediaButton(
              context,
              Icons.image,
              'Agregar imagen',
              isDark,
              secondaryTextColor,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Función de imagen en desarrollo')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaButton(
    BuildContext context,
    IconData icon,
    String label,
    bool isDark,
    Color secondaryTextColor,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? FluentColors.textPrimaryDark : FluentColors.textPrimaryLight,
        side: BorderSide(
          color: isDark ? FluentColors.borderDark : FluentColors.borderLight,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: FluentSpacing.md,
          vertical: FluentSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FluentRadius.lg),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }
}
