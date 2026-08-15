import 'package:flutter/material.dart';
import '../services/app_scope.dart';
import '../models/mood_entry.dart';
import '../utils/formatters.dart';
import '../widgets/section_card.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});
  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final todayMood = app.todayMood;
    final summary = app.monthMoodSummary(month: _visibleMonth);
    final totalLogged = summary.values.fold(0, (p, e) => p + e);
    final missedDays = app.missedMoodDaysThisMonth;

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 30 + bottomInset),
      children: [
        if (missedDays.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              color: Colors.orange.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Colors.orange.shade800),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${missedDays.length} day${missedDays.length == 1 ? '' : 's'} this month ${missedDays.length == 1 ? 'has' : 'have'} no mood logged',
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange.shade800, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap any day below in the calendar to fill it in — keeps your monthly summary accurate.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        SectionCard(
          title: "How are you feeling today?",
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: kMoodOptions.map((m) {
              final selected = todayMood?.mood == m.key;
              return GestureDetector(
                onTap: () => _logMood(context, m.key, DateTime.now()),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? m.color.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? m.color : Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(m.icon, size: 28, color: m.color),
                      const SizedBox(height: 4),
                      Text(m.label, style: TextStyle(fontSize: 11, color: m.color)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: formatMonthYear(_visibleMonth),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1)),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1)),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Tap a day to log or edit its mood', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ),
              _MoodCalendarGrid(
                month: _visibleMonth,
                app: app,
                onDayTap: (date) => _pickMoodForDay(context, date),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Monthly Summary',
          child: totalLogged == 0
              ? Text('No moods logged this month yet.', style: TextStyle(color: Colors.grey.shade600))
              : Column(
                  children: summary.entries.map((e) {
                    final option = moodOptionFor(e.key);
                    final pct = e.value / totalLogged;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(option.icon, size: 20, color: option.color),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(value: pct, minHeight: 10, color: option.color, backgroundColor: option.color.withValues(alpha: 0.12)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('${e.value}'),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  /// Opens a small mood-picker for [date] first (used when tapping a
  /// calendar day), then hands off to the note sheet once a mood is chosen.
  void _pickMoodForDay(BuildContext context, DateTime date) {
    final now = DateTime.now();
    if (date.isAfter(DateTime(now.year, now.month, now.day))) return; // no logging future days

    final app = AppScope.of(context);
    final existing = app.moodForDay(date);

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSameDay(date, now) ? 'Today' : formatDate(date),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: kMoodOptions.map((m) {
                  final selected = existing?.mood == m.key;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _logMood(context, m.key, date);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? m.color.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? m.color : Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(m.icon, size: 26, color: m.color),
                          const SizedBox(height: 4),
                          Text(m.label, style: TextStyle(fontSize: 10, color: m.color)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logMood(BuildContext context, String key, DateTime date) {
    final app = AppScope.of(context);
    final existing = app.moodForDay(date);
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    final option = moodOptionFor(key);
    final isToday = _isSameDay(date, DateTime.now());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(option.icon, color: option.color, size: 26),
                const SizedBox(width: 8),
                Text(
                  '${isToday ? 'Today' : formatDate(date)}: ${option.label}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Add a short note (optional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  app.upsertMood(MoodEntry(
                    id: existing?.id ?? app.newId(),
                    date: date,
                    mood: key,
                    note: noteCtrl.text.trim(),
                  ));
                  Navigator.pop(ctx);
                },
                child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Save')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodCalendarGrid extends StatelessWidget {
  final DateTime month;
  final dynamic app;
  final void Function(DateTime date) onDayTap;
  const _MoodCalendarGrid({required this.month, required this.app, required this.onDayTap});

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday % 7; // Sunday-start grid
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final cells = <Widget>[];
    for (int i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final mood = app.moodForDay(date);
      final option = mood != null ? moodOptionFor(mood.mood) : null;
      final isFuture = date.isAfter(todayOnly);
      final isToday = date.isAtSameMomentAs(todayOnly);

      cells.add(GestureDetector(
        onTap: isFuture ? null : () => onDayTap(date),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: isToday ? Border.all(color: Theme.of(context).colorScheme.primary) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$day', style: TextStyle(fontSize: 10, color: isFuture ? Colors.grey.shade300 : Colors.grey.shade500)),
              option != null
                  ? Icon(option.icon, size: 16, color: option.color)
                  : Icon(Icons.circle_outlined, size: 10, color: isFuture ? Colors.grey.shade200 : Colors.grey.shade400),
            ],
          ),
        ),
      ));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }
}
