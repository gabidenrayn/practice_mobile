import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';

class AddHabitScreen extends StatefulWidget {
  final Habit? habit; // null = create, non-null = edit

  const AddHabitScreen({super.key, this.habit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late HabitCategory _category;
  late HabitFrequency _frequency;
  late String _colorHex;
  late String _iconName;

  bool get isEditing => widget.habit != null;

  final _icons = [
    'star',
    'water_drop',
    'self_improvement',
    'fitness_center',
    'menu_book',
    'code',
    'music_note',
    'brush',
    'directions_run',
    'bedtime',
    'restaurant',
    'favorite',
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.habit?.title ?? '');
    _descCtrl = TextEditingController(text: widget.habit?.description ?? '');
    _category = widget.habit?.category ?? HabitCategory.custom;
    _frequency = widget.habit?.frequency ?? HabitFrequency.daily;
    _colorHex = widget.habit?.colorHex ?? '#6C63FF';
    _iconName = widget.habit?.iconName ?? 'star';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, введите название привычки')),
      );
      return;
    }
    final provider = context.read<HabitProvider>();
    if (isEditing) {
      provider.updateHabit(
        widget.habit!.id,
        title: _titleCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        category: _category,
        frequency: _frequency,
        colorHex: _colorHex,
        iconName: _iconName,
      );
    } else {
      provider.addHabit(
        title: _titleCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        category: _category,
        frequency: _frequency,
        colorHex: _colorHex,
        iconName: _iconName,
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Изменить привычку' : 'Новая привычка'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Сохранить',
              style: TextStyle(
                color: AppTheme.fromHex(_colorHex),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PreviewCard(
              title: _titleCtrl.text.isEmpty
                  ? 'Предпросмотр привычки'
                  : _titleCtrl.text,
              colorHex: _colorHex,
              iconName: _iconName,
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Название'),
            TextField(
              controller: _titleCtrl,
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration('например, Утренняя медитация'),
            ),
            const SizedBox(height: 16),
            const _SectionLabel('Описание (необязательно)'),
            TextField(
              controller: _descCtrl,
              decoration: _inputDecoration('Добавьте заметку...'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Иконка'),
            _IconPicker(
              selected: _iconName,
              icons: _icons,
              color: AppTheme.fromHex(_colorHex),
              onSelected: (i) => setState(() => _iconName = i),
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Цвет'),
            _ColorPicker(
              selected: _colorHex,
              onSelected: (c) => setState(() => _colorHex = c),
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Категория'),
            _CategoryPicker(
              selected: _category,
              color: AppTheme.fromHex(_colorHex),
              onSelected: (c) => setState(() => _category = c),
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Частота'),
            _FrequencyPicker(
              selected: _frequency,
              color: AppTheme.fromHex(_colorHex),
              onSelected: (f) => setState(() => _frequency = f),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      );
}

class _PreviewCard extends StatelessWidget {
  final String title;
  final String colorHex;
  final String iconName;

  const _PreviewCard({
    required this.title,
    required this.colorHex,
    required this.iconName,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.fromHex(colorHex);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(_iconData(iconName), color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconPicker extends StatelessWidget {
  final String selected;
  final List<String> icons;
  final Color color;
  final ValueChanged<String> onSelected;

  const _IconPicker({
    required this.selected,
    required this.icons,
    required this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: icons.map((name) {
        final isSelected = name == selected;
        return GestureDetector(
          onTap: () => onSelected(name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.2) : AppTheme.card,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              _iconData(name),
              color: isSelected ? color : AppTheme.textSecondary,
              size: 22,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _ColorPicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final hexList = AppTheme.habitColors
        .map((c) => '#${c.value.toRadixString(16).substring(2).toUpperCase()}')
        .toList();
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: hexList.map((hex) {
        final isSelected = hex == selected;
        return GestureDetector(
          onTap: () => onSelected(hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.fromHex(hex),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: AppTheme.fromHex(hex).withOpacity(0.5),
                          blurRadius: 8)
                    ]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final HabitCategory selected;
  final Color color;
  final ValueChanged<HabitCategory> onSelected;

  const _CategoryPicker({
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: HabitCategory.values.map((cat) {
        final isSelected = cat == selected;
        return ChoiceChip(
          label: Text(_catLabel(cat)),
          selected: isSelected,
          selectedColor: color.withOpacity(0.2),
          onSelected: (_) => onSelected(cat),
          side: BorderSide(
            color: isSelected ? color : Colors.transparent,
          ),
        );
      }).toList(),
    );
  }
}

class _FrequencyPicker extends StatelessWidget {
  final HabitFrequency selected;
  final Color color;
  final ValueChanged<HabitFrequency> onSelected;

  const _FrequencyPicker({
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: HabitFrequency.values.map((f) {
        final isSelected = f == selected;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.2) : AppTheme.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? color : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    f == HabitFrequency.daily ? 'Ежедневно' : 'Еженедельно',
                    style: TextStyle(
                      color: isSelected ? color : AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
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

String _catLabel(HabitCategory cat) {
  switch (cat) {
    case HabitCategory.health:
      return '🏥 Здоровье';
    case HabitCategory.productivity:
      return '⚡ Продуктивность';
    case HabitCategory.mindfulness:
      return '🧘 Осознанность';
    case HabitCategory.fitness:
      return '💪 Фитнес';
    case HabitCategory.learning:
      return '📚 Обучение';
    case HabitCategory.custom:
      return '✨ Другое';
  }
}
