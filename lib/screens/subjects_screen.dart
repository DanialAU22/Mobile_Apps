import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/subject.dart';
import '../providers/subject_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/subject_card.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<SubjectProvider>().loadSubjects(),
    );
  }

  void _openSubjectForm({Subject? existing}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SubjectFormSheet(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubjectProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openSubjectForm(),
          ),
        ],
      ),
      body: SafeArea(
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.subjects.isEmpty
                ? const Center(child: Text('No subjects yet. Add one!'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: provider.subjects.length,
                    itemBuilder: (ctx, i) {
                      final subject = provider.subjects[i];
                      return SubjectCard(
                        subject: subject,
                        onTap: () => _openSubjectForm(existing: subject),
                        onLongPress: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete subject'),
                              content: const Text(
                                'Delete this subject and its related tasks and exams?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && context.mounted) {
                            await context
                                .read<SubjectProvider>()
                                .deleteSubject(subject.id);
                          }
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class _SubjectFormSheet extends StatefulWidget {
  final Subject? existing;

  const _SubjectFormSheet({this.existing});

  @override
  State<_SubjectFormSheet> createState() => _SubjectFormSheetState();
}

class _SubjectFormSheetState extends State<_SubjectFormSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor =
        widget.existing?.color ?? kSubjectDefaultColors.first;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState?.save();

    final provider = context.read<SubjectProvider>();
    if (widget.existing == null) {
      final subject = Subject(
        id: generateId(),
        name: _name!.trim(),
        colorValue: _selectedColor.value,
      );
      await provider.addSubject(subject);
    } else {
      final updated = widget.existing!.copyWith(
        name: _name?.trim(),
        colorValue: _selectedColor.value,
      );
      await provider.updateSubject(updated);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + bottomInset,
      ),
      child: Form(
        key: _formKey,
        child: Wrap(
          runSpacing: 12,
          children: [
            Text(
              widget.existing == null ? 'Add Subject' : 'Edit Subject',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextFormField(
              initialValue: widget.existing?.name,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              onSaved: (v) => _name = v,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Color',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final c in kSubjectDefaultColors)
                  GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: CircleAvatar(
                      backgroundColor: c,
                      radius: _selectedColor == c ? 18 : 14,
                      child: _selectedColor == c
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _submit,
                child: Text(widget.existing == null ? 'Add' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

