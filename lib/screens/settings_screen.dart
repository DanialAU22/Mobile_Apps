import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../providers/exam_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/study_session_provider.dart';
import '../providers/subject_provider.dart';
import '../providers/task_provider.dart';
import '../services/export_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<SettingsProvider>().load());
  }

  Future<void> _pickReminderTime() async {
    final settings = context.read<SettingsProvider>();
    final time = await showTimePicker(
      context: context,
      initialTime: settings.reminderTime,
    );
    if (time != null) {
      await settings.setReminderTime(time.hour, time.minute);
      await NotificationService.instance
          .scheduleDailyStudyReminder(hour: time.hour, minute: time.minute);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder time updated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _exportBackup() async {
    try {
      final path = await ExportService.instance.exportToJson();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup saved to:\n$path'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not access file'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Backup'),
        content: const Text(
          'This will merge imported data with existing data. '
          'Duplicate IDs will be replaced.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ExportService.instance.importFromJson(path);
      await context.read<SubjectProvider>().loadSubjects();
      await context.read<TaskProvider>().loadTasks();
      await context.read<ExamProvider>().loadExams();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup imported successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Data'),
        content: const Text(
          'This will permanently delete all subjects, tasks, exams, '
          'and study sessions. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await DatabaseHelper.instance.deleteAllData();
      await context.read<SubjectProvider>().loadSubjects();
      await context.read<TaskProvider>().loadTasks();
      await context.read<ExamProvider>().loadExams();
      await context.read<StudySessionProvider>().loadSessions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data has been reset'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reset failed: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('App theme'),
            subtitle: Text(_themeModeLabel(settings.themeMode)),
            onTap: () => _showThemePicker(settings),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Daily reminder time'),
            subtitle: Text(
              '${settings.reminderHour.toString().padLeft(2, '0')}:'
              '${settings.reminderMinute.toString().padLeft(2, '0')}',
            ),
            onTap: _pickReminderTime,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up),
            title: const Text('Notification sound'),
            subtitle: const Text('Play sound for notifications'),
            value: settings.soundEnabled,
            onChanged: (v) => settings.setSoundEnabled(v),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.save_alt),
            title: const Text('Export backup'),
            subtitle: const Text('Save data to JSON file'),
            onTap: _exportBackup,
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Import backup'),
            subtitle: const Text('Restore from JSON file'),
            onTap: _importBackup,
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
            title: Text(
              'Reset all data',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text('Permanently delete all data'),
            onTap: _resetAllData,
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showThemePicker(SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Light'),
              onTap: () {
                settings.setThemeMode(ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Dark'),
              onTap: () {
                settings.setThemeMode(ThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('System'),
              onTap: () {
                settings.setThemeMode(ThemeMode.system);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
