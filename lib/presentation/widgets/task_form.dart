import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';

class TaskForm extends StatefulWidget {
  final Task? initialTask;
  final void Function(
    String title,
    String? desc,
    DateTime? dueDate,
    int priority,
    String? category,
  ) onSubmit;

  const TaskForm({super.key, this.initialTask, required this.onSubmit});

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  DateTime? _dueDate;
  int _priority = 1;
  String? _category;
  
  // Error messages
  String? _dueDateError;
  String? _categoryError;
  
  // Character limits
  static const int _titleMaxLength = 100;
  static const int _descMaxLength = 500;
  int _descCharCount = 0;

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
    _titleController = TextEditingController(text: widget.initialTask?.title ?? '');
    _descController = TextEditingController(text: widget.initialTask?.description ?? '');
    _dueDate = widget.initialTask?.dueDate;
    _priority = widget.initialTask?.priority ?? 1;
    _category = widget.initialTask?.category;
    
    // Initialize character count
    _descCharCount = _descController.text.length;
    
    // Listen to description changes
    _descController.addListener(() {
      setState(() {
        _descCharCount = _descController.text.length;
      });
    });
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      initialDate: _dueDate ?? now,
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
        _dueDateError = null; // Clear error when date is selected
      });
    }
  }

  void _handleSubmit() {
    // Clear previous errors
    setState(() {
      _dueDateError = null;
      _categoryError = null;
    });

    // Validate form fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate due date
    if (_dueDate == null) {
      setState(() {
        _dueDateError = "Please select a due date";
      });
      return;
    }

    // Validate category
    if (_category == null) {
      setState(() {
        _categoryError = "Please select a category";
      });
      return;
    }

    // All validations passed
    widget.onSubmit(
      _titleController.text,
      _descController.text,
      _dueDate,
      _priority,
      _category,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialTask == null ? "New Task" : "Edit Task"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Title *",
                  hintText: "Enter task title",
                  counterText: "", // Hide default counter
                ),
                maxLength: _titleMaxLength,
                validator: (v) => v == null || v.trim().isEmpty ? "Title is required" : null,
              ),
              const SizedBox(height: 10),

              // Description field
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: "Description",
                  hintText: "Add details (optional)",
                  counterText: "$_descCharCount/$_descMaxLength",
                  counterStyle: TextStyle(
                    color: _descCharCount > _descMaxLength 
                        ? Colors.red 
                        : Colors.grey[600],
                  ),
                ),
                maxLength: _descMaxLength,
                maxLines: 3,
                validator: (v) {
                  if (v != null && v.length > _descMaxLength) {
                    return "Description is too long (max $_descMaxLength characters)";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Priority selector
              const Text("Priority *", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('Low'),
                    icon: Icon(Icons.arrow_downward, color: Colors.green),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Medium'),
                    icon: Icon(Icons.remove, color: Colors.orange),
                  ),
                  ButtonSegment(
                    value: 2,
                    label: Text('High'),
                    icon: Icon(Icons.arrow_upward, color: Colors.red),
                  ),
                ],
                selected: {_priority},
                onSelectionChanged: (Set<int> selected) {
                  setState(() => _priority = selected.first);
                },
              ),
              const SizedBox(height: 16),

              // Category dropdown
              const Text("Category *", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  errorText: _categoryError,
                  errorStyle: const TextStyle(color: Colors.red),
                ),
                hint: const Text('Select category'),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _category = value;
                    _categoryError = null; // Clear error when category is selected
                  });
                },
              ),
              const SizedBox(height: 16),

              // Due date picker
              const Text("Due Date *", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _dueDateError != null ? Colors.red : Colors.grey,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          _dueDate == null
                              ? "No date selected"
                              : "Due: ${_dueDate!.toLocal().toString().split(' ')[0]}",
                          style: TextStyle(
                            color: _dueDate == null ? Colors.grey[600] : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: const Text("Pick date"),
                    )
                  ],
                ),
              ),
              if (_dueDateError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: Text(
                    _dueDateError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                "* Required fields",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _handleSubmit,
          child: Text(widget.initialTask == null ? "Add" : "Save"),
        ),
      ],
    );
  }
}