import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/task_provider.dart';
import '../../data/models/task_model.dart';
import 'task_form.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  const TaskTile({super.key, required this.task});

  void _editTask(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => TaskForm(
        initialTask: task,
        onSubmit: (title, desc, due, priority, category) {
          final updated = task.copyWith(
            title: title,
            description: desc,
            dueDate: due,
            priority: priority,
            category: category,
          );
          context.read<TaskProvider>().updateTask(updated);
        },
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    return switch (priority) {
      0 => Colors.green,
      1 => Colors.orange,
      2 => Colors.red,
      _ => Colors.grey,
    };
  }

  IconData _getPriorityIcon(int priority) {
    return switch (priority) {
      0 => Icons.arrow_downward,
      1 => Icons.remove,
      2 => Icons.arrow_upward,
      _ => Icons.remove,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        // Add drag handle icon at the start
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Icon(
              Icons.drag_handle,
              color: Colors.grey[400],
            ),
            const SizedBox(width: 8),
            // Checkbox
            Checkbox(
              value: task.isDone,
              onChanged: (_) => context.read<TaskProvider>().toggleDone(task),
            ),
          ],
        ),
        onTap: () => _editTask(context),
        title: Row(
          children: [
            // Priority indicator
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _getPriorityColor(task.priority),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Priority badge
            Icon(
              _getPriorityIcon(task.priority),
              size: 16,
              color: _getPriorityColor(task.priority),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 4),
              Text(task.description!),
            ],
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                // Category chip
                if (task.category != null)
                  Chip(
                    label: Text(task.category!),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    labelStyle: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                // Due date
                if (task.dueDate != null)
                  Chip(
                    avatar: const Icon(Icons.calendar_today, size: 14),
                    label: Text(task.dueDate!.toLocal().toString().split(' ')[0]),
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    labelStyle: const TextStyle(fontSize: 12),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => context.read<TaskProvider>().deleteTask(task.id, context),
        ),
      ),
    );
  }
}