import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

enum AppThemeColor {
  blue,
  purple,
  green,
  orange,
  pink,
  teal;

  String get name => switch (this) {
    AppThemeColor.blue => 'Blue',
    AppThemeColor.purple => 'Purple',
    AppThemeColor.green => 'Green',
    AppThemeColor.orange => 'Orange',
    AppThemeColor.pink => 'Pink',
    AppThemeColor.teal => 'Teal',
  };

  Color get color => switch (this) {
    AppThemeColor.blue => Colors.blue,
    AppThemeColor.purple => Colors.purple,
    AppThemeColor.green => Colors.green,
    AppThemeColor.orange => Colors.orange,
    AppThemeColor.pink => Colors.pink,
    AppThemeColor.teal => Colors.teal,
  };
}

class ThemeProvider extends ChangeNotifier {
  static const String _boxName = 'themeSettings';
  static const String _themeModeKey = 'themeMode';
  static const String _themeColorKey = 'themeColor';

  ThemeMode _themeMode = ThemeMode.light;
  AppThemeColor _themeColor = AppThemeColor.blue;

  ThemeMode get themeMode => _themeMode;
  AppThemeColor get themeColor => _themeColor;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Load saved theme from Hive
  Future<void> loadTheme() async {
    final box = await Hive.openBox(_boxName);
    
    // Load theme mode
    final savedMode = box.get(_themeModeKey, defaultValue: 'light');
    _themeMode = savedMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
    
    // Load theme color
    final savedColor = box.get(_themeColorKey, defaultValue: 'blue');
    _themeColor = AppThemeColor.values.firstWhere(
      (c) => c.name.toLowerCase() == savedColor,
      orElse: () => AppThemeColor.blue,
    );
    
    notifyListeners();
  }

  // Toggle between light and dark mode
  Future<void> toggleThemeMode() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _saveThemeMode();
    notifyListeners();
  }

  // Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _saveThemeMode();
    notifyListeners();
  }

  // Change theme color
  Future<void> setThemeColor(AppThemeColor color) async {
    _themeColor = color;
    await _saveThemeColor();
    notifyListeners();
  }

  // Save theme mode to Hive
  Future<void> _saveThemeMode() async {
    final box = await Hive.openBox(_boxName);
    await box.put(_themeModeKey, _themeMode == ThemeMode.dark ? 'dark' : 'light');
  }

  // Save theme color to Hive
  Future<void> _saveThemeColor() async {
    final box = await Hive.openBox(_boxName);
    await box.put(_themeColorKey, _themeColor.name.toLowerCase());
  }

  // Get light theme
  ThemeData get lightTheme => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _themeColor.color,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: _themeColor.color,
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _themeColor.color,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );

  // Get dark theme
  ThemeData get darkTheme => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _themeColor.color,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: _themeColor.color.withOpacity(0.2),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _themeColor.color,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}