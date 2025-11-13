# 📝 Todo App
A beautiful and feature-rich todo application built with Flutter and Dart.

## 📸 Try live demo here: 
https://stran1023-todo-app.netlify.app/

You can switch between desktop view and mobile view by **F12 -> Crtl + Shift + M** (on Windows)

## ✨ Features

### 📅 Calendar-Centric Design
- Interactive calendar view with task visualization
- Date-based task organization
- Color-coded category indicators on calendar dates

### 🎯 Task Management
- Create, edit, and delete tasks
- Task priorities (High, Medium, Low)
- Categories (Work, Personal, Shopping, Health, Learning, Other)
- Due dates with calendar picker
- Task descriptions
- Drag and drop to reorder tasks
- Undo delete with snackbar

### 🍅 Pomodoro Timer
- Customizable work/break durations
- Focus sessions (default 25 minutes)
- Short breaks (default 5 minutes)
- Long breaks (default 15 minutes)
- Session tracking and statistics
- Daily and lifetime progress tracking
- Auto-switch between work and breaks

### 🎨 Themes & Customization
- Light and Dark mode
- 6 color themes (Blue, Purple, Green, Orange, Pink, Teal)
- Persistent theme preferences

### 💾 Data Persistence
- Local storage using Hive
- All data saved offline
- Fast and reliable

### 📱 Responsive Design
- Works on Windows desktop
- Mobile-friendly layout
- Adaptive UI for different screen sizes

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Dart SDK
- An IDE (VS Code, Android Studio, or IntelliJ)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/stran1023/flutter_todo_app.git
cd flutter_todo_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
# For Windows
flutter run -d windows

# For Android
flutter run -d android

# For Web
flutter run -d chrome
```

## 📦 Dependencies

- `hive` & `hive_flutter` - Local database
- `provider` - State management
- `table_calendar` - Calendar widget
- `uuid` - Unique ID generation

## 🏗️ Project Structure
```
lib/
├── main.dart
├── core/
│   └── theme/
│       └── app_theme.dart
├── data/
│   └── models/
│       ├── task_model.dart
│       └── task_model.g.dart
├── logic/
│   └── providers/
│       ├── task_provider.dart
│       └── theme_provider.dart
└── presentation/
    ├── screens/
    │   ├── home_screen.dart
    │   ├── calendar_screen.dart
    │   ├── settings_screen.dart
    │   └── pomodoro_screen.dart
    └── widgets/
        ├── task_tile.dart
        └── task_form.dart
```

## 🎯 Usage

### Adding a Task
1. Click the **+ Add Task** button
2. Fill in task details (title required)
3. Select priority and category
4. Set a due date
5. Click **Add**

### Using Pomodoro Timer
1. Click the **⏱️ Timer** icon in the app bar
2. Click **Start** to begin a focus session
3. Work until the timer completes
4. Take a break when prompted
5. Customize timer durations in settings

### Changing Themes
1. Click **⚙️ Settings** icon
2. Toggle **Dark Mode**
3. Select your preferred **Color Theme**
4. Changes apply immediately
