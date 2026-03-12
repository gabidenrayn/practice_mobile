import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';

class HabitProvider extends ChangeNotifier {
  static const _boxName = 'habits';
  static const _legacyKey = 'habits_v1'; // старый ключ SharedPreferences

  late Box<Habit> _box;
  bool _isLoading = true;

  // ─── Getters ──────────────────────────────────────────────────────────────

  List<Habit> get _habits => _box.values.toList();

  List<Habit> get habits => _habits.where((h) => !h.isArchived).toList();

  List<Habit> get archivedHabits =>
      _habits.where((h) => h.isArchived).toList();

  bool get isLoading => _isLoading;

  List<Habit> get todayHabits {
    final now = DateTime.now();
    return habits.where((h) {
      if (h.frequency == HabitFrequency.daily) return true;
      return h.createdAt.weekday == now.weekday;
    }).toList();
  }

  int get completedTodayCount =>
      todayHabits.where((h) => h.isCompletedToday).length;

  double get todayProgress =>
      todayHabits.isEmpty ? 0 : completedTodayCount / todayHabits.length;

  // ─── Инициализация ────────────────────────────────────────────────────────

  HabitProvider() {
    _init();
  }

  /// Инициализация Hive и миграция данных из SharedPreferences (если нужно)
  Future<void> _init() async {
    await Hive.initFlutter();

    // Регистрируем адаптеры
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(HabitAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HabitFrequencyAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(HabitCategoryAdapter());
    }

    _box = await Hive.openBox<Habit>(_boxName);

    // Миграция: если Hive пустой, но есть данные в SharedPreferences
    if (_box.isEmpty) {
      await _migrateFromSharedPreferences();
    }

    // Первый запуск: добавляем sample habits
    if (_box.isEmpty) {
      for (final habit in _seedHabits()) {
        await _box.put(habit.id, habit);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Миграция старых данных из SharedPreferences → Hive
  Future<void> _migrateFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_legacyKey);
      if (data != null) {
        final habits = Habit.decodeList(data);
        for (final habit in habits) {
          await _box.put(habit.id, habit);
        }
        // Удаляем старые данные после успешной миграции
        await prefs.remove(_legacyKey);
        debugPrint('✅ Миграция SharedPreferences → Hive: ${habits.length} привычек');
      }
    } catch (e) {
      debugPrint('⚠️ Ошибка миграции: $e');
    }
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

  // ─── CRUD операции ────────────────────────────────────────────────────────

  Future<void> addHabit({
    required String title,
    String? description,
    HabitCategory category = HabitCategory.custom,
    HabitFrequency frequency = HabitFrequency.daily,
    String colorHex = '#6C63FF',
    String iconName = 'star',
  }) async {
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
    await _box.put(habit.id, habit);
    notifyListeners();
  }

  Future<void> toggleCompletion(String habitId, {DateTime? date}) async {
    final habit = _box.get(habitId);
    if (habit == null) return;

    final target = date ?? DateTime.now();
    final already = habit.isCompletedOn(target);

    if (already) {
      habit.completedDates.removeWhere(
        (d) =>
            d.year == target.year &&
            d.month == target.month &&
            d.day == target.day,
      );
    } else {
      habit.completedDates.add(target);
    }

    await habit.save(); // Hive HiveObject.save() — сохраняет изменения
    notifyListeners();
  }

  Future<void> updateHabit(
    String habitId, {
    String? title,
    String? description,
    HabitCategory? category,
    HabitFrequency? frequency,
    String? colorHex,
    String? iconName,
  }) async {
    final habit = _box.get(habitId);
    if (habit == null) return;

    if (title != null) habit.title = title;
    if (description != null) habit.description = description;
    if (category != null) habit.category = category;
    if (frequency != null) habit.frequency = frequency;
    if (colorHex != null) habit.colorHex = colorHex;
    if (iconName != null) habit.iconName = iconName;

    await habit.save();
    notifyListeners();
  }

  Future<void> archiveHabit(String habitId) async {
    final habit = _box.get(habitId);
    if (habit == null) return;
    habit.isArchived = true;
    await habit.save();
    notifyListeners();
  }

  Future<void> deleteHabit(String habitId) async {
    await _box.delete(habitId);
    notifyListeners();
  }

  // ─── Аналитика ────────────────────────────────────────────────────────────

  /// Карта выполнения конкретной привычки (для heatmap)
  Map<DateTime, int> getHeatmapData(String habitId, {int days = 365}) {
    final habit = _box.get(habitId);
    if (habit == null) return {};
    return habit.getHeatmapData(days: days);
  }

  /// Общая карта активности по всем привычкам (для общего heatmap)
  Map<DateTime, int> getOverallHeatmapData({int days = 365}) {
    final now = DateTime.now();
    final map = <DateTime, int>{};

    for (int i = 0; i < days; i++) {
      final day = now.subtract(Duration(days: i));
      final key = DateTime(day.year, day.month, day.day);
      int count = 0;
      for (final habit in habits) {
        if (habit.isCompletedOn(day)) count++;
      }
      map[key] = count;
    }
    return map;
  }

  /// Статистика за последние 7 дней (для графика)
  List<Map<String, dynamic>> getWeeklyStats() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final key = DateTime(day.year, day.month, day.day);
      int completed = 0;
      int total = todayHabits.length;
      for (final habit in habits) {
        if (habit.isCompletedOn(day)) completed++;
      }
      return {'date': key, 'completed': completed, 'total': total};
    });
  }

  // Оставляем старый метод для обратной совместимости
  Map<DateTime, bool> getCompletionMap(String habitId, {int days = 30}) {
    final habit = _box.get(habitId);
    if (habit == null) return {};
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
