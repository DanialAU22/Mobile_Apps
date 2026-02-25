import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exam.dart';
import '../models/subject.dart';
import '../providers/exam_provider.dart';
import '../providers/subject_provider.dart';
import '../utils/helpers.dart';

class AddExamScreen extends StatefulWidget {
  const AddExamScreen({super.key});

  @override
  State<AddExamScreen> createState() => _AddExamScreenState();
}

class _AddExamScreenState extends State<AddExamScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _title;
  String? _location;
  Subject? _selectedSubject;
  DateTime? _dateTime;

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: _dateTime ?? now,
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime ?? now),
    );
    if (time == null) {
      setState(() {
        _dateTime = date;
      });
      return;
    }
    setState(() {
      _dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState?.save();

    final exam = Exam(
      id: generateId(),
      title: _title!.trim(),
      subjectId: _selectedSubject?.id,
      dateTime: _dateTime,
      location: _location?.trim(),
    );

    await context.read<ExamProvider>().addExam(exam);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<SubjectProvider>().subjects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Exam'),
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
                    labelText: 'Location (optional)',
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (v) => _location = v,
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
                OutlinedButton.icon(
                  onPressed: _pickDateTime,
                  icon: const Icon(Icons.event),
                  label: Text(
                    _dateTime == null
                        ? 'Set date & time'
                        : 'On ${formatDateTime(_dateTime)}',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Save Exam'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

