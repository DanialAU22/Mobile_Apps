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
  final _searchController = TextEditingController();
  bool? _filterCompleted;
  bool _filterOverdue = false;
  String? _filterPriority;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<SubjectProvider>().loadSubjects();
      await context.read<TaskProvider>().loadTasks();
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<TaskProvider>().setSearchQuery(
          _searchController.text.trim().isEmpty ? null : _searchController.text,
        );
  }

  void _openAddTask() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddTaskScreen()),
    );
  }

  String subjectNameFor(Task task, List subjects) {
    if (task.subjectId == null) return 'No subject';
    try {
      final subj = subjects.firstWhere((s) => s.id == task.subjectId);
      return subj.name;
    } catch (_) {
      return 'No subject';
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<SubjectProvider>().subjects;
    final taskProvider = context.watch<TaskProvider>();
    final tasks = taskProvider.visibleTasks;
    final hasFilters = _filterCompleted != null ||
        _filterOverdue ||
        _filterPriority != null ||
        (taskProvider.searchQuery != null &&
            taskProvider.searchQuery!.trim().isNotEmpty);

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title or description...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Pending'),
                  selected: _filterCompleted == false,
                  onSelected: (v) {
                    setState(() {
                      _filterCompleted = v ? false : null;
                      context.read<TaskProvider>().setFilters(
                            completed: _filterCompleted,
                            overdue: _filterOverdue,
                            priority: _filterPriority,
                          );
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Completed'),
                  selected: _filterCompleted == true,
                  onSelected: (v) {
                    setState(() {
                      _filterCompleted = v ? true : null;
                      context.read<TaskProvider>().setFilters(
                            completed: _filterCompleted,
                            overdue: _filterOverdue,
                            priority: _filterPriority,
                          );
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Overdue'),
                  selected: _filterOverdue,
                  onSelected: (v) {
                    setState(() {
                      _filterOverdue = v;
                      context.read<TaskProvider>().setFilters(
                            completed: _filterCompleted,
                            overdue: _filterOverdue,
                            priority: _filterPriority,
                          );
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('High'),
                  selected: _filterPriority == 'high',
                  onSelected: (v) {
                    setState(() {
                      _filterPriority = v ? 'high' : null;
                      context.read<TaskProvider>().setFilters(
                            completed: _filterCompleted,
                            overdue: _filterOverdue,
                            priority: _filterPriority,
                          );
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Medium'),
                  selected: _filterPriority == 'medium',
                  onSelected: (v) {
                    setState(() {
                      _filterPriority = v ? 'medium' : null;
                      context.read<TaskProvider>().setFilters(
                            completed: _filterCompleted,
                            overdue: _filterOverdue,
                            priority: _filterPriority,
                          );
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Low'),
                  selected: _filterPriority == 'low',
                  onSelected: (v) {
                    setState(() {
                      _filterPriority = v ? 'low' : null;
                      context.read<TaskProvider>().setFilters(
                            completed: _filterCompleted,
                            overdue: _filterOverdue,
                            priority: _filterPriority,
                          );
                    });
                  },
                ),
                if (hasFilters) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('Clear'),
                    onPressed: () {
                      setState(() {
                        _filterCompleted = null;
                        _filterOverdue = false;
                        _filterPriority = null;
                        _searchController.clear();
                        context.read<TaskProvider>().setSearchQuery(null);
                        context.read<TaskProvider>().setFilters(
                              completed: null,
                              overdue: false,
                              priority: null,
                            );
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: taskProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : tasks.isEmpty
                    ? _buildEmptyState(hasFilters)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: tasks.length,
                        itemBuilder: (ctx, i) {
                          final task = tasks[i];
                          return TaskTile(
                            task: task,
                            subjectName: subjectNameFor(task, subjects),
                            onToggleComplete: (value) {
                              context.read<TaskProvider>()
                                  .toggleCompletion(task).then((next) {
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
                                context.read<TaskProvider>().deleteTask(task),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool hasFilters) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters
                ? 'No tasks match your filters.'
                : 'No tasks. Add one!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (!hasFilters)
            FilledButton.icon(
              onPressed: _openAddTask,
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            ),
        ],
      ),
    );
  }
}
