import 'dart:convert';

/// Categoría personalizada de notas (por usuario).
class NoteCategory {
  final String id;
  final String name;
  final int colorValue;

  const NoteCategory({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  NoteCategory copyWith({
    String? id,
    String? name,
    int? colorValue,
  }) {
    return NoteCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  factory NoteCategory.fromJson(Map<String, dynamic> json) {
    return NoteCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: (json['color'] as num?)?.toInt() ?? 0xFF14B8A6,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': colorValue,
      };

  static List<NoteCategory> listFromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => NoteCategory.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJsonString(List<NoteCategory> categories) {
    return jsonEncode(categories.map((c) => c.toJson()).toList());
  }
}

/// Colores sugeridos al crear/editar una categoría.
class NoteCategoryColors {
  NoteCategoryColors._();

  static const presets = <int>[
    0xFF14B8A6,
    0xFF0EA5E9,
    0xFF6366F1,
    0xFF22C55E,
    0xFFF59E0B,
    0xFFEF4444,
    0xFFEC4899,
    0xFF8B5CF6,
  ];
}
