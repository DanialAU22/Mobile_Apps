import 'package:flutter/material.dart';

const String tableSubjects = 'subjects';
const String tableTasks = 'tasks';
const String tableExams = 'exams';
const String tableStudySessions = 'study_sessions';

const List<Color> kSubjectDefaultColors = <Color>[
  Colors.teal,
  Colors.blue,
  Colors.indigo,
  Colors.deepPurple,
  Colors.orange,
  Colors.pink,
  Colors.green,
];

const Map<String, String> kPriorityLabels = {
  'low': 'Low',
  'medium': 'Medium',
  'high': 'High',
};

Color priorityColor(String? priority) {
  switch (priority) {
    case 'high':
      return Colors.red;
    case 'medium':
      return Colors.orange;
    case 'low':
    default:
      return Colors.blueGrey;
  }
}

