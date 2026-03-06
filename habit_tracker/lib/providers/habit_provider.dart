import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';

class HabitProvider extends ChangeNotifier {
  static const _storageKey = 'habits_v1';

  List<Habit> _habits = [];
  bool _isLoading = true;

  List<Habit> get habits => _habits.where((h) => !h.isArchived).toList();
  List<Habit> get archivedHabits => _habits.where((h) => h.isArchived).toList();
  bool get isLoading => _isLoading;

  List<Habit> get todayHabits {
    final now = DateTime.now();
    return habits.where((h) {
      if (h.frequency == HabitFrequency.daily) return true;
      // Weekly: only show on the day of the week it was created
      return h.createdAt.weekday == now.weekday;
    }).toList();
  }

  int get completedTodayCount =>
      todayHabits.where((h) => h.isCompletedToday).length;

  double get todayProgress =>
      todayHabits.isEmpty ? 0 : completedTodayCount / todayHabits.length;

  HabitProvider() {
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      _habits = Habit.decodeList(data);
    } else {
      _habits = _seedHabits(); // First launch: add sample habits
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, Habit.encodeList(_habits));
  }

  List<Habit> _seedHabits() => [
        Habit(
          id: const Uuid().v4(),
          title: 'Утренняя медитация',
          description: '10 минут осознанности',
          category: HabitCategory.mindfulness,
          colorHex: '#FF6B9D',
          iconName: 'self_improvement',
          createdAt: DateTime.now(),
        ),
        Habit(
          id: const Uuid().v4(),
          title: 'Чтение 30 мин',
          description: 'Любая книга подойдёт',
          category: HabitCategory.learning,
          colorHex: '#4ECDC4',
          iconName: 'menu_book',
          createdAt: DateTime.now(),
        ),
        Habit(
          id: const Uuid().v4(),
          title: 'Выпить 8 стаканов воды',
          category: HabitCategory.health,
          colorHex: '#45B7D1',
          iconName: 'water_drop',
          createdAt: DateTime.now(),
        ),
      ];

  void addHabit({
    required String title,
    String? description,
    HabitCategory category = HabitCategory.custom,
    HabitFrequency frequency = HabitFrequency.daily,
    String colorHex = '#6C63FF',
    String iconName = 'star',
  }) {
    final habit = Habit(
      id: const Uuid().v4(),
      title: title,
      description: description,
      category: category,
      frequency: frequency,
      colorHex: colorHex,
      iconName: iconName,
      createdAt: DateTime.now(),
    );
    _habits.add(habit);
    _saveHabits();
    notifyListeners();
  }

  void toggleCompletion(String habitId, {DateTime? date}) {
    final idx = _habits.indexWhere((h) => h.id == habitId);
    if (idx == -1) return;
    final habit = _habits[idx];
    final target = date ?? DateTime.now();
    final already = habit.isCompletedOn(target);
    if (already) {
      habit.completedDates.removeWhere((d) =>
          d.year == target.year &&
          d.month == target.month &&
          d.day == target.day);
    } else {
      habit.completedDates.add(target);
    }
    _saveHabits();
    notifyListeners();
  }

  void updateHabit(
    String habitId, {
    String? title,
    String? description,
    HabitCategory? category,
    HabitFrequency? frequency,
    String? colorHex,
    String? iconName,
  }) {
    final idx = _habits.indexWhere((h) => h.id == habitId);
    if (idx == -1) return;
    _habits[idx] = _habits[idx].copyWith(
      title: title,
      description: description,
      category: category,
      frequency: frequency,
      colorHex: colorHex,
      iconName: iconName,
    );
    _saveHabits();
    notifyListeners();
  }

  void archiveHabit(String habitId) {
    final idx = _habits.indexWhere((h) => h.id == habitId);
    if (idx == -1) return;
    _habits[idx] = _habits[idx].copyWith(isArchived: true);
    _saveHabits();
    notifyListeners();
  }

  void deleteHabit(String habitId) {
    _habits.removeWhere((h) => h.id == habitId);
    _saveHabits();
    notifyListeners();
  }

  /// Returns completion map for the last [days] days for a specific habit
  Map<DateTime, bool> getCompletionMap(String habitId, {int days = 30}) {
    final habit = _habits.firstWhere((h) => h.id == habitId,
        orElse: () => Habit(id: '', title: '', createdAt: DateTime.now()));
    final now = DateTime.now();
    final map = <DateTime, bool>{};
    for (int i = 0; i < days; i++) {
      final day = now.subtract(Duration(days: i));
      final key = DateTime(day.year, day.month, day.day);
      map[key] = habit.isCompletedOn(day);
    }
    return map;
  }
}
