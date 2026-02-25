import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/subject_provider.dart';
import '../providers/task_provider.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<SubjectProvider>().loadSubjects();
      await context.read<TaskProvider>().loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subjectProvider = context.watch<SubjectProvider>();
    final taskProvider = context.watch<TaskProvider>();

    final total = taskProvider.totalTasks;
    final completed = taskProvider.completedTasks;
    final completionRate = taskProvider.completionRate;

    final subjects = subjectProvider.subjects;
    final subjectTasks = {
      for (final s in subjects) s.id: <bool>[],
    };

    for (final task in taskProvider.allTasks) {
      if (task.subjectId == null) continue;
      subjectTasks[task.subjectId!]?.add(task.isCompleted);
    }

    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < subjects.length; i++) {
      final s = subjects[i];
      final stats = subjectTasks[s.id] ?? [];
      final totalPerSubj = stats.length;
      final completedPerSubj = stats.where((c) => c).length;
      final rate = totalPerSubj == 0 ? 0.0 : completedPerSubj / totalPerSubj;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: (rate * 100).clamp(0, 100),
              color: s.color,
              width: 18,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Overall Progress',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: completionRate,
                          strokeWidth: 10,
                        ),
                      ),
                      Text(
                        '${(completionRate * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Total tasks: $total, Completed: $completed',
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Subject Completion',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: subjects.isEmpty
                    ? const Center(
                        child: Text('Add subjects and tasks to see progress.'),
                      )
                    : BarChart(
                        BarChartData(
                          barGroups: barGroups,
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                interval: 25,
                                getTitlesWidget: (value, meta) => Text(
                                  '${value.toInt()}%',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 ||
                                      index >= subjects.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      subjects[index]
                                          .name
                                          .characters
                                          .take(3)
                                          .toString()
                                          .toUpperCase(),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          maxY: 100,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

