import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../providers/exam_provider.dart';
import '../providers/subject_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/exam_tile.dart';
import '../widgets/task_tile.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<SubjectProvider>().loadSubjects();
      await context.read<TaskProvider>().loadTasks();
      await context.read<ExamProvider>().loadExams();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>().tasksForDay(_selectedDay);
    final exams = context.watch<ExamProvider>().examsForDay(_selectedDay);
    final subjects = context.watch<SubjectProvider>().subjects;

    String subjectName(String? id) {
      if (id == null) return 'No subject';
      try {
        final subj = subjects.firstWhere((s) => s.id == id);
        return subj.name;
      } catch (_) {
        return 'No subject';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  day.year == _selectedDay.year &&
                  day.month == _selectedDay.month &&
                  day.day == _selectedDay.day,
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                ),
              ),
              eventLoader: (day) {
                final t = context.read<TaskProvider>().tasksForDay(day);
                final e = context.read<ExamProvider>().examsForDay(day);
                return [...t, ...e];
              },
            ),
            Expanded(
              child: ListView(
                children: [
                  if (tasks.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        'Tasks',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  for (final t in tasks)
                    TaskTile(
                      task: t,
                      subjectName: subjectName(t.subjectId),
                      onToggleComplete: (value) {
                        context.read<TaskProvider>()
                            .toggleCompletion(t).then((next) {
                          if (mounted && next) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Next occurrence scheduled'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        });
                      },
                      onDelete: () =>
                          context.read<TaskProvider>().deleteTask(t),
                    ),
                  if (exams.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        'Exams',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  for (final e in exams)
                    ExamTile(
                      exam: e,
                      subjectName: subjectName(e.subjectId),
                      onDelete: () =>
                          context.read<ExamProvider>().deleteExam(e),
                    ),
                  if (tasks.isEmpty && exams.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No tasks or exams on this day.'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

