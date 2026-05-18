import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import '../../viewmodels/diary_viewmodel.dart';
import '../../../domain/models/diary_entry.dart';

class EntryDetailScreen extends ConsumerStatefulWidget {
  final String entryId;

  const EntryDetailScreen({super.key, required this.entryId});

  @override
  ConsumerState<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends ConsumerState<EntryDetailScreen> {
  DiaryEntry? entry;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadEntry();
  }

  Future<void> _loadEntry() async {
    try {
      final diaryRepository = ref.read(diaryViewModelProvider.notifier);
      // Acceder directamente al repositorio para obtener la entrada
      // Por ahora usaremos el estado del viewModel
      final state = ref.read(diaryViewModelProvider);
      final foundEntry = state.entries.firstWhere(
        (e) => e.id == widget.entryId,
        orElse: () => throw Exception('Entrada no encontrada'),
      );
      
      setState(() {
        entry = foundEntry;
        isLoading = false;
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
        appBar: AppBar(
          title: const Text('Cargando...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null || entry == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                error ?? 'Entrada no encontrada',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(entry!.title.isNotEmpty ? entry!.title : 'Sin título'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('${AppRoutes.editEntry}/${entry!.id}'),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fecha
            Row(
              children: [
                Icon(Icons.calendar_today, 
                    size: 16, 
                    color: Theme.of(context).textTheme.bodySmall?.color),
                const SizedBox(width: 8),
                Text(
                  entry!.date,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Título
            if (entry!.title.isNotEmpty) ...[
              Text(
                entry!.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Contenido
            Text(
              entry!.content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Indicadores de multimedia
            if (entry!.audioMarkers.isNotEmpty || entry!.drawStrokes.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Contenido Multimedia',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (entry!.audioMarkers.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.audiotrack, size: 20),
                    const SizedBox(width: 8),
                    Text('${entry!.audioMarkers.length} marcador(es) de audio'),
                  ],
                ),
              if (entry!.drawStrokes.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.draw, size: 20),
                    const SizedBox(width: 8),
                    Text('${entry!.drawStrokes.length} trazo(s) de dibujo'),
                  ],
                ),
              if (entry!.audioFilePath != null)
                Row(
                  children: [
                    const Icon(Icons.mic, size: 20),
                    const SizedBox(width: 8),
                    const Text('Grabación de audio disponible'),
                  ],
                ),
            ],
            
            // Metadata
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Información',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(context, 'ID', entry!.id),
            _buildInfoRow(context, 'Usuario', entry!.userId),
            _buildInfoRow(
              context,
              'Sincronizado',
              entry!.synced ? 'Sí' : 'No',
            ),
            if (entry!.createdAt != null)
              _buildInfoRow(
                context,
                'Creado',
                _formatDateTime(entry!.createdAt!),
              ),
            if (entry!.updatedAt != null)
              _buildInfoRow(
                context,
                'Actualizado',
                _formatDateTime(entry!.updatedAt!),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('${AppRoutes.editEntry}/${entry!.id}'),
        icon: const Icon(Icons.edit),
        label: const Text('Editar'),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
