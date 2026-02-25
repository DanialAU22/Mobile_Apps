import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/exam_provider.dart';
import '../providers/subject_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/exam_tile.dart';
import '../widgets/task_tile.dart';
import 'add_exam_screen.dart';
import 'add_task_screen.dart';
import 'calendar_screen.dart';
import 'progress_screen.dart';
import 'subjects_screen.dart';
import 'tasks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<SubjectProvider>().loadSubjects();
      await context.read<TaskProvider>().loadTasks();
      await context.read<ExamProvider>().loadExams();
    });
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  void _openQuickAdd() {
    if (_selectedIndex == 0 || _selectedIndex == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddTaskScreen()),
      );
    } else if (_selectedIndex == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddExamScreen()),
      );
    }
  }

  Widget _buildTodayTab() {
    final tasksToday =
        context.watch<TaskProvider>().tasksForDay(DateTime.now());
    final exams7Days =
        context.watch<ExamProvider>().examsForNextDays(7);
    final subjects = context.watch<SubjectProvider>().subjects;
    final completionRate =
        context.watch<TaskProvider>().completionRate;

    String subjectName(String? id) {
      if (id == null) return 'No subject';
      try {
        final subj = subjects.firstWhere((s) => s.id == id);
        return subj.name;
      } catch (_) {
        return 'No subject';
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<TaskProvider>().loadTasks();
        await context.read<ExamProvider>().loadExams();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Today\'s Tasks',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (tasksToday.isEmpty)
            const Text('No tasks for today.'),
          for (final t in tasksToday)
            TaskTile(
              task: t,
              subjectName: subjectName(t.subjectId),
              onToggleComplete: (value) =>
                  context.read<TaskProvider>().toggleCompletion(t),
              onDelete: () =>
                  context.read<TaskProvider>().deleteTask(t),
            ),
          const SizedBox(height: 24),
          Text(
            'Upcoming Exams (7 days)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (exams7Days.isEmpty)
            const Text('No upcoming exams in the next week.'),
          for (final e in exams7Days)
            ExamTile(
              exam: e,
              subjectName: subjectName(e.subjectId),
              onDelete: () =>
                  context.read<ExamProvider>().deleteExam(e),
            ),
          const SizedBox(height: 24),
          Text(
            'Overall Progress',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              height: 120,
              width: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: completionRate,
                    strokeWidth: 10,
                  ),
                  Text(
                    '${(completionRate * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (_selectedIndex) {
      0 => _buildTodayTab(),
      1 => const SubjectsScreen(),
      2 => const TasksScreen(),
      3 => const CalendarScreen(),
      4 => const ProgressScreen(),
      _ => _buildTodayTab(),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Deadline & Exam Planner'),
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onNavTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book),
            label: 'Subjects',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights),
            label: 'Progress',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openQuickAdd,
        child: const Icon(Icons.add),
      ),
    );
  }
}

