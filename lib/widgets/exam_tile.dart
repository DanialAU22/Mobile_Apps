import 'package:flutter/material.dart';

import '../models/exam.dart';
import '../utils/helpers.dart';

class ExamTile extends StatelessWidget {
  final Exam exam;
  final String? subjectName;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ExamTile({
    super.key,
    required this.exam,
    this.subjectName,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(exam.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete exam?'),
            content: Text('Delete "${exam.title}"? This cannot be undone.'),
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
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        return ok ?? false;
      },
      onDismissed: (_) {
        onDelete?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exam "${exam.title}" deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Theme.of(context).colorScheme.error,
        child: Icon(
          Icons.delete,
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.school),
        title: Text(exam.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subjectName != null)
              Text(
                subjectName!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            Text(
              exam.dateTime == null
                  ? 'No date'
                  : formatDateTime(exam.dateTime),
            ),
            if (exam.location != null && exam.location!.isNotEmpty)
              Text('Location: ${exam.location}'),
          ],
        ),
      ),
    );
  }
}

