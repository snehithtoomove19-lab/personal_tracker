import 'package:flutter/material.dart';
import '../services/app_scope.dart';
import '../utils/formatters.dart';
import '../models/transaction.dart';
import '../models/mood_entry.dart';
import '../widgets/section_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selected = DateTime.now();

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday % 7;

    final dayTx =
        app.transactions.where((t) => _sameDay(t.date, _selected)).toList();
    final dayTasks = app.tasks
        .where((t) => t.dueDate != null && _sameDay(t.dueDate!, _selected))
        .toList();
    final dayMood = app.moodForDay(_selected);
    final dayGoals = app.goals
        .where(
            (g) => g.targetDate != null && _sameDay(g.targetDate!, _selected))
        .toList();
    final dayNotes =
        app.notes.where((n) => _sameDay(n.createdAt, _selected)).toList();

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 30 + bottomInset),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1))),
              Text(formatMonthYear(_month),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month + 1))),
            ],
          ),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (int i = 0; i < leadingBlanks; i++) const SizedBox(),
              for (int day = 1; day <= daysInMonth; day++)
                _buildDayCell(context, app, day),
            ],
          ),
          const SizedBox(height: 12),
          Text(formatDate(_selected),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          if (dayMood != null)
            SectionCard(
              title: 'Mood',
              child: Row(
                children: [
                  Icon(moodOptionFor(dayMood.mood).icon,
                      color: moodOptionFor(dayMood.mood).color),
                  const SizedBox(width: 8),
                  Text('${moodOptionFor(dayMood.mood).label} ${dayMood.note}'),
                ],
              ),
            ),
          if (dayMood != null) const SizedBox(height: 10),
          SectionCard(
            title: 'Expenses & Income',
            child: dayTx.isEmpty
                ? Text('Nothing logged',
                    style: TextStyle(color: Colors.grey.shade600))
                : Column(
                    children: dayTx
                        .map((t) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(t.category),
                              subtitle: t.note.isNotEmpty ? Text(t.note) : null,
                              trailing: Text(
                                '${t.type == TxType.income ? '+' : '-'}${formatMoney(t.amount, app.currency)}',
                                style: TextStyle(
                                    color: t.type == TxType.income
                                        ? const Color(0xFF2FB380)
                                        : const Color(0xFFE2574C)),
                              ),
                            ))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 10),
          SectionCard(
            title: 'Tasks',
            child: dayTasks.isEmpty
                ? Text('No tasks due',
                    style: TextStyle(color: Colors.grey.shade600))
                : Column(
                    children: dayTasks
                        .map((t) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(t.completed
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked),
                              title: Text(t.title),
                            ))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 10),
          SectionCard(
            title: 'Goals due',
            child: dayGoals.isEmpty
                ? Text('No goals due',
                    style: TextStyle(color: Colors.grey.shade600))
                : Column(
                    children: dayGoals
                        .map((g) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(g.title),
                            trailing: Text('${g.progress}%')))
                        .toList()),
          ),
          const SizedBox(height: 10),
          SectionCard(
            title: 'Notes created',
            child: dayNotes.isEmpty
                ? Text('No notes',
                    style: TextStyle(color: Colors.grey.shade600))
                : Column(
                    children: dayNotes
                        .map((n) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(n.title)))
                        .toList()),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(BuildContext context, app, int day) {
    final date = DateTime(_month.year, _month.month, day);
    final isSelected = _sameDay(date, _selected);
    final hasTx = app.transactions.any((t) => _sameDay(t.date, date));
    final hasTask =
        app.tasks.any((t) => t.dueDate != null && _sameDay(t.dueDate!, date));
    final mood = app.moodForDay(date);

    return GestureDetector(
      onTap: () => setState(() => _selected = date),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
              : null,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: Theme.of(context).colorScheme.primary)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$day', style: const TextStyle(fontSize: 12)),
            if (mood != null)
              Icon(moodOptionFor(mood.mood).icon,
                  size: 12, color: moodOptionFor(mood.mood).color)
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasTx)
                    Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: const BoxDecoration(
                            color: Colors.redAccent, shape: BoxShape.circle)),
                  if (hasTask)
                    Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: const BoxDecoration(
                            color: Colors.blueAccent, shape: BoxShape.circle)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
