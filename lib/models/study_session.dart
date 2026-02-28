class StudySession {
  final String id;
  final String? subjectId;
  final int durationMinutes;
  final DateTime date;

  const StudySession({
    required this.id,
    this.subjectId,
    required this.durationMinutes,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'duration': durationMinutes,
      'date': date.toIso8601String(),
    };
  }

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      id: map['id'] as String,
      subjectId: map['subjectId'] as String?,
      durationMinutes: map['duration'] as int,
      date: DateTime.parse(map['date'] as String),
    );
  }
}
