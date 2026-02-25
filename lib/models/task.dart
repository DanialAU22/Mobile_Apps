class Task {
  final String id;
  final String? subjectId;
  final String title;
  final String? description;
  final DateTime? deadline;
  final String? priority; // 'low' | 'medium' | 'high'
  final bool isCompleted;

  const Task({
    required this.id,
    required this.title,
    this.subjectId,
    this.description,
    this.deadline,
    this.priority,
    this.isCompleted = false,
  });

  Task copyWith({
    String? id,
    String? subjectId,
    String? title,
    String? description,
    DateTime? deadline,
    String? priority,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'title': title,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'priority': priority,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      subjectId: map['subjectId'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      deadline: map['deadline'] != null
          ? DateTime.tryParse(map['deadline'] as String)
          : null,
      priority: map['priority'] as String?,
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
    );
  }
}

