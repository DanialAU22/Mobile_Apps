import 'package:flutter/material.dart';

import '../models/task.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final String? subjectName;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final ValueChanged<bool?>? onToggleComplete;

  const TaskTile({
    super.key,
    required this.task,
    this.subjectName,
    this.onTap,
    this.onDelete,
    this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final priorityLabel = kPriorityLabels[task.priority] ?? 'None';
    final pColor = priorityColor(task.priority);

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete task?'),
            content: Text('Delete "${task.title}"? This cannot be undone.'),
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
            content: Text('Task "${task.title}" deleted'),
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
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: onToggleComplete,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration:
                task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
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
              task.deadline == null
                  ? 'No deadline'
                  : 'Due ${formatDateTime(task.deadline)}',
            ),
            if (task.isRecurring && task.recurrenceType != null)
              Text(
                'Repeats ${task.recurrenceType}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Chip(
              label: Text(
                priorityLabel,
                style: const TextStyle(fontSize: 11),
              ),
              backgroundColor: pColor.withOpacity(0.15),
              labelStyle: TextStyle(
                color: pColor,
                fontWeight: FontWeight.w600,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

