import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/exam_provider.dart';
import '../providers/study_session_provider.dart';
import '../providers/subject_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/exam_tile.dart';
import '../widgets/task_tile.dart';
import 'add_exam_screen.dart';
import 'add_task_screen.dart';
import 'calendar_screen.dart';
import 'progress_screen.dart';
import 'study_timer_screen.dart';
import 'settings_screen.dart';
import 'subjects_screen.dart';
import 'tasks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _studyStreak = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  Future<void> _loadData() async {
    final subjectProvider = context.read<SubjectProvider>();
    final taskProvider = context.read<TaskProvider>();
    final examProvider = context.read<ExamProvider>();
    final studySessionProvider = context.read<StudySessionProvider>();

    await subjectProvider.loadSubjects();
    await taskProvider.loadTasks();
    await examProvider.loadExams();
    final streak = await studySessionProvider.getProductivityStreak();
    if (mounted) setState(() => _studyStreak = streak);
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

  String _motivationalMessage(double completionRate) {
    if (completionRate < 0.5) return "Let's focus today!";
    if (completionRate < 0.8) return "You're making progress!";
    return "Great discipline!";
  }

  Widget _buildTodayTab() {
    final taskProvider = context.watch<TaskProvider>();
    final examProvider = context.watch<ExamProvider>();
    final subjects = context.watch<SubjectProvider>().subjects;
    final completionRate = taskProvider.completionRate;
    final tasksToday = taskProvider.tasksForDay(DateTime.now());
    final exams7Days = examProvider.examsForNextDays(7);
    final overdueTasks = taskProvider.overdueTasks;
    final highPriorityUpcoming = taskProvider.highPriorityUpcoming;

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
        await _loadData();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_studyStreak > 0)
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_studyStreak day streak!',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          if (_studyStreak > 0) const SizedBox(height: 12),
          Center(
            child: Text(
              _motivationalMessage(completionRate),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          if (overdueTasks.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 4),
                Text(
                  'Overdue Tasks',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.red.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final t in overdueTasks)
              TaskTile(
                task: t,
                subjectName: subjectName(t.subjectId),
                onToggleComplete: (value) async {
                  final next =
                      await context.read<TaskProvider>().toggleCompletion(t);
                  if (!mounted || !next) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Next occurrence scheduled'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                onDelete: () => context.read<TaskProvider>().deleteTask(t),
              ),
            const SizedBox(height: 24),
          ],
          if (highPriorityUpcoming.isNotEmpty) ...[
            Text(
              'High Priority Upcoming',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final t in highPriorityUpcoming.take(5))
              TaskTile(
                task: t,
                subjectName: subjectName(t.subjectId),
                onToggleComplete: (value) async {
                  final next =
                      await context.read<TaskProvider>().toggleCompletion(t);
                  if (!mounted || !next) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Next occurrence scheduled'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                onDelete: () => context.read<TaskProvider>().deleteTask(t),
              ),
            const SizedBox(height: 24),
          ],
          Text(
            "Today's Tasks",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (tasksToday.isEmpty)
            _buildEmptyState('No tasks for today.')
          else
            for (final t in tasksToday)
              TaskTile(
                task: t,
                subjectName: subjectName(t.subjectId),
                onToggleComplete: (value) async {
                  final next =
                      await context.read<TaskProvider>().toggleCompletion(t);
                  if (!mounted || !next) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Next occurrence scheduled'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                onDelete: () => context.read<TaskProvider>().deleteTask(t),
              ),
          const SizedBox(height: 24),
          Text(
            'Upcoming Exams (7 days)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (exams7Days.isEmpty)
            _buildEmptyState('No upcoming exams in the next week.')
          else
            for (final e in exams7Days)
              ExamTile(
                exam: e,
                subjectName: subjectName(e.subjectId),
                onDelete: () => context.read<ExamProvider>().deleteExam(e),
              ),
          const SizedBox(height: 24),
          Text(
            'Overall Progress',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: completionRate),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Center(
                child: SizedBox(
                  height: 120,
                  width: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: value,
                        strokeWidth: 10,
                      ),
                      Text(
                        '${(completionRate * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 24,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.timer),
            tooltip: 'Study Timer',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const StudyTimerScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ),
            ),
          ),
        ],
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
