import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import '../../viewmodels/diary_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diaryState = ref.watch(diaryViewModelProvider);
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Diario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => ref.read(diaryViewModelProvider.notifier).syncPendingEntries(),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      body: diaryState.isLoading && diaryState.entries.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : diaryState.entries.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: diaryState.entries.length,
                  itemBuilder: (context, index) {
                    final entry = diaryState.entries[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => context.push('${AppRoutes.entryDetail}/${entry.id}'),
                        onLongPress: () => _showDeleteDialog(context, ref, entry.id),
                        child: ListTile(
                          title: Text(entry.title.isNotEmpty ? entry.title : 'Sin título',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(entry.content.isNotEmpty 
                                  ? entry.content.substring(0, entry.content.length > 100 ? 100 : entry.content.length)
                                  : 'Sin contenido'),
                              const SizedBox(height: 4),
                              Text(entry.date, style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                          trailing: (entry.audioMarkers.isNotEmpty || entry.drawStrokes.isNotEmpty) 
                              ? const Icon(Icons.attach_file) 
                              : null,
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createEntry),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Entrada'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No hay entradas aún', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Toca el botón + para crear tu primera entrada',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String entryId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Entrada'),
        content: const Text('¿Estás seguro de que deseas eliminar esta entrada?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await ref.read(diaryViewModelProvider.notifier).deleteEntry(entryId);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
