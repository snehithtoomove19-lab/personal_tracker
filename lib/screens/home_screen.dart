import 'package:flutter/material.dart';
import '../services/app_scope.dart';
import '../services/app_state.dart';
import '../models/mood_entry.dart';
import '../utils/formatters.dart';
import '../widgets/section_card.dart';
import '../widgets/quick_add_sheet.dart';
import 'tasks_screen.dart';
import 'mood_screen.dart';
import 'ai_chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final now = DateTime.now();
    final quote = kMotivationalQuotes[now.day % kMotivationalQuotes.length];

    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showQuickAddSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Quick Add'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
        children: [
          Text('Welcome back, ${app.userName}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(formatDate(now), style: TextStyle(color: Colors.grey.shade600)),
          if (app.streak > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.local_fire_department, size: 16, color: Colors.orange.shade600),
                const SizedBox(width: 4),
                Text('${app.streak}-day logging streak', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ],
          if (app.isMyBirthdayToday || app.todayBirthdayContacts.isNotEmpty) ...[
            const SizedBox(height: 12),
            SectionCard(
              title: app.isMyBirthdayToday ? 'Happy Birthday!' : 'Today’s Birthdays',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (app.isMyBirthdayToday) ...[
                    Text('Happy birthday, ${app.userName}! 🎉', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    if (app.age != null)
                      Text('You are ${app.age} years young today.', style: const TextStyle(fontSize: 13)),
                  ],
                  if (app.todayBirthdayContacts.isNotEmpty) ...[
                    if (app.isMyBirthdayToday) const SizedBox(height: 10),
                    const Text('Also celebrating today:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    ...app.todayBirthdayContacts.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${c.name} (${c.relation}) — turns ${c.ageOn(now)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          SectionCard(
            child: Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'Total Balance',
                    value: formatMoney(app.totalBalance, app.currency),
                    color: app.totalBalance >= 0 ? kIncomeColorLocal : kExpenseColorLocal,
                    icon: Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SectionCard(
                  child: StatTile(
                    label: "Today's Expense",
                    value: formatMoney(app.todayExpense, app.currency),
                    icon: Icons.today,
                    color: kExpenseColorLocal,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SectionCard(
                  child: StatTile(
                    label: "This Month",
                    value: formatMoney(app.monthExpense, app.currency),
                    icon: Icons.calendar_month,
                    color: kExpenseColorLocal,
                  ),
                ),
              ),
            ],
          ),
          if (app.monthOverMonthChangePercent != null) ...[
            const SizedBox(height: 12),
            SectionCard(
              child: Row(
                children: [
                  Icon(
                    app.monthOverMonthChangePercent! > 0 ? Icons.trending_up : Icons.trending_down,
                    color: app.monthOverMonthChangePercent! > 0 ? kExpenseColorLocal : kIncomeColorLocal,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "${app.monthOverMonthChangePercent!.abs().toStringAsFixed(0)}% "
                      "${app.monthOverMonthChangePercent! > 0 ? 'more' : 'less'} spending vs last month",
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (app.overBudgetCategories.isNotEmpty) ...[
            const SizedBox(height: 12),
            SectionCard(
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${app.overBudgetCategories.length} categor${app.overBudgetCategories.length == 1 ? 'y is' : 'ies are'} over budget this month',
                      style: const TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          SectionCard(
            title: "Today's Mood",
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoodScreen())),
              child: Row(
                children: [
                  Icon(
                    app.todayMood != null ? moodOptionFor(app.todayMood!.mood).icon : Icons.add_circle_outline,
                    size: 28,
                    color: app.todayMood != null ? moodOptionFor(app.todayMood!.mood).color : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Text(app.todayMood == null ? "Tap to log today's mood" : (app.todayMood!.note.isEmpty ? moodOptionFor(app.todayMood!.mood).label : app.todayMood!.note)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          SectionCard(
            title: 'Pending Tasks',
            trailing: TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksScreen())),
              child: const Text('See all'),
            ),
            child: _PendingTasksList(app: app),
          ),
          const SizedBox(height: 12),

          SectionCard(
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen())),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    child: Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ask AI', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Got a question? Ask anything.', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          SectionCard(
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.amber),
                const SizedBox(width: 10),
                Expanded(child: Text(quote, style: const TextStyle(fontStyle: FontStyle.italic))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const kIncomeColorLocal = Color(0xFF2FB380);
const kExpenseColorLocal = Color(0xFFE2574C);

class _PendingTasksList extends StatelessWidget {
  final AppState app;
  const _PendingTasksList({required this.app});

  @override
  Widget build(BuildContext context) {
    final pending = app.tasks.where((t) => !t.completed).take(4).toList();
    if (pending.isEmpty) {
      return Text('No pending tasks', style: TextStyle(color: Colors.grey.shade600));
    }
    return Column(
      children: pending
          .map((t) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: t.completed,
                title: Text(t.title),
                subtitle: t.dueDate != null ? Text(formatDate(t.dueDate!)) : null,
                onChanged: (_) => app.toggleTask(t.id),
              ))
          .toList(),
    );
  }
}
