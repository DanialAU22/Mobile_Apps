import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/subject.dart';
import '../models/task.dart';
import '../providers/subject_provider.dart';
import '../providers/task_provider.dart';
import '../utils/helpers.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _title;
  String? _description;
  Subject? _selectedSubject;
  DateTime? _deadline;
  String _priority = 'medium';
  bool _isRecurring = false;
  String? _recurrenceType;
  DateTime? _recurrenceEndDate;

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: _deadline ?? now,
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? now),
    );
    if (time == null) {
      setState(() => _deadline = date);
      return;
    }
    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickRecurrenceEndDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: _deadline ?? now,
      lastDate: DateTime(now.year + 5),
      initialDate: _recurrenceEndDate ?? (_deadline ?? now),
    );
    if (date != null) {
      setState(() => _recurrenceEndDate = date);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState?.save();

    if (_isRecurring && _deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recurring tasks require a deadline.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final task = Task(
      id: generateId(),
      title: _title!.trim(),
      description: _description?.trim(),
      subjectId: _selectedSubject?.id,
      deadline: _deadline,
      priority: _priority,
      isCompleted: false,
      isRecurring: _isRecurring,
      recurrenceType: _isRecurring ? (_recurrenceType ?? 'weekly') : null,
      recurrenceEndDate: _isRecurring ? _recurrenceEndDate : null,
    );

    await context.read<TaskProvider>().addTask(task);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task saved'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<SubjectProvider>().subjects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (v) => _title = v,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onSaved: (v) => _description = v,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Subject>(
                  decoration: const InputDecoration(
                    labelText: 'Subject (optional)',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedSubject,
                  items: [
                    for (final s in subjects)
                      DropdownMenuItem(
                        value: s,
                        child: Text(s.name),
                      ),
                  ],
                  onChanged: (v) => setState(() => _selectedSubject = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDeadline,
                        icon: const Icon(Icons.event),
                        label: Text(
                          _deadline == null
                              ? 'Set deadline'
                              : 'Deadline: ${formatDateTime(_deadline)}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  value: _priority,
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _priority = v);
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Recurring task'),
                  subtitle: Text(
                    _isRecurring ? 'Repeats ${_recurrenceType ?? 'weekly'}' : '',
                  ),
                  value: _isRecurring,
                  onChanged: (v) {
                    setState(() {
                      _isRecurring = v;
                      if (v && _recurrenceType == null) {
                        _recurrenceType = 'weekly';
                      }
                    });
                  },
                ),
                if (_isRecurring) ...[
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Repeat',
                      border: OutlineInputBorder(),
                    ),
                    value: _recurrenceType ?? 'weekly',
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _recurrenceType = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickRecurrenceEndDate,
                    icon: const Icon(Icons.event),
                    label: Text(
                      _recurrenceEndDate == null
                          ? 'Set end date (optional)'
                          : 'Ends: ${formatDate(_recurrenceEndDate)}',
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Save Task'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
