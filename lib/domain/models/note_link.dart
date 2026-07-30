/// Enlace asociado a una nota.
class NoteLink {
  final String id;
  final String url;
  final String? label;

  const NoteLink({
    required this.id,
    required this.url,
    this.label,
  });

  factory NoteLink.fromJson(Map<String, dynamic> json) {
    return NoteLink(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      label: json['label']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        if (label != null && label!.isNotEmpty) 'label': label,
      };
}
