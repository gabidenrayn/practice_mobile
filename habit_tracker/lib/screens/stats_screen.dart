import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../models/habit.dart';
import '../widgets/habit_heatmap.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Общая'),
            Tab(text: 'По привычкам'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OverallStatsTab(),
          _PerHabitStatsTab(),
        ],
      ),
    );
  }
}

// ─── Вкладка: Общая статистика ────────────────────────────────────────────────

class _OverallStatsTab extends StatelessWidget {
  const _OverallStatsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habits = provider.habits;

    if (habits.isEmpty) {
      return const Center(
        child: Text(
          'Нет данных\nДобавь первую привычку!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    // Общая статистика
    final totalCompleted = habits.fold<int>(
      0,
      (sum, h) => sum + h.completedDates.length,
    );
    final bestStreak = habits.fold<int>(
      0,
      (max, h) => h.bestStreak > max ? h.bestStreak : max,
    );
    final avgRate = habits.isEmpty
        ? 0.0
        : habits.fold<double>(0, (s, h) => s + h.completionRate30Days) /
            habits.length;

    // Heatmap данные
    final heatmapData = provider.getOverallHeatmapData(days: 365);
    final maxVal = habits.length > 0 ? habits.length : 1;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─ Карточки статистики ─
        _StatsRow(
          items: [
            _StatCard(
              label: 'Всего выполнено',
              value: '$totalCompleted',
              icon: Icons.check_circle_outline,
              color: const Color(0xFF4ECDC4),
            ),
            _StatCard(
              label: 'Лучший streak',
              value: '$bestStreak дн',
              icon: Icons.local_fire_department,
              color: const Color(0xFFFF6B6B),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatsRow(
          items: [
            _StatCard(
              label: 'Выполнение (30д)',
              value: '${(avgRate * 100).round()}%',
              icon: Icons.trending_up,
              color: const Color(0xFF6C63FF),
            ),
            _StatCard(
              label: 'Привычек',
              value: '${habits.length}',
              icon: Icons.list_alt,
              color: const Color(0xFFFFB347),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ─ Heatmap ─
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: HabitHeatmap(
            data: heatmapData,
            baseColor: const Color(0xFF6C63FF),
            maxValue: maxVal,
            title: 'Общая активность за год',
          ),
        ),
        const SizedBox(height: 24),

        // ─ Недельный прогресс ─
        _WeeklyProgressCard(provider: provider),
      ],
    );
  }
}

// ─── Вкладка: По привычкам ────────────────────────────────────────────────────

class _PerHabitStatsTab extends StatelessWidget {
  const _PerHabitStatsTab();

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitProvider>().habits;

    if (habits.isEmpty) {
      return const Center(
        child: Text('Нет привычек', style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: habits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) => _HabitStatCard(habit: habits[i]),
    );
  }
}

class _HabitStatCard extends StatelessWidget {
  final Habit habit;
  const _HabitStatCard({required this.habit});

  Color get _habitColor {
    try {
      final hex = habit.colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF6C63FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<HabitProvider>();
    final heatmapData = provider.getHeatmapData(habit.id, days: 365);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _habitColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _habitColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.star, color: _habitColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (habit.description != null)
                      Text(
                        habit.description!,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Мини-статистика
          Row(
            children: [
              _MiniStat(
                label: 'Серия',
                value: '${habit.currentStreak} дн',
                color: Colors.orange,
              ),
              const SizedBox(width: 12),
              _MiniStat(
                label: 'Рекорд',
                value: '${habit.bestStreak} дн',
                color: _habitColor,
              ),
              const SizedBox(width: 12),
              _MiniStat(
                label: '30 дней',
                value: '${(habit.completionRate30Days * 100).round()}%',
                color: const Color(0xFF4ECDC4),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Heatmap для конкретной привычки
          HabitHeatmap(
            data: heatmapData,
            baseColor: _habitColor,
            maxValue: 1,
            title: '',
          ),
        ],
      ),
    );
  }
}

// ─── Недельный прогресс ───────────────────────────────────────────────────────

class _WeeklyProgressCard extends StatelessWidget {
  final HabitProvider provider;
  const _WeeklyProgressCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final stats = provider.getWeeklyStats();
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Последние 7 дней',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final stat = stats[i];
              final total = (stat['total'] as int).clamp(1, 999);
              final completed = stat['completed'] as int;
              final ratio = (completed / total).clamp(0.0, 1.0);

              final date = stat['date'] as DateTime;
              final dayLabel = days[date.weekday - 1];
              final isToday = _isToday(date);

              return Column(
                children: [
                  Text(
                    '$completed',
                    style: TextStyle(
                      fontSize: 11,
                      color: completed > 0
                          ? const Color(0xFF6C63FF)
                          : Colors.white38,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        width: 32,
                        height: 80 * ratio,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              const Color(0xFF6C63FF),
                              const Color(0xFF6C63FF).withOpacity(0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          isToday ? const Color(0xFF6C63FF) : Colors.white54,
                      fontWeight:
                          isToday ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

// ─── Вспомогательные виджеты ──────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final List<Widget> items;
  const _StatsRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map(
            (w) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: w,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}
