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

  factory NoteCategory.fromJson(Map<String, dynamic> json) {
    return NoteCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: (json['color'] as num?)?.toInt() ?? 0xFFE8A87C,
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

/// Colores sugeridos al crear una categoría.
class NoteCategoryColors {
  NoteCategoryColors._();

  static const presets = <int>[
    0xFFE8A87C,
    0xFFD4A574,
    0xFF85C1E9,
    0xFF82E0AA,
    0xFFF1948A,
    0xFFBB8FCE,
    0xFFF7DC6F,
    0xFF76D7C4,
  ];
}
