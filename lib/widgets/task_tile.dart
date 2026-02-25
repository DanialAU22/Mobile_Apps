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
      onDismissed: (_) => onDelete?.call(),
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

