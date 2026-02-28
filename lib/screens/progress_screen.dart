import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../models/subject.dart';
import '../providers/study_session_provider.dart';
import '../providers/subject_provider.dart';
import '../providers/task_provider.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Map<String, int>? _weeklyStudyMinutes;
  String? _mostStudiedSubjectId;
  int _streak = 0;
  int _overdueCount = 0;
  Map<String, int>? _completionTrend;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  Future<void> _loadData() async {
    await context.read<SubjectProvider>().loadSubjects();
    await context.read<TaskProvider>().loadTasks();
    await context.read<StudySessionProvider>().loadSessions();

    final sessionProvider = context.read<StudySessionProvider>();
    final taskProvider = context.read<TaskProvider>();

    final weekly = await sessionProvider.getWeeklyStudyMinutes();
    final mostStudied = await sessionProvider.getMostStudiedSubjectId();
    final streak = await sessionProvider.getProductivityStreak();
    final overdue = await _computeOverdueCount(taskProvider);
    final trend = await _loadCompletionTrend();

    if (mounted) {
      setState(() {
        _weeklyStudyMinutes = weekly;
        _mostStudiedSubjectId = mostStudied;
        _streak = streak;
        _overdueCount = overdue;
        _completionTrend = trend;
      });
    }
  }

  Future<int> _computeOverdueCount(TaskProvider taskProvider) async {
    try {
      return await DatabaseHelper.instance.getOverdueTasksCount();
    } catch (_) {
      return taskProvider.overdueTasks.length;
    }
  }

  Future<Map<String, int>> _loadCompletionTrend() async {
    try {
      return await DatabaseHelper.instance.getCompletionTrendLast30Days();
    } catch (_) {
      return {};
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverallProgress(completionRate, total, completed),
                const SizedBox(height: 24),
                _buildAnalyticsCards(),
                const SizedBox(height: 24),
                _buildWeeklyStudyChart(),
                const SizedBox(height: 24),
                _buildCompletionTrendChart(),
                const SizedBox(height: 24),
                _buildSubjectCompletion(subjects, barGroups),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverallProgress(double rate, int total, int completed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overall Progress',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: rate),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return SizedBox(
              height: 150,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 10,
                      ),
                    ),
                    Text(
                      '${(rate * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Text(
          'Total: $total · Completed: $completed',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildAnalyticsCards() {
    final theme = Theme.of(context);
    final subjects = context.watch<SubjectProvider>().subjects;
    Subject? mostStudied;
    if (_mostStudiedSubjectId != null) {
      try {
        mostStudied =
            subjects.firstWhere((s) => s.id == _mostStudiedSubjectId);
      } catch (_) {}
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _analyticsCard(
          theme,
          icon: Icons.local_fire_department,
          title: 'Streak',
          value: '$_streak days',
          color: Colors.orange,
        ),
        _analyticsCard(
          theme,
          icon: Icons.warning_amber,
          title: 'Overdue',
          value: '$_overdueCount',
          color: Colors.red,
        ),
        _analyticsCard(
          theme,
          icon: Icons.psychology,
          title: 'Most Studied',
          value: mostStudied?.name ?? '—',
          color: theme.colorScheme.primary,
        ),
      ],
    );
  }

  Widget _analyticsCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyStudyChart() {
    final theme = Theme.of(context);
    final weeklyData = _weeklyStudyMinutes ?? {};
    if (weeklyData.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = weeklyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final double maxY = sortedEntries.isEmpty
        ? 60.0
        : (sortedEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2).toDouble().clamp(60.0, double.infinity).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Study Time',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barGroups: List.generate(sortedEntries.length, (i) {
                final e = sortedEntries[i];
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.toDouble(),
                      color: theme.colorScheme.primary,
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                  showingTooltipIndicators: [0],
                );
              }),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toInt()}m',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= sortedEntries.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          sortedEntries[i].key.length >= 10
                              ? sortedEntries[i].key.substring(5, 10)
                              : sortedEntries[i].key,
                          style: const TextStyle(fontSize: 9),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDayLabel(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return iso;
    }
  }

  Widget _buildCompletionTrendChart() {
    final trend = _completionTrend ?? {};
    if (trend.isEmpty) return const SizedBox.shrink();

    final sorted = trend.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final maxY = sorted.isEmpty ? 10.0 : (sorted.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Completion Trend (30 days)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barGroups: List.generate(sorted.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: sorted[i].value.toDouble(),
                      color: Colors.teal,
                      width: 8,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toInt()}',
                      style: const TextStyle(fontSize: 9),
                    ),
                  ),
                ),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectCompletion(
    List<Subject> subjects,
    List<BarChartGroupData> barGroups,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject Completion',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        subjects.isEmpty
            ? _buildEmptyState()
            : SizedBox(
                height: 200,
                child: BarChart(
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
                            if (index < 0 || index >= subjects.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                subjects[index].name.length > 4
                                    ? '${subjects[index].name.substring(0, 4)}…'
                                    : subjects[index].name,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    maxY: 100,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 8),
          Text(
            'Add subjects and tasks to see progress.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
