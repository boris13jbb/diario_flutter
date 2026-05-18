import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/diary_viewmodel.dart';

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
    // Obtener la entrada del estado del ViewModel
    final diaryState = ref.read(diaryViewModelProvider);
    final entry = diaryState.entries.firstWhere(
      (e) => e.id == widget.entryId,
      orElse: () => throw Exception('Entrada no encontrada'),
    );

    // Pre-llenar los campos del formulario con los datos de la entrada
    _titleController.text = entry.title;
    _contentController.text = entry.content;
    
    // Parsear la fecha del formato YYYY-MM-DD
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
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(diaryViewModelProvider.notifier);
    bool success;

    if (widget.isEditing) {
      // Actualizar entrada existente
      final diaryState = ref.read(diaryViewModelProvider);
      final existingEntry = diaryState.entries.firstWhere(
        (e) => e.id == widget.entryId,
        orElse: () => throw Exception('Entrada no encontrada'),
      );

      // Crear una copia actualizada de la entrada
      final updatedEntry = existingEntry.copyWith(
        date: _selectedDate.toIso8601String().split('T')[0],
        title: _titleController.text,
        content: _contentController.text,
      );

      success = await notifier.updateEntry(updatedEntry);
    } else {
      success = await notifier.createEntry(
        date: _selectedDate.toIso8601String().split('T')[0],
        title: _titleController.text,
        content: _contentController.text,
      );
    }

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar Entrada' : 'Nueva Entrada'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveEntry),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título'),
              style: Theme.of(context).textTheme.titleLarge,
              validator: (v) => v?.isEmpty ?? true ? 'El título es requerido' : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(_selectedDate.toString().split(' ')[0]),
              onTap: _selectDate,
            ),
            const Divider(height: 32),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Contenido', alignLabelWithHint: true),
              maxLines: null,
              minLines: 10,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 16),
            // TODO: Agregar botones para audio y dibujo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.mic),
                  label: const Text('Grabar Audio'),
                  onPressed: () {
                    // TODO: Implementar grabación de audio
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Función de audio en desarrollo')),
                    );
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.draw),
                  label: const Text('Dibujar'),
                  onPressed: () {
                    // TODO: Implementar dibujo
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Función de dibujo en desarrollo')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
