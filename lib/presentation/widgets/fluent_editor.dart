import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/note_priority.dart';
import '../../core/utils/form_validators.dart';
import '../../domain/models/note_task.dart';
import '../viewmodels/diary_viewmodel.dart';
import 'category_picker_dialog.dart';
import 'fluent_colors.dart';

enum _SaveStatus { idle, dirty, saving, saved, error }

/// Editor de notas con guardado automático, formato Markdown, tareas y metadatos.
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
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  final _uuid = const Uuid();

  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;
  int _priority = NotePriority.none;
  int? _colorValue;
  List<NoteTask> _tasks = [];
  DateTime? _reminderAt;
  bool _previewMarkdown = false;
  bool _autovalidate = false;
  _SaveStatus _saveStatus = _SaveStatus.idle;
  Timer? _debounce;
  String? _workingEntryId;
  bool _loading = false;

  static const _noteColors = <int>[
    0xFFE3F2FD,
    0xFFF3E5F5,
    0xFFE8F5E9,
    0xFFFFF3E0,
    0xFFFFEBEE,
    0xFFE0F7FA,
  ];

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onDirty);
    _contentController.addListener(_onDirty);
    _tagsController.addListener(_onDirty);
    if (widget.isEditing && widget.entryId != null) {
      _workingEntryId = widget.entryId;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadEntry());
    }
  }

  Future<void> _loadEntry() async {
    setState(() => _loading = true);
    final diaryState = ref.read(diaryViewModelProvider);
    try {
      final entry = diaryState.entries.firstWhere(
        (e) => e.id == widget.entryId,
      );
      _titleController.text = entry.title;
      _contentController.text = entry.content;
      _selectedCategoryId = entry.categoryId;
      _priority = entry.priority;
      _colorValue = entry.colorValue;
      _tasks = List.of(entry.tasks);
      _reminderAt = entry.reminderAt;
      _tagsController.text = entry.tags.join(', ');
      try {
        final dateParts = entry.date.split('-');
        if (dateParts.length == 3) {
          _selectedDate = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
          );
        }
      } catch (_) {}
      _saveStatus = _SaveStatus.saved;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cargar la nota')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onDirty() {
    if (_loading) return;
    if (_saveStatus != _SaveStatus.dirty) {
      setState(() => _saveStatus = _SaveStatus.dirty);
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 900), () {
      unawaited(_autoSave());
    });
  }

  List<String> _parseTags() {
    return _tagsController.text
        .split(RegExp(r'[,#\s]+'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<bool> _autoSave({bool closeAfter = false}) async {
    if (!_formKey.currentState!.validate() &&
        _titleController.text.trim().isEmpty) {
      // Permite auto-guardar borradores con título vacío solo si hay contenido.
      if (_contentController.text.trim().isEmpty) return false;
    }

    setState(() => _saveStatus = _SaveStatus.saving);
    final notifier = ref.read(diaryViewModelProvider.notifier);

    try {
      if (widget.isEditing || _workingEntryId != null) {
        final diaryState = ref.read(diaryViewModelProvider);
        final existing = diaryState.entries.firstWhere(
          (e) => e.id == (_workingEntryId ?? widget.entryId),
        );
        final updated = existing.copyWith(
          date: _selectedDate.toIso8601String().split('T')[0],
          title: _titleController.text.trim(),
          content: _contentController.text,
          categoryId: _normalizeCategoryId(_selectedCategoryId),
          priority: _priority,
          colorValue: _colorValue,
          tags: _parseTags(),
          tasks: _tasks,
          reminderAt: _reminderAt,
        );
        final ok = await notifier.updateEntry(updated, quiet: true);
        if (!mounted) return ok;
        setState(
          () => _saveStatus = ok ? _SaveStatus.saved : _SaveStatus.error,
        );
        if (ok && closeAfter) context.pop();
        return ok;
      } else {
        final newId = await notifier.createEntry(
          date: _selectedDate.toIso8601String().split('T')[0],
          title: _titleController.text.trim(),
          content: _contentController.text,
          categoryId: _normalizeCategoryId(_selectedCategoryId),
          priority: _priority,
          colorValue: _colorValue,
          tags: _parseTags(),
          tasks: _tasks,
          reminderAt: _reminderAt,
        );
        if (newId == null || !mounted) {
          setState(() => _saveStatus = _SaveStatus.error);
          return false;
        }
        _workingEntryId = newId;
        setState(() => _saveStatus = _SaveStatus.saved);
        if (closeAfter && mounted) context.pop();
        return true;
      }
    } catch (_) {
      if (mounted) setState(() => _saveStatus = _SaveStatus.error);
      return false;
    }
  }

  Future<void> _saveAndClose() async {
    setState(() => _autovalidate = true);
    if (!_formKey.currentState!.validate()) return;
    await _autoSave(closeAfter: true);
  }

  String? _normalizeCategoryId(String? id) {
    if (id == null || id.isEmpty) return null;
    return id;
  }

  String _categoryLabel(DiaryState state) {
    final id = _selectedCategoryId;
    if (id == null || id.isEmpty) return 'Sin categoría / carpeta';
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
    _onDirty();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _onDirty();
    }
  }

  Future<void> _pickReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderAt ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderAt ?? DateTime.now()),
    );
    if (time == null || !mounted) return;
    setState(() {
      _reminderAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
    _onDirty();
  }

  void _insertMarkdown(String left, [String right = '']) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final selected = text.substring(start, end);
    final next = text.replaceRange(start, end, '$left$selected$right');
    _contentController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(
        offset: start + left.length + selected.length,
      ),
    );
    _onDirty();
  }

  void _addTask() {
    setState(() {
      _tasks = [
        ..._tasks,
        NoteTask(id: _uuid.v4(), title: 'Nueva tarea'),
      ];
    });
    _onDirty();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  String get _statusLabel {
    switch (_saveStatus) {
      case _SaveStatus.dirty:
        return 'Cambios sin guardar';
      case _SaveStatus.saving:
        return 'Guardando…';
      case _SaveStatus.saved:
        return 'Guardado';
      case _SaveStatus.error:
        return 'Error al guardar';
      case _SaveStatus.idle:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? FluentColors.surfaceDark : FluentColors.surfaceLight;
    final textColor =
        isDark ? FluentColors.textPrimaryDark : FluentColors.textPrimaryLight;
    final diaryState = ref.watch(diaryViewModelProvider);

    return PopScope(
      canPop: _saveStatus != _SaveStatus.dirty &&
          _saveStatus != _SaveStatus.saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_saveStatus == _SaveStatus.dirty) {
          await _autoSave();
        }
        if (mounted) context.pop();
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyS, control: true):
              _saveAndClose,
        },
        child: Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () async {
                if (_saveStatus == _SaveStatus.dirty) await _autoSave();
                if (mounted) context.pop();
              },
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEditing || _workingEntryId != null
                      ? 'Editar nota'
                      : 'Nueva nota',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (_statusLabel.isNotEmpty)
                  Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: _saveStatus == _SaveStatus.error
                          ? FluentColors.error
                          : (isDark
                              ? FluentColors.textSecondaryDark
                              : FluentColors.textSecondaryLight),
                    ),
                  ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: _previewMarkdown ? 'Editar' : 'Vista previa Markdown',
                onPressed: () =>
                    setState(() => _previewMarkdown = !_previewMarkdown),
                icon: Icon(
                  _previewMarkdown ? Icons.edit_note : Icons.preview,
                  color: textColor,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: FluentSpacing.sm),
                decoration: BoxDecoration(
                  color: FluentColors.primary,
                  borderRadius: BorderRadius.circular(FluentRadius.md),
                ),
                child: IconButton(
                  icon: const Icon(Icons.check, color: Colors.white, size: 20),
                  onPressed: _saveAndClose,
                  tooltip: 'Guardar (Ctrl+S)',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  autovalidateMode: _autovalidate
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      FluentSpacing.xl,
                      FluentSpacing.lg,
                      FluentSpacing.xl,
                      FluentSpacing.xl +
                          MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _chipButton(
                                icon: Icons.calendar_today,
                                label:
                                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                onTap: _selectDate,
                                isDark: isDark,
                              ),
                              _chipButton(
                                icon: Icons.folder_outlined,
                                label: _categoryLabel(diaryState),
                                onTap: _pickCategory,
                                isDark: isDark,
                              ),
                              _chipButton(
                                icon: Icons.flag_outlined,
                                label: NotePriority.label(_priority),
                                onTap: () {
                                  setState(() {
                                    _priority =
                                        (_priority + 1) % (NotePriority.high + 1);
                                  });
                                  _onDirty();
                                },
                                isDark: isDark,
                              ),
                              _chipButton(
                                icon: Icons.alarm,
                                label: _reminderAt == null
                                    ? 'Recordatorio'
                                    : '${_reminderAt!.day}/${_reminderAt!.month} ${_reminderAt!.hour.toString().padLeft(2, '0')}:${_reminderAt!.minute.toString().padLeft(2, '0')}',
                                onTap: _pickReminder,
                                isDark: isDark,
                              ),
                              if (_reminderAt != null)
                                _chipButton(
                                  icon: Icons.close,
                                  label: 'Quitar aviso',
                                  onTap: () {
                                    setState(() => _reminderAt = null);
                                    _onDirty();
                                  },
                                  isDark: isDark,
                                ),
                            ],
                          ),
                          const SizedBox(height: FluentSpacing.md),
                          Text(
                            'Color de nota',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? FluentColors.textSecondaryDark
                                  : FluentColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final c in _noteColors)
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _colorValue = c);
                                    _onDirty();
                                  },
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Color(c),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _colorValue == c
                                            ? FluentColors.primary
                                            : Colors.black26,
                                        width: _colorValue == c ? 2 : 1,
                                      ),
                                    ),
                                  ),
                                ),
                              GestureDetector(
                                onTap: () {
                                  setState(() => _colorValue = null);
                                  _onDirty();
                                },
                                child: const Icon(Icons.format_color_reset),
                              ),
                            ],
                          ),
                          const SizedBox(height: FluentSpacing.md),
                          TextField(
                            controller: _tagsController,
                            decoration: InputDecoration(
                              labelText: 'Etiquetas (separadas por coma)',
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(FluentRadius.lg),
                              ),
                            ),
                          ),
                          const SizedBox(height: FluentSpacing.lg),
                          TextFormField(
                            controller: _titleController,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Título',
                              border: InputBorder.none,
                            ),
                            validator: FormValidators.requiredTitle,
                          ),
                          const SizedBox(height: FluentSpacing.sm),
                          _buildFormatToolbar(isDark),
                          const SizedBox(height: FluentSpacing.sm),
                          if (_previewMarkdown)
                            Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(minHeight: 280),
                              padding: const EdgeInsets.all(FluentSpacing.lg),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(FluentRadius.xl),
                                border: Border.all(
                                  color: isDark
                                      ? FluentColors.borderDark
                                      : FluentColors.borderLight,
                                ),
                              ),
                              child: MarkdownBody(
                                data: _contentController.text.isEmpty
                                    ? '_Sin contenido_'
                                    : _contentController.text,
                              ),
                            )
                          else
                            TextField(
                              controller: _contentController,
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor,
                                height: 1.6,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Escribe tu nota… Soporta Markdown (**negrita**, *cursiva*, - listas)',
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(FluentRadius.xl),
                                ),
                                contentPadding:
                                    const EdgeInsets.all(FluentSpacing.lg),
                              ),
                              maxLines: null,
                              minLines: 12,
                              keyboardType: TextInputType.multiline,
                            ),
                          const SizedBox(height: FluentSpacing.xl),
                          Row(
                            children: [
                              Text(
                                'Tareas',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: _addTask,
                                icon: const Icon(Icons.add_task),
                                label: const Text('Añadir'),
                              ),
                            ],
                          ),
                          ..._tasks.asMap().entries.map((entry) {
                            final i = entry.key;
                            final task = entry.value;
                            return CheckboxListTile(
                              value: task.completed,
                              onChanged: (v) {
                                setState(() {
                                  _tasks = List.of(_tasks);
                                  _tasks[i] =
                                      task.copyWith(completed: v ?? false);
                                });
                                _onDirty();
                              },
                              title: TextFormField(
                                initialValue: task.title,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Tarea',
                                ),
                                onChanged: (value) {
                                  _tasks = List.of(_tasks);
                                  _tasks[i] = task.copyWith(title: value);
                                  _onDirty();
                                },
                              ),
                              secondary: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () {
                                  setState(() {
                                    _tasks = List.of(_tasks)..removeAt(i);
                                  });
                                  _onDirty();
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFormatToolbar(bool isDark) {
    return Wrap(
      spacing: 4,
      children: [
        IconButton(
          tooltip: 'Negrita',
          onPressed: () => _insertMarkdown('**', '**'),
          icon: const Icon(Icons.format_bold),
        ),
        IconButton(
          tooltip: 'Cursiva',
          onPressed: () => _insertMarkdown('*', '*'),
          icon: const Icon(Icons.format_italic),
        ),
        IconButton(
          tooltip: 'Lista',
          onPressed: () => _insertMarkdown('\n- '),
          icon: const Icon(Icons.format_list_bulleted),
        ),
        IconButton(
          tooltip: 'Casilla',
          onPressed: () => _insertMarkdown('\n- [ ] '),
          icon: const Icon(Icons.check_box_outlined),
        ),
        IconButton(
          tooltip: 'Enlace',
          onPressed: () => _insertMarkdown('[', '](https://)'),
          icon: const Icon(Icons.link),
        ),
      ],
    );
  }

  Widget _chipButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
