import 'dart:convert';
import 'package:hive/hive.dart';

part 'habit.g.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

@HiveType(typeId: 1)
enum HabitFrequency {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
}

@HiveType(typeId: 2)
enum HabitCategory {
  @HiveField(0)
  health,
  @HiveField(1)
  productivity,
  @HiveField(2)
  mindfulness,
  @HiveField(3)
  fitness,
  @HiveField(4)
  learning,
  @HiveField(5)
  custom,
}

// ─── Model ────────────────────────────────────────────────────────────────────

@HiveType(typeId: 0)
class Habit extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  HabitCategory category;

  @HiveField(4)
  HabitFrequency frequency;

  @HiveField(5)
  String colorHex;

  @HiveField(6)
  String iconName;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  List<DateTime> completedDates;

  @HiveField(9)
  bool isArchived;

  Habit({
    required this.id,
    required this.title,
    this.description,
    this.category = HabitCategory.custom,
    this.frequency = HabitFrequency.daily,
    this.colorHex = '#6C63FF',
    this.iconName = 'star',
    required this.createdAt,
    List<DateTime>? completedDates,
    this.isArchived = false,
  }) : completedDates = completedDates ?? [];

  // ─── Computed properties ───────────────────────────────────────────────────

  bool isCompletedOn(DateTime date) {
    return completedDates.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }

  bool get isCompletedToday => isCompletedOn(DateTime.now());

  /// Текущая серия (streak) — непрерывные дни до сегодня
  int get currentStreak {
    int streak = 0;
    DateTime day = DateTime.now();
    while (isCompletedOn(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Лучшая серия за всё время
  int get bestStreak {
    if (completedDates.isEmpty) return 0;
    final sorted = [...completedDates]..sort();
    int best = 1, current = 1;
    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > best) best = current;
      } else if (diff > 1) {
        current = 1;
      }
    }
    return best;
  }

  /// Процент выполнения за последние 30 дней
  double get completionRate30Days {
    final now = DateTime.now();
    int completed = 0;
    for (int i = 0; i < 30; i++) {
      if (isCompletedOn(now.subtract(Duration(days: i)))) completed++;
    }
    return completed / 30;
  }

  /// Карта выполнения за последние [days] дней
  Map<DateTime, int> getHeatmapData({int days = 365}) {
    final now = DateTime.now();
    final map = <DateTime, int>{};
    for (int i = 0; i < days; i++) {
      final day = now.subtract(Duration(days: i));
      final key = DateTime(day.year, day.month, day.day);
      map[key] = isCompletedOn(day) ? 1 : 0;
    }
    return map;
  }

  // ─── CopyWith ─────────────────────────────────────────────────────────────

  Habit copyWith({
    String? title,
    String? description,
    HabitCategory? category,
    HabitFrequency? frequency,
    String? colorHex,
    String? iconName,
    bool? isArchived,
    List<DateTime>? completedDates,
  }) {
    return Habit(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt,
      completedDates: completedDates ?? this.completedDates,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  // ─── JSON (для обратной совместимости при миграции) ───────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.index,
        'frequency': frequency.index,
        'colorHex': colorHex,
        'iconName': iconName,
        'createdAt': createdAt.toIso8601String(),
        'completedDates':
            completedDates.map((d) => d.toIso8601String()).toList(),
        'isArchived': isArchived,
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        category: HabitCategory.values[json['category'] ?? 5],
        frequency: HabitFrequency.values[json['frequency'] ?? 0],
        colorHex: json['colorHex'] ?? '#6C63FF',
        iconName: json['iconName'] ?? 'star',
        createdAt: DateTime.parse(json['createdAt']),
        completedDates: (json['completedDates'] as List<dynamic>)
            .map((d) => DateTime.parse(d))
            .toList(),
        isArchived: json['isArchived'] ?? false,
      );

  static String encodeList(List<Habit> habits) =>
      json.encode(habits.map((h) => h.toJson()).toList());

  static List<Habit> decodeList(String data) =>
      (json.decode(data) as List<dynamic>)
          .map((h) => Habit.fromJson(h))
          .toList();
}
