import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

enum PomodoroType {
  work,
  shortBreak,
  longBreak;

  String get label => switch (this) {
    PomodoroType.work => 'Focus',
    PomodoroType.shortBreak => 'Short Break',
    PomodoroType.longBreak => 'Long Break',
  };
}

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  PomodoroType _currentType = PomodoroType.work;
  int _completedPomodoros = 0;
  int _todayPomodoros = 0;
  int _todayMinutesFocused = 0;

  int _workDuration = 25;
  int _shortBreakDuration = 5;
  int _longBreakDuration = 15;

  late Box _statsBox;
  late Box _settingsBox;

  @override
  void initState() {
    super.initState();
    _initBoxes();
  }

  Future<void> _initBoxes() async {
    _statsBox = await Hive.openBox('pomodoroStats');
    _settingsBox = await Hive.openBox('pomodoroSettings');
    await _loadStats();
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _workDuration = _settingsBox.get('workDuration', defaultValue: 25);
      _shortBreakDuration = _settingsBox.get('shortBreakDuration', defaultValue: 5);
      _longBreakDuration = _settingsBox.get('longBreakDuration', defaultValue: 15);
      _remainingSeconds = _getCurrentDuration() * 60;
    });
  }

  Future<void> _saveSettings() async {
    await _settingsBox.put('workDuration', _workDuration);
    await _settingsBox.put('shortBreakDuration', _shortBreakDuration);
    await _settingsBox.put('longBreakDuration', _longBreakDuration);
  }

  int _getCurrentDuration() {
    return switch (_currentType) {
      PomodoroType.work => _workDuration,
      PomodoroType.shortBreak => _shortBreakDuration,
      PomodoroType.longBreak => _longBreakDuration,
    };
  }

  Future<void> _loadStats() async {
    final today = DateTime.now().toString().split(' ')[0];
    final lastDate = _statsBox.get('lastDate', defaultValue: '');

    setState(() {
      _completedPomodoros = _statsBox.get('totalPomodoros', defaultValue: 0);
      if (lastDate == today) {
        _todayPomodoros = _statsBox.get('todayPomodoros', defaultValue: 0);
        _todayMinutesFocused = _statsBox.get('todayMinutesFocused', defaultValue: 0);
      } else {
        _todayPomodoros = 0;
        _todayMinutesFocused = 0;
      }
    });

    // persist reset if new day
    if (lastDate != today) {
      await _statsBox.put('todayPomodoros', 0);
      await _statsBox.put('todayMinutesFocused', 0);
      await _statsBox.put('lastDate', today);
    }
  }

  Future<void> _saveStats() async {
    final today = DateTime.now().toString().split(' ')[0];
    await _statsBox.put('totalPomodoros', _completedPomodoros);
    await _statsBox.put('todayPomodoros', _todayPomodoros);
    await _statsBox.put('todayMinutesFocused', _todayMinutesFocused);
    await _statsBox.put('lastDate', today);
  }

  void _startTimer() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _completeSession();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRunning = false;
      _remainingSeconds = _getCurrentDuration() * 60;
    });
  }

  void _completeSession() {
    if (_timer == null) return;
    _timer?.cancel();
    _timer = null;

    final previousType = _currentType;

    if (previousType == PomodoroType.work) {
      setState(() {
        _completedPomodoros++;
        _todayPomodoros++;
        _todayMinutesFocused += _workDuration;
      });
      _saveStats();
    }

    setState(() {
      _isRunning = false;

      if (previousType == PomodoroType.work) {
        if (_todayPomodoros % 4 == 0) {
          _currentType = PomodoroType.longBreak;
        } else {
          _currentType = PomodoroType.shortBreak;
        }
      } else {
        _currentType = PomodoroType.work;
      }

      _remainingSeconds = _getCurrentDuration() * 60;
    });

    _showCompletionDialog(previousType);
  }

  void _showCompletionDialog(PomodoroType previousType) {
    final isWork = previousType == PomodoroType.work;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isWork ? Icons.celebration : Icons.coffee,
              color: _getTypeColor(),
              size: 32,
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text("Session Complete!")),
          ],
        ),
        content: Text(
          isWork
              ? "Great work! Time for a break 🎉"
              : "Break's over! Ready to focus? 💪",
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Later"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startTimer();
            },
            child: const Text("Start Now"),
          ),
        ],
      ),
    );
  }

  void _changeSessionType(PomodoroType type) {
    _resetTimer();
    setState(() {
      _currentType = type;
      _remainingSeconds = _getCurrentDuration() * 60;
    });
  }

  void _showSettingsDialog() {
    int tempWork = _workDuration;
    int tempShort = _shortBreakDuration;
    int tempLong = _longBreakDuration;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Timer Settings"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDurationSlider(
                  label: "Focus Duration",
                  value: tempWork,
                  min: 1,
                  max: 60,
                  icon: Icons.work_outline,
                  color: Colors.red,
                  onChanged: (value) {
                    setDialogState(() => tempWork = value.round());
                  },
                ),
                const SizedBox(height: 16),
                _buildDurationSlider(
                  label: "Short Break",
                  value: tempShort,
                  min: 1,
                  max: 30,
                  icon: Icons.coffee,
                  color: Colors.green,
                  onChanged: (value) {
                    setDialogState(() => tempShort = value.round());
                  },
                ),
                const SizedBox(height: 16),
                _buildDurationSlider(
                  label: "Long Break",
                  value: tempLong,
                  min: 1,
                  max: 60,
                  icon: Icons.beach_access,
                  color: Colors.blue,
                  onChanged: (value) {
                    setDialogState(() => tempLong = value.round());
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _workDuration = tempWork;
                  _shortBreakDuration = tempShort;
                  _longBreakDuration = tempLong;
                  _remainingSeconds = _getCurrentDuration() * 60;
                });
                await _saveSettings();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Timer settings saved!"),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSlider({
    required String label,
    required int value,
    required int min,
    required int max,
    required IconData icon,
    required Color color,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "$value min",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Color _getTypeColor() {
    return switch (_currentType) {
      PomodoroType.work => Colors.red,
      PomodoroType.shortBreak => Colors.green,
      PomodoroType.longBreak => Colors.blue,
    };
  }

  IconData _getTypeIcon() {
    return switch (_currentType) {
      PomodoroType.work => Icons.work_outline,
      PomodoroType.shortBreak => Icons.coffee,
      PomodoroType.longBreak => Icons.beach_access,
    };
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = _getCurrentDuration().clamp(1, 9999);
    final progress = 1 - (_remainingSeconds / (duration * 60));
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pomodoro Timer"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
            tooltip: "Timer Settings",
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Session Type Selector
              Row(
                children: PomodoroType.values.map((type) {
                  final isSelected = _currentType == type;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: _isRunning ? null : () => _changeSessionType(type),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? _getTypeColor() : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getIconForType(type),
                                color: isSelected ? Colors.white : Colors.black54,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                type.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const Spacer(flex: 1),

              // Circular Timer
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: screenHeight * 0.35,
                    height: screenHeight * 0.35,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(_getTypeColor()),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getTypeIcon(), size: 40, color: _getTypeColor()),
                      const SizedBox(height: 12),
                      Text(
                        _formatTime(_remainingSeconds),
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: _getTypeColor(),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentType.label,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Spacer(flex: 1),

              // Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isRunning)
                    ElevatedButton.icon(
                      onPressed: _startTimer,
                      icon: const Icon(Icons.play_arrow, size: 28),
                      label: const Text("Start", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getTypeColor(),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _pauseTimer,
                      icon: const Icon(Icons.pause, size: 28),
                      label: const Text("Pause", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      ),
                    ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _resetTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(14),
                      shape: const CircleBorder(),
                    ),
                    child: const Icon(Icons.refresh, size: 24),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Your Progress",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCompactStat(
                          icon: Icons.today,
                          label: "Today",
                          value: "$_todayPomodoros",
                          color: Colors.blue,
                          tooltip: "Focus sessions today",
                        ),
                        Container(width: 1, height: 40, color: Colors.grey[300]),
                        _buildCompactStat(
                          icon: Icons.access_time,
                          label: "Focus Time",
                          value: "${_todayMinutesFocused}m",
                          color: Colors.orange,
                          tooltip: "Minutes focused today",
                        ),
                        Container(width: 1, height: 40, color: Colors.grey[300]),
                        _buildCompactStat(
                          icon: Icons.check_circle,
                          label: "All Time",
                          value: "$_completedPomodoros",
                          color: Colors.green,
                          tooltip: "Total sessions completed",
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? tooltip,
  }) {
    final stat = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: stat);
    }
    return stat;
  }

  IconData _getIconForType(PomodoroType type) {
    return switch (type) {
      PomodoroType.work => Icons.work_outline,
      PomodoroType.shortBreak => Icons.coffee,
      PomodoroType.longBreak => Icons.beach_access,
    };
  }
}
