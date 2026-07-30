import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/form_validators.dart';
import '../../viewmodels/diary_viewmodel.dart';
import '../../widgets/fluent_colors.dart';

/// Pantalla legacy del editor (rutas usan FluentEditorScreen).
/// Se mantiene alineada en validaciones por si se reutiliza.
class EditorScreen extends ConsumerStatefulWidget {
  final bool isEditing;
  final String? entryId;

  const EditorScreen({super.key, required this.isEditing, this.entryId});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  DateTime _selectedDate = DateTime.now();
  bool _autovalidate = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();

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

    try {
      final dateParts = entry.date.split('-');
      if (dateParts.length == 3) {
        _selectedDate = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
        );
      }
    } catch (_) {
      // Conserva la fecha actual si el formato es inválido.
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
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
    setState(() => _autovalidate = true);
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(diaryViewModelProvider.notifier);
    bool success;

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
      );

      success = await notifier.updateEntry(updatedEntry);
    } else {
      final newId = await notifier.createEntry(
        date: _selectedDate.toIso8601String().split('T')[0],
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
      );
      success = newId != null;
    }

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar entrada' : 'Nueva entrada'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Guardar',
            onPressed: _saveEntry,
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidate
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título'),
                style: Theme.of(context).textTheme.titleLarge,
                textCapitalization: TextCapitalization.sentences,
                validator: FormValidators.requiredTitle,
              ),
              const SizedBox(height: FluentSpacing.lg),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(_selectedDate.toString().split(' ')[0]),
                subtitle: const Text('Fecha de la entrada'),
                onTap: _selectDate,
              ),
              const Divider(height: 32),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Contenido',
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                minLines: 10,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
