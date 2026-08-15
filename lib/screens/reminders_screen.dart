import 'package:flutter/material.dart';
import '../services/app_scope.dart';
import '../utils/formatters.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final now = DateTime.now();
    final soon = now.add(const Duration(days: 30));

    final upcomingTasks = app.tasks
        .where((t) => !t.completed && t.dueDate != null && !t.dueDate!.isBefore(DateTime(now.year, now.month, now.day)) && t.dueDate!.isBefore(soon))
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    final overdueTasks = app.overdueTasks;

    final noDateTasks = app.tasks.where((t) => !t.completed && t.dueDate == null).toList();

    final upcomingGoals = app.goals
        .where((g) => !g.completed && g.targetDate != null && !g.targetDate!.isBefore(DateTime(now.year, now.month, now.day)) && g.targetDate!.isBefore(soon))
        .toList()
      ..sort((a, b) => a.targetDate!.compareTo(b.targetDate!));

    final upcomingBirthdayContacts = app.birthdayContacts
        .where((c) => c.daysUntil(now) <= 30)
        .toList()
      ..sort((a, b) => a.daysUntil(now).compareTo(b.daysUntil(now)));

    // "Bill" reminders derived from recurring-looking expense categories (e.g. Bills)
    final billCategoryTx = app.transactions.where((t) => t.category == 'Bills').toList();

    // Recurring transactions (rent, subscriptions, etc.) show their most recent
    // occurrence so the person can see what's set to auto-repeat.
    final recurringSeries = <String, dynamic>{};
    for (final t in app.transactions.where((t) => t.repeat.name != 'none')) {
      final key = '${t.type.name}|${t.category}|${t.amount}|${t.paymentMethod}';
      if (!recurringSeries.containsKey(key) || (recurringSeries[key].date as DateTime).isBefore(t.date)) {
        recurringSeries[key] = t;
      }
    }
    final recurringList = recurringSeries.values.toList();

    Widget tile(IconData icon, String title, String subtitle, Color color) => ListTile(
          leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color)),
          title: Text(title),
          subtitle: Text(subtitle),
        );

    String taskDueLabel(dynamic t) {
      final dateStr = formatDate(t.dueDate!);
      if (t.dueTimeMinutes != null) {
        final h = t.dueTimeMinutes ~/ 60;
        final m = t.dueTimeMinutes % 60;
        final period = h >= 12 ? 'PM' : 'AM';
        final displayHour = h % 12 == 0 ? 12 : h % 12;
        return '$dateStr at $displayHour:${m.toString().padLeft(2, '0')} $period';
      }
      return dateStr;
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom + 20;

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
        children: [
          if (overdueTasks.isEmpty && upcomingTasks.isEmpty && upcomingGoals.isEmpty && noDateTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(child: Text("You're all caught up", style: TextStyle(color: Colors.grey.shade600))),
            ),
          if (overdueTasks.isNotEmpty) ...[
            const Text('Overdue Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
            Card(child: Column(children: overdueTasks.map((t) => tile(Icons.warning_amber, t.title, 'Was due ${formatDate(t.dueDate!)}', Colors.red)).toList())),
            const SizedBox(height: 16),
          ],
          if (upcomingTasks.isNotEmpty) ...[
            const Text('Upcoming Task Reminders (next 30 days)', style: TextStyle(fontWeight: FontWeight.bold)),
            Card(child: Column(children: upcomingTasks.map((t) => tile(Icons.check_circle_outline, t.title, 'Due ${taskDueLabel(t)}', Colors.blue)).toList())),
            const SizedBox(height: 16),
          ],
          if (upcomingGoals.isNotEmpty) ...[
            const Text('Upcoming Goal Reminders', style: TextStyle(fontWeight: FontWeight.bold)),
            Card(child: Column(children: upcomingGoals.map((g) => tile(Icons.flag_outlined, g.title, 'Target ${formatDate(g.targetDate!)}', Colors.purple)).toList())),
            const SizedBox(height: 16),
          ],
          if (upcomingBirthdayContacts.isNotEmpty) ...[
            const Text('Upcoming Birthdays', style: TextStyle(fontWeight: FontWeight.bold)),
            Card(
              child: Column(
                children: upcomingBirthdayContacts.map((c) {
                  final days = c.daysUntil(now);
                  final next = c.nextOccurrence(now);
                  final age = c.ageOn(next);
                  final label = days == 0
                      ? 'Today — turns $age'
                      : days == 1
                          ? 'Tomorrow — turns $age'
                          : '$days days — turns $age';
                  return tile(Icons.cake_outlined, '${c.name} • ${c.relation}', '${formatDateShort(c.date)} • $label', Colors.pink);
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (noDateTasks.isNotEmpty) ...[
            const Text('Tasks Without a Due Date', style: TextStyle(fontWeight: FontWeight.bold)),
            Card(child: Column(children: noDateTasks.map((t) => tile(Icons.radio_button_unchecked, t.title, 'No due date set — add one to get a reminder here', Colors.grey)).toList())),
            const SizedBox(height: 16),
          ],
          if (recurringList.isNotEmpty) ...[
            const Text('Recurring Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
            Card(
              child: Column(
                children: recurringList
                    .map((t) => tile(
                          Icons.autorenew,
                          '${t.category} (${t.repeat.name})',
                          'Last on ${formatDate(t.date)} · ${app.currency}${t.amount}',
                          Colors.indigo,
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (billCategoryTx.isNotEmpty) ...[
            const Text('Recent Bill Payments', style: TextStyle(fontWeight: FontWeight.bold)),
            Card(
              child: Column(
                children: billCategoryTx
                    .take(5)
                    .map((t) => tile(Icons.receipt_long, t.category, formatDate(t.date), Colors.orange))
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Reminders shown here are based on due dates. Turn on "Welcome-Back Summary" in Settings to also see a quick popup when you open the app if anything needs attention.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
