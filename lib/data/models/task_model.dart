import 'package:hive/hive.dart';

part 'task_model.g.dart'; // generated file

// Priority enum
enum TaskPriority {
  low,
  medium,
  high;

  String get label => switch (this) {
    TaskPriority.low => 'Low',
    TaskPriority.medium => 'Medium',
    TaskPriority.high => 'High',
  };
}

@HiveType(typeId: 0)
class Task {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime? dueDate;

  @HiveField(4)
  bool isDone;

  @HiveField(5)
  int priority; // 0=low, 1=medium, 2=high

  @HiveField(6)
  String? category;

  @HiveField(7)
  int order; // For drag and drop ordering

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.isDone = false,
    this.priority = 1, // default to medium
    this.category,
    this.order = 0,
  });

  TaskPriority get priorityEnum => TaskPriority.values[priority];

  Task copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isDone,
    int? priority,
    String? category,
    int? order,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isDone: isDone ?? this.isDone,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      order: order ?? this.order,
    );
  }
}