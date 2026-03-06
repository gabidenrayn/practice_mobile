import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';
import '../screens/add_habit_screen.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;

  const HabitCard({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.fromHex(habit.colorHex);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddHabitScreen(habit: habit),
                ),
              ),
              backgroundColor: const Color(0xFF45B7D1),
              foregroundColor: Colors.white,
              icon: Icons.edit_rounded,
              label: 'Изменить',
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(20)),
            ),
            SlidableAction(
              onPressed: (_) => _confirmArchive(context),
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              icon: Icons.archive_rounded,
              label: 'В архив',
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(20)),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () => _toggle(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: habit.isCompletedToday
                  ? color.withOpacity(0.15)
                  : AppTheme.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: habit.isCompletedToday
                    ? color.withOpacity(0.4)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                _CheckButton(
                  isCompleted: habit.isCompletedToday,
                  color: color,
                  onTap: () => _toggle(context),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: habit.isCompletedToday
                              ? AppTheme.textSecondary
                              : AppTheme.textPrimary,
                          decoration: habit.isCompletedToday
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (habit.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          habit.description!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _StreakBadge(streak: habit.currentStreak, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggle(BuildContext context) {
    HapticFeedback.lightImpact();
    context.read<HabitProvider>().toggleCompletion(habit.id);
  }

  void _confirmArchive(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Архивировать привычку?'),
        content: Text('"${habit.title}" будет в архиве. Статистика останется.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отменить'),
          ),
          TextButton(
            onPressed: () {
              context.read<HabitProvider>().archiveHabit(habit.id);
              Navigator.pop(context);
            },
            child: const Text('Архивировать',
                style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  final bool isCompleted;
  final Color color;
  final VoidCallback onTap;

  const _CheckButton({
    required this.isCompleted,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isCompleted ? color : color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isCompleted ? Icons.check_rounded : Icons.add_rounded,
          color: isCompleted ? Colors.white : color,
          size: 22,
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  final Color color;

  const _StreakBadge({required this.streak, required this.color});

  @override
  Widget build(BuildContext context) {
    if (streak == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '🔥 $streak',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
