import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Heatmap календарь активности в стиле GitHub
class HabitHeatmap extends StatelessWidget {
  final Map<DateTime, int> data;
  final Color baseColor;
  final int maxValue; // максимальное значение для насыщенности цвета
  final String title;

  const HabitHeatmap({
    super.key,
    required this.data,
    this.baseColor = const Color(0xFF6C63FF),
    this.maxValue = 1,
    this.title = 'Активность за год',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
        ],
        _buildMonthLabels(context),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeekdayLabels(context),
            const SizedBox(width: 4),
            Expanded(child: _buildGrid()),
          ],
        ),
        const SizedBox(height: 8),
        _buildLegend(context),
      ],
    );
  }

  Widget _buildMonthLabels(BuildContext context) {
    final weeks = _buildWeeks();
    final labels = <Widget>[];

    String? lastMonth;
    for (int i = 0; i < weeks.length; i++) {
      final firstDay = weeks[i].first;
      if (firstDay == null) {
        labels.add(const Expanded(child: SizedBox()));
        continue;
      }

      final month = DateFormat('MMM', 'ru').format(firstDay);
      if (month != lastMonth && firstDay.day <= 7) {
        lastMonth = month;
        labels.add(
          Expanded(
            child: Text(
              month,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
              overflow: TextOverflow.clip,
            ),
          ),
        );
      } else {
        labels.add(const Expanded(child: SizedBox()));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(left: 22),
      child: Row(children: labels),
    );
  }

  Widget _buildWeekdayLabels(BuildContext context) {
    const days = ['', 'Пн', '', 'Ср', '', 'Пт', ''];
    return Column(
      children: days
          .map(
            (d) => SizedBox(
              height: 13,
              width: 18,
              child: Text(
                d,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white38,
                      fontSize: 9,
                    ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildGrid() {
    final weeks = _buildWeeks();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: weeks.map((week) {
        return Expanded(
          child: Column(
            children: week.map((day) {
              if (day == null) {
                return const SizedBox(height: 13);
              }
              final value = data[day] ?? 0;
              return Padding(
                padding: const EdgeInsets.all(1),
                child: _buildCell(day, value),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCell(DateTime day, int value) {
    final color = _getCellColor(value);
    final isToday = _isToday(day);

    return Tooltip(
      message: _formatTooltip(day, value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 11,
        height: 11,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
          border: isToday
              ? Border.all(color: Colors.white54, width: 1)
              : null,
        ),
      ),
    );
  }

  Color _getCellColor(int value) {
    if (value == 0) return Colors.white.withOpacity(0.07);

    final ratio = (value / maxValue).clamp(0.0, 1.0);
    return Color.lerp(
      baseColor.withOpacity(0.3),
      baseColor,
      ratio,
    )!;
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;
  }

  String _formatTooltip(DateTime day, int value) {
    final dateStr = DateFormat('d MMM yyyy', 'ru').format(day);
    if (value == 0) return '$dateStr: не выполнено';
    if (maxValue == 1) return '$dateStr: выполнено ✓';
    return '$dateStr: $value/${maxValue}';
  }

  /// Строим сетку: 53 недели × 7 дней
  List<List<DateTime?>> _buildWeeks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Начинаем с понедельника 53 недели назад
    final startOffset = (today.weekday - 1) + 52 * 7;
    final start = today.subtract(Duration(days: startOffset));

    final weeks = <List<DateTime?>>[];
    DateTime current = start;

    while (!current.isAfter(today)) {
      final week = <DateTime?>[];
      for (int d = 0; d < 7; d++) {
        final cell = current.add(Duration(days: d));
        week.add(cell.isAfter(today) ? null : cell);
      }
      weeks.add(week);
      current = current.add(const Duration(days: 7));
    }

    return weeks;
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Меньше',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white38,
                fontSize: 10,
              ),
        ),
        const SizedBox(width: 4),
        ...List.generate(5, (i) {
          final ratio = i / 4;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: i == 0
                    ? Colors.white.withOpacity(0.07)
                    : Color.lerp(
                        baseColor.withOpacity(0.3),
                        baseColor,
                        ratio,
                      ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
        const SizedBox(width: 4),
        Text(
          'Больше',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white38,
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}

// ─── Вариант для конкретной привычки ─────────────────────────────────────────

class SingleHabitHeatmap extends StatelessWidget {
  final Map<DateTime, int> data;
  final Color color;
  final String habitTitle;

  const SingleHabitHeatmap({
    super.key,
    required this.data,
    required this.color,
    required this.habitTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: HabitHeatmap(
        data: data,
        baseColor: color,
        maxValue: 1,
        title: habitTitle,
      ),
    );
  }
}
