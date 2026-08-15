import 'package:flutter/material.dart';
import '../services/app_scope.dart';
import '../models/mood_entry.dart';
import '../utils/formatters.dart';
import '../widgets/section_card.dart';

class MonthlyReviewScreen extends StatefulWidget {
  const MonthlyReviewScreen({super.key});
  @override
  State<MonthlyReviewScreen> createState() => _MonthlyReviewScreenState();
}

class _MonthlyReviewScreenState extends State<MonthlyReviewScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final review = app.monthlyReview(month: _month);
    final moodSummary = review['moodSummary'] as Map<String, int>;
    final topMood = moodSummary.isEmpty ? null : moodSummary.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final topMoodOption = topMood != null ? moodOptionFor(topMood.key) : null;

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Review')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 30 + bottomInset),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1))),
              Text(formatMonthYear(_month), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1))),
            ],
          ),
          const SizedBox(height: 8),
          SectionCard(
            child: Column(
              children: [
                _ReviewRow(icon: Icons.arrow_upward, color: const Color(0xFFE2574C), label: 'Total Spent', value: formatMoney(review['totalSpent'], app.currency)),
                _ReviewRow(icon: Icons.arrow_downward, color: const Color(0xFF2FB380), label: 'Total Income', value: formatMoney(review['totalIncome'], app.currency)),
                _ReviewRow(
                  icon: topMoodOption?.icon ?? Icons.sentiment_neutral,
                  color: topMoodOption?.color ?? Colors.grey,
                  label: 'Top Mood',
                  value: topMood != null ? '${topMoodOption!.label} (${topMood.value}x)' : 'No moods logged',
                ),
                _ReviewRow(icon: Icons.check_circle_outline, color: Colors.blue, label: 'Tasks Completed', value: '${review['tasksCompleted']}'),
                _ReviewRow(icon: Icons.flag_outlined, color: Colors.purple, label: 'Goals Achieved', value: '${review['goalsAchieved']}'),
                _ReviewRow(
                  icon: Icons.calendar_today_outlined,
                  color: Colors.teal,
                  label: 'Most Productive Day',
                  value: review['mostProductiveDay'] != null ? '${review['mostProductiveDay']} ${_monthName(_month)}' : '—',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(DateTime d) => formatMonthYear(d).split(' ').first;
}

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _ReviewRow({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
