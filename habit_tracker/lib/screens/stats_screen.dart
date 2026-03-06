import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../models/habit.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, provider, _) {
        final habits = provider.habits;
        return CustomScrollView(
          slivers: [
            const SliverSafeArea(
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Text(
                    'Статистика',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _OverallStats(provider: provider),
            ),
            if (habits.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(
                    'Детали привычек',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _HabitStatCard(habit: habits[index]),
                    childCount: habits.length,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _OverallStats extends StatelessWidget {
  final HabitProvider provider;

  const _OverallStats({required this.provider});

  @override
  Widget build(BuildContext context) {
    final habits = provider.habits;
    final totalCompletions =
        habits.fold<int>(0, (sum, h) => sum + h.completedDates.length);
    final avgRate = habits.isEmpty
        ? 0.0
        : habits.fold<double>(0, (sum, h) => sum + h.completionRate30Days) /
            habits.length;
    final bestStreak = habits.isEmpty
        ? 0
        : habits.map((h) => h.bestStreak).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          _StatTile(
            label: 'Всего\nвыполнений',
            value: '$totalCompletions',
            icon: Icons.check_circle_rounded,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 12),
          _StatTile(
            label: '30-дн.\nср. %',
            value: '${(avgRate * 100).toStringAsFixed(0)}%',
            icon: Icons.trending_up_rounded,
            color: const Color(0xFF4ECDC4),
          ),
          const SizedBox(width: 12),
          _StatTile(
            label: 'Лучший\nстрик',
            value: '$bestStreak 🔥',
            icon: Icons.local_fire_department_rounded,
            color: const Color(0xFFFF6B35),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitStatCard extends StatelessWidget {
  final Habit habit;

  const _HabitStatCard({required this.habit});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.fromHex(habit.colorHex);
    final rate = habit.completionRate30Days;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconData(habit.iconName), color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  habit.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                '${(rate * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 30-day heatmap strip
          _HeatmapStrip(habit: habit, color: color),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat('🔥 Текущий', '${habit.currentStreak} дней'),
              const SizedBox(width: 16),
              _MiniStat('⭐ Лучший', '${habit.bestStreak} дней'),
              const SizedBox(width: 16),
              _MiniStat('✅ Всего', '${habit.completedDates.length}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatmapStrip extends StatelessWidget {
  final Habit habit;
  final Color color;

  const _HeatmapStrip({required this.habit, required this.color});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Row(
      children: List.generate(30, (i) {
        final day = now.subtract(Duration(days: 29 - i));
        final done = habit.isCompletedOn(day);
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            height: 8,
            decoration: BoxDecoration(
              color: done ? color : color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat(this.label, this.value);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
        ],
      );
}

IconData _iconData(String name) {
  const map = {
    'star': Icons.star_rounded,
    'water_drop': Icons.water_drop_rounded,
    'self_improvement': Icons.self_improvement_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'menu_book': Icons.menu_book_rounded,
    'code': Icons.code_rounded,
    'music_note': Icons.music_note_rounded,
    'brush': Icons.brush_rounded,
    'directions_run': Icons.directions_run_rounded,
    'bedtime': Icons.bedtime_rounded,
    'restaurant': Icons.restaurant_rounded,
    'favorite': Icons.favorite_rounded,
  };
  return map[name] ?? Icons.star_rounded;
}
