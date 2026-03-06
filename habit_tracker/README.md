# 🎯 Трекер привычек

Чистое и расширяемое Flutter‑приложение для отслеживания привычек с тёмным интерфейсом, счётчиками стриков и статистикой.

## ✨ Features

- **Экран Сегодня** — отслеживайте ежедневные/еженедельные привычки одним касанием
- **Счётчик стриков** — 🔥 текущие и лучшие серии по каждой привычке
- **Кольцо прогресса** — визуализация дневного прогресса
- **Statistics** — 30-day heatmap strip, completion rate, totals
- **Добавление/редактирование привычек** — собственная иконка, цвет, категория, частота
- **Swipe Actions** — edit or archive by swiping left
- **Сохранение** — привычки хранятся локально с помощью `shared_preferences`
- **Dark Theme** — polished Material 3 dark design

## 🚀 Getting Started

### Prerequisites

- Flutter SDK ≥ 3.0.0 — [Install Flutter](https://docs.flutter.dev/get-started/install)
- VS Code + [Flutter extension](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)

### Run the app

```bash
cd habit_tracker
flutter pub get
flutter run
```

Or in VS Code: press **F5** to launch.

## 📁 Project Structure

```
lib/
├── main.dart              # App entry point
├── models/
│   └── habit.dart         # Habit data model + serialization
├── providers/
│   └── habit_provider.dart # State management (ChangeNotifier)
├── screens/
│   ├── home_screen.dart   # Main screen with bottom nav
│   ├── add_habit_screen.dart # Create/Edit habit form
│   └── stats_screen.dart  # Statistics & heatmaps
├── widgets/
│   ├── habit_card.dart    # Swipeable habit list item
│   ├── progress_header.dart # Daily progress ring
│   └── empty_state.dart   # Empty list state
└── theme/
    └── app_theme.dart     # Colors, typography, theme
```

## 🔧 Easy to Extend

Here are ideas to build on top of this foundation:

| Feature | Where to add |
|---|---|
| Push notifications / reminders | `providers/notification_provider.dart` + `pubspec: flutter_local_notifications` |
| Weekly calendar view | New `widgets/week_calendar.dart` |
| Habit notes / journal | Add `notes` field to `Habit` model |
| iCloud / Firebase sync | New `services/sync_service.dart` |
| Light theme toggle | Add `themeMode` to `HabitProvider` |
| Widget (home screen) | `android/` + `ios/` native code |
| CSV / JSON export | New `services/export_service.dart` |
| Tags / filtering | Add `tags` list to `Habit` model |
| Gamification / XP | New `models/user_progress.dart` |

## 🏗 Architecture

- **State**: `provider` package with `ChangeNotifier`
- **Storage**: `shared_preferences` (local, no backend required)
- **Routing**: `Navigator.push` (easy to migrate to go_router)
- **Models**: Plain Dart classes with JSON serialization

## 📦 Dependencies

| Package | Purpose |
|---|---|
| `provider` | State management |
| `shared_preferences` | Local persistence |
| `uuid` | Unique habit IDs |
| `intl` | Date formatting |
| `google_fonts` | Inter font |
| `flutter_slidable` | Swipe-to-edit/archive |
| `fl_chart` | (ready for chart widgets) |
