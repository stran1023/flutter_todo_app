import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../logic/providers/task_provider.dart';
import '../widgets/task_tile.dart';
import '../widgets/task_form.dart';
import '../../data/models/task_model.dart';
import 'package:uuid/uuid.dart';
import 'settings_screen.dart';
import 'pomodoro_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Set<String> _expandedCategories = {};
  
  final List<String> _categories = [
    'Work',
    'Personal',
    'Shopping',
    'Health',
    'Learning',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  void _openNewTaskForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => TaskForm(
        onSubmit: (title, desc, dueDate, priority, category) {
          final newTask = Task(
            id: const Uuid().v4(),
            title: title,
            description: desc,
            dueDate: dueDate ?? _selectedDay,
            priority: priority,
            category: category,
          );
          context.read<TaskProvider>().addTask(newTask);
        },
      ),
    );
  }

  List<Task> _getTasksForDay(DateTime day, List<Task> allTasks) {
    return allTasks.where((task) {
      if (task.dueDate == null) return false;
      return isSameDay(task.dueDate, day);
    }).toList();
  }

  Map<String, List<Task>> _groupTasksByCategory(List<Task> tasks) {
    final Map<String, List<Task>> grouped = {};
    
    for (var task in tasks) {
      final category = task.category ?? 'Uncategorized';
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(task);
    }
    
    for (var tasks in grouped.values) {
      tasks.sort((a, b) => a.order.compareTo(b.order));
    }
    
    return grouped;
  }

  Color _getPriorityColor(int priority) {
    return switch (priority) {
      0 => Colors.green,
      1 => Colors.orange,
      2 => Colors.red,
      _ => Colors.grey,
    };
  }

  Color _getCategoryColor(String? category) {
    return switch (category) {
      'Work' => Colors.blue,
      'Personal' => Colors.purple,
      'Shopping' => Colors.orange,
      'Health' => Colors.red,
      'Learning' => Colors.teal,
      _ => Colors.grey,
    };
  }

  IconData _getCategoryIcon(String? category) {
    return switch (category) {
      'Work' => Icons.work_outline,
      'Personal' => Icons.person_outline,
      'Shopping' => Icons.shopping_cart_outlined,
      'Health' => Icons.favorite_outline,
      'Learning' => Icons.school_outlined,
      _ => Icons.list_alt,
    };
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_expandedCategories.contains(category)) {
        _expandedCategories.remove(category);
      } else {
        _expandedCategories.add(category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final allTasks = provider.allTasks;
    final selectedDayTasks = _selectedDay != null 
        ? _getTasksForDay(_selectedDay!, allTasks)
        : <Task>[];
    final groupedTasks = _groupTasksByCategory(selectedDayTasks);
    final sortedCategories = groupedTasks.keys.toList()..sort();
    
    // Check if screen is wide (desktop) or narrow (mobile)
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Tasks"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
            tooltip: "Today",
          ),
          IconButton(
            icon: const Icon(Icons.timer),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PomodoroScreen()),
              );
            },
            tooltip: "Pomodoro Timer",
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            tooltip: "Settings",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNewTaskForm(context),
        icon: const Icon(Icons.add),
        label: const Text("Add Task"),
      ),
      body: isDesktop 
          ? _buildDesktopLayout(selectedDayTasks, groupedTasks, sortedCategories, allTasks)
          : _buildMobileLayout(selectedDayTasks, groupedTasks, sortedCategories, allTasks),
    );
  }

  // Desktop Layout - Side by side
  Widget _buildDesktopLayout(List<Task> selectedDayTasks, Map<String, List<Task>> groupedTasks, List<String> sortedCategories, List<Task> allTasks) {
    return Row(
      children: [
        _buildCalendarPanel(allTasks, selectedDayTasks),
        Expanded(
          child: _buildTasksList(selectedDayTasks, groupedTasks, sortedCategories),
        ),
      ],
    );
  }

  // Mobile Layout - Stacked vertically
  Widget _buildMobileLayout(List<Task> selectedDayTasks, Map<String, List<Task>> groupedTasks, List<String> sortedCategories, List<Task> allTasks) {
    return Column(
      children: [
        // Compact calendar
        TableCalendar<Task>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
              _expandedCategories.clear();
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          eventLoader: (day) => _getTasksForDay(day, allTasks),
          calendarFormat: CalendarFormat.month, // Week view for mobile
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarBuilders: CalendarBuilders<Task>(
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return const SizedBox();
              
              final priorities = events.map((t) => t.priority).toSet().toList()
                  ..sort((a, b) => b.compareTo(a));

              return Positioned(
                bottom: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: priorities.take(3).map((priority) {
                    return Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(priority),
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        // Selected date info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selectedDay != null
                      ? "${_selectedDay!.day} ${_getMonthName(_selectedDay!.month)} ${_selectedDay!.year}"
                      : "Select a date",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                "${selectedDayTasks.length} task${selectedDayTasks.length == 1 ? '' : 's'}",
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        // Tasks list
        Expanded(
          child: _buildTasksList(selectedDayTasks, groupedTasks, sortedCategories),
        ),
      ],
    );
  }

  // Calendar Panel (Desktop only)
  Widget _buildCalendarPanel(List<Task> allTasks, List<Task> selectedDayTasks) {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  "Calendar",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          TableCalendar<Task>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                // Clear expanded categories when selecting a new day
                _expandedCategories.clear();
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: (day) => _getTasksForDay(day, allTasks),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarBuilders: CalendarBuilders<Task>(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return const SizedBox();
                
                final priorities = events.map((t) => t.priority).toSet().toList()
                  ..sort((a, b) => b.compareTo(a));

                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: priorities.take(3).map((priority) {
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(priority),
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedDay != null
                      ? "${_selectedDay!.day} ${_getMonthName(_selectedDay!.month)} ${_selectedDay!.year}"
                      : "Select a date",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${selectedDayTasks.length} task${selectedDayTasks.length == 1 ? '' : 's'} scheduled",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Text(
                  "Categories",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(cat),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          cat,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tasks List (shared by both layouts)
  Widget _buildTasksList(List<Task> selectedDayTasks, Map<String, List<Task>> groupedTasks, List<String> sortedCategories) {
    if (selectedDayTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              "No tasks scheduled",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Click + to add a new task",
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final tasks = groupedTasks[category]!;
        final completedCount = tasks.where((t) => t.isDone).length;
        final isExpanded = _expandedCategories.contains(category);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => _toggleCategory(category),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category).withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: isExpanded ? Radius.zero : const Radius.circular(12),
                      bottomRight: isExpanded ? Radius.zero : const Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        color: _getCategoryColor(category),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$completedCount of ${tasks.length} completed",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          value: tasks.isEmpty ? 0 : completedCount / tasks.length,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getCategoryColor(category),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  itemBuilder: (context, i) => TaskTile(
                    key: ValueKey(tasks[i].id),
                    task: tasks[i],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}