import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../data/models/task_model.dart';

enum TaskFilter { all, active, completed }

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  TaskFilter _filter = TaskFilter.all;
  String _searchQuery = "";

  final Box<Task> _box = Hive.box<Task>('tasksBox');

  // Getter for all tasks (needed for calendar view)
  List<Task> get allTasks => _tasks;

  List<Task> get filteredTasks {
    final filtered = switch (_filter) {
      TaskFilter.all => _tasks,
      TaskFilter.active => _tasks.where((t) => !t.isDone).toList(),
      TaskFilter.completed => _tasks.where((t) => t.isDone).toList(),
    };
    
    // Sort by order
    filtered.sort((a, b) => a.order.compareTo(b.order));
    
    if (_searchQuery.isEmpty) return filtered;
    return filtered
        .where((t) =>
            t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (t.description ?? "")
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  TaskFilter get currentFilter => _filter;

  void addTask(Task task) {
    // Set order to be at the end
    final maxOrder = _tasks.isEmpty ? 0 : _tasks.map((t) => t.order).reduce((a, b) => a > b ? a : b);
    final taskWithOrder = task.copyWith(order: maxOrder + 1);
    
    _tasks.add(taskWithOrder);
    _box.put(taskWithOrder.id, taskWithOrder);
    notifyListeners();
  }

  void updateTask(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      _box.put(task.id, task);
      notifyListeners();
    }
  }

  void toggleDone(Task task) {
    final updatedTask = task.copyWith(isDone: !task.isDone);
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
    }
    _box.put(task.id, updatedTask);
    notifyListeners();
  }

  void deleteTask(String id, BuildContext context) {
    // Find the task before deleting
    final taskToDelete = _tasks.firstWhere((t) => t.id == id);
    
    // Remove from list and Hive
    _tasks.removeWhere((t) => t.id == id);
    _box.delete(id);
    notifyListeners();

    // Show snackbar with undo option
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task "${taskToDelete.title}" deleted'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            // Restore the task
            _tasks.add(taskToDelete);
            _box.put(taskToDelete.id, taskToDelete);
            notifyListeners();
          },
        ),
      ),
    );
  }

  // Reorder tasks when dragged
  void reorderTasks(int oldIndex, int newIndex) {
    final tasks = filteredTasks;
    
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final task = tasks.removeAt(oldIndex);
    tasks.insert(newIndex, task);
    
    // Update order for all affected tasks
    for (int i = 0; i < tasks.length; i++) {
      final updatedTask = tasks[i].copyWith(order: i);
      final globalIndex = _tasks.indexWhere((t) => t.id == updatedTask.id);
      if (globalIndex != -1) {
        _tasks[globalIndex] = updatedTask;
        _box.put(updatedTask.id, updatedTask);
      }
    }
    
    notifyListeners();
  }

  void setFilter(TaskFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void loadTasks() {
    _tasks = _box.values.toList();
    // Sort by order on load
    _tasks.sort((a, b) => a.order.compareTo(b.order));
    notifyListeners();
  }
}