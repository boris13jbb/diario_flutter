/// Tarea / casilla dentro de una nota.
class NoteTask {
  final String id;
  final String title;
  final bool completed;
  final DateTime? dueAt;
  final String? assigneeId;

  const NoteTask({
    required this.id,
    required this.title,
    this.completed = false,
    this.dueAt,
    this.assigneeId,
  });

  NoteTask copyWith({
    String? id,
    String? title,
    bool? completed,
    DateTime? dueAt,
    String? assigneeId,
    bool clearDueAt = false,
    bool clearAssignee = false,
  }) {
    return NoteTask(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
      assigneeId: clearAssignee ? null : (assigneeId ?? this.assigneeId),
    );
  }

  factory NoteTask.fromJson(Map<String, dynamic> json) {
    return NoteTask(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      completed: json['completed'] == true,
      dueAt: json['due_at'] != null
          ? DateTime.tryParse(json['due_at'].toString())
          : null,
      assigneeId: json['assignee_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'completed': completed,
        if (dueAt != null) 'due_at': dueAt!.toUtc().toIso8601String(),
        if (assigneeId != null && assigneeId!.isNotEmpty)
          'assignee_id': assigneeId,
      };
}
