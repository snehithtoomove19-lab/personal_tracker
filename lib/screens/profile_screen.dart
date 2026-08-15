import 'package:flutter/material.dart';
import '../services/app_scope.dart';
import '../utils/formatters.dart';
import '../widgets/section_card.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final savedPct = app.savingsGoal <= 0 ? 0.0 : (app.totalBalance / app.savingsGoal).clamp(0, 1).toDouble();

    final bottomPadding = MediaQuery.of(context).padding.bottom + 20;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
      children: [
        SectionCard(
          child: Row(
            children: [
              const CircleAvatar(radius: 32, child: Icon(Icons.person, size: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (app.age != null) ...[
                      const SizedBox(height: 4),
                      Text('${app.age} years old', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                    if (app.streak > 0) ...[
                      const SizedBox(height: 4),
                      Text('${app.streak}-day streak', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editName(context, app)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Birthday',
          trailing: TextButton(onPressed: () => _editBirthday(context, app), child: const Text('Edit')),
          child: app.birthday == null
              ? Text('Not set', style: TextStyle(color: Colors.grey.shade600))
              : Row(
                  children: [
                    const Icon(Icons.cake_outlined, size: 20),
                    const SizedBox(width: 10),
                    Text(formatDate(app.birthday!)),
                    if (app.age != null) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${app.age} yrs', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Monthly Savings Goal',
          trailing: TextButton(onPressed: () => _editSavings(context, app), child: const Text('Edit')),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(app.savingsGoal > 0 ? formatMoney(app.savingsGoal, app.currency) : 'Not set'),
              if (app.savingsGoal > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: savedPct, minHeight: 10)),
                const SizedBox(height: 4),
                Text('${(savedPct * 100).toStringAsFixed(0)}% of goal (based on balance)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Builder(builder: (context) {
                  final months = app.monthsToReachSavingsGoal;
                  if (months == null) {
                    return Text(
                      'Not enough recent income/expense history to project a timeline yet.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    );
                  }
                  if (months == 0) {
                    return const Text('Goal reached!', style: TextStyle(fontSize: 12, color: Color(0xFF2FB380), fontWeight: FontWeight.bold));
                  }
                  return Text(
                    'At your current pace, you\'ll reach this in about $months month${months == 1 ? '' : 's'}.',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  );
                }),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'App Statistics',
          child: Wrap(
            runSpacing: 14,
            children: [
              SizedBox(width: 150, child: StatTile(label: 'Transactions', value: '${app.transactions.length}')),
              SizedBox(width: 150, child: StatTile(label: 'Tasks', value: '${app.tasks.length}')),
              SizedBox(width: 150, child: StatTile(label: 'Notes', value: '${app.notes.length}')),
              SizedBox(width: 150, child: StatTile(label: 'Goals', value: '${app.goals.length}')),
              SizedBox(width: 150, child: StatTile(label: 'Mood Logs', value: '${app.moods.length}')),
              SizedBox(width: 150, child: StatTile(label: 'Completed Goals', value: '${app.goals.where((g) => g.completed).length}')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ),
      ],
    );
  }

  void _editName(BuildContext context, app) {
    final ctrl = TextEditingController(text: app.userName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) app.setUserName(ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editBirthday(BuildContext context, app) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: app.birthday ?? DateTime(DateTime.now().year - 20),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: 'Select your birthday',
    );
    if (picked != null) app.setBirthday(picked);
  }

  void _editSavings(BuildContext context, app) {
    final ctrl = TextEditingController(text: app.savingsGoal > 0 ? app.savingsGoal.toString() : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Monthly Savings Goal'),
        content: TextField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null) app.setSavingsGoal(v);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
