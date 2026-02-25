class Exam {
  final String id;
  final String? subjectId;
  final String title;
  final DateTime? dateTime;
  final String? location;

  const Exam({
    required this.id,
    required this.title,
    this.subjectId,
    this.dateTime,
    this.location,
  });

  Exam copyWith({
    String? id,
    String? subjectId,
    String? title,
    DateTime? dateTime,
    String? location,
  }) {
    return Exam(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'title': title,
      'dateTime': dateTime?.toIso8601String(),
      'location': location,
    };
  }

  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'] as String,
      subjectId: map['subjectId'] as String?,
      title: map['title'] as String,
      dateTime: map['dateTime'] != null
          ? DateTime.tryParse(map['dateTime'] as String)
          : null,
      location: map['location'] as String?,
    );
  }
}

