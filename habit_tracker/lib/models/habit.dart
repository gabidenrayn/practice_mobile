import 'dart:convert';

enum HabitFrequency { daily, weekly }

enum HabitCategory { health, productivity, mindfulness, fitness, learning, custom }

class Habit {
  final String id;
  String title;
  String? description;
  HabitCategory category;
  HabitFrequency frequency;
  String colorHex;
  String iconName;
  DateTime createdAt;
  List<DateTime> completedDates;
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

  /// Check if completed on a specific date
  bool isCompletedOn(DateTime date) {
    return completedDates.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  bool get isCompletedToday => isCompletedOn(DateTime.now());

  /// Current streak (consecutive days ending today)
  int get currentStreak {
    int streak = 0;
    DateTime day = DateTime.now();
    while (isCompletedOn(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Best streak ever
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

  /// Completion rate for last 30 days
  double get completionRate30Days {
    final now = DateTime.now();
    int completed = 0;
    for (int i = 0; i < 30; i++) {
      if (isCompletedOn(now.subtract(Duration(days: i)))) completed++;
    }
    return completed / 30;
  }

  Habit copyWith({
    String? title,
    String? description,
    HabitCategory? category,
    HabitFrequency? frequency,
    String? colorHex,
    String? iconName,
    bool? isArchived,
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
      completedDates: completedDates,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.index,
        'frequency': frequency.index,
        'colorHex': colorHex,
        'iconName': iconName,
        'createdAt': createdAt.toIso8601String(),
        'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
        'isArchived': isArchived,
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        category: HabitCategory.values[json['category'] ?? 6],
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
