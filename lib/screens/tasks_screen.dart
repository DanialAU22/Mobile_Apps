import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/subject_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_tile.dart';
import 'add_task_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<SubjectProvider>().loadSubjects();
      await context.read<TaskProvider>().loadTasks();
    });
  }

  void _openAddTask() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddTaskScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<SubjectProvider>().subjects;
    final taskProvider = context.watch<TaskProvider>();

    String subjectNameFor(Task task) {
      if (task.subjectId == null) return 'No subject';
      try {
        final subj =
            subjects.firstWhere((s) => s.id == task.subjectId);
        return subj.name;
      } catch (_) {
        return 'No subject';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          PopupMenuButton<String?>(
            initialValue: taskProvider.filterSubjectId,
            itemBuilder: (ctx) => [
              const PopupMenuItem<String?>(
                value: null,
                child: Text('All subjects'),
              ),
              for (final s in subjects)
                PopupMenuItem<String?>(
                  value: s.id,
                  child: Text(s.name),
                ),
            ],
            onSelected: (value) =>
                context.read<TaskProvider>().setFilterSubject(value),
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openAddTask,
          ),
        ],
      ),
      body: SafeArea(
        child: taskProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : taskProvider.visibleTasks.isEmpty
                ? const Center(child: Text('No tasks. Add one!'))
                : ListView.builder(
                    itemCount: taskProvider.visibleTasks.length,
                    itemBuilder: (ctx, i) {
                      final task = taskProvider.visibleTasks[i];
                      return TaskTile(
                        task: task,
                        subjectName: subjectNameFor(task),
                        onToggleComplete: (value) {
                          context
                              .read<TaskProvider>()
                              .toggleCompletion(task);
                        },
                        onDelete: () =>
                            context.read<TaskProvider>().deleteTask(task),
                      );
                    },
                  ),
      ),
    );
  }
}

