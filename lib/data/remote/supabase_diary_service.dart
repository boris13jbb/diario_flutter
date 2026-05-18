import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/diary_entry.dart';

/// Servicio remoto para sincronizar entradas del diario con Supabase
class SupabaseDiaryService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'diary_entries';

  /// Obtiene todas las entradas del usuario actual
  Future<List<DiaryEntry>> getAllEntries(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

      return (response as List)
          .map((json) => DiaryEntry.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener entradas: $e');
    }
  }

  /// Obtiene una entrada específica por ID
  Future<DiaryEntry?> getEntryById(String entryId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', entryId)
          .maybeSingle();

      if (response == null) return null;
      return DiaryEntry.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener entrada: $e');
    }
  }

  /// Crea una nueva entrada en Supabase
  Future<DiaryEntry> createEntry(DiaryEntry entry) async {
    try {
      final response = await _supabase.from(_tableName).insert(entry.toJson()).select().single();
      return DiaryEntry.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear entrada: $e');
    }
  }

  /// Actualiza una entrada existente
  Future<DiaryEntry> updateEntry(DiaryEntry entry) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .update(entry.toJson())
          .eq('id', entry.id)
          .select()
          .single();
      return DiaryEntry.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar entrada: $e');
    }
  }

  /// Elimina una entrada
  Future<void> deleteEntry(String entryId) async {
    try {
      await _supabase.from(_tableName).delete().eq('id', entryId);
    } catch (e) {
      throw Exception('Error al eliminar entrada: $e');
    }
  }

  /// Sincroniza entradas pendientes (synced = false)
  Future<void> syncPendingEntries(List<DiaryEntry> pendingEntries) async {
    for (final entry in pendingEntries) {
      try {
        if (entry.createdAt == null) {
          // Es una entrada nueva
          await createEntry(entry);
        } else {
          // Es una entrada existente que fue modificada
          await updateEntry(entry);
        }
      } catch (e) {
        // Si falla la sincronización, continuamos con la siguiente
        print('Error al sincronizar entrada ${entry.id}: $e');
      }
    }
  }

  /// Obtiene entradas modificadas después de una fecha específica
  Future<List<DiaryEntry>> getEntriesModifiedAfter(
    String userId,
    DateTime lastSync,
  ) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .gt('updated_at', lastSync.toIso8601String())
          .order('date', ascending: false);

      return (response as List)
          .map((json) => DiaryEntry.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener entradas modificadas: $e');
    }
  }
}
