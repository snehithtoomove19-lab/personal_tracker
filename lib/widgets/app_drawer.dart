import 'package:flutter/material.dart';
import '../services/app_scope.dart';
import '../screens/reports_screen.dart';
import '../screens/budgets_screen.dart';
import '../screens/notes_screen.dart';
import '../screens/goals_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/reminders_screen.dart';
import '../screens/monthly_review_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/search_screen.dart';
import '../screens/sms_import_screen.dart';
import '../screens/ai_chat_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    Widget item(IconData icon, String label, Widget screen) {
      return ListTile(
        leading: Icon(icon),
        title: Text(label),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
      );
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DrawerHeader(
              child: Row(
                children: [
                  const CircleAvatar(radius: 28, child: Icon(Icons.person, size: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hi, ${app.userName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        if (app.streak > 0) ...[
                          const SizedBox(height: 4),
                          Text('${app.streak} day streak', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  item(Icons.auto_awesome, 'Ask AI', const AiChatScreen()),
                  item(Icons.search, 'Search Everything', const SearchScreen()),
                  item(Icons.bar_chart, 'Reports', const ReportsScreen()),
                  item(Icons.pie_chart_outline, 'Budgets', const BudgetsScreen()),
                  item(Icons.note_alt_outlined, 'Notes', const NotesScreen()),
                  item(Icons.flag_outlined, 'Goals', const GoalsScreen()),
                  item(Icons.calendar_month_outlined, 'Calendar', const CalendarScreen()),
                  item(Icons.notifications_none, 'Reminders', const RemindersScreen()),
                  item(Icons.event_available_outlined, 'Monthly Review', const MonthlyReviewScreen()),
                  item(Icons.sms_outlined, 'Add from SMS', const SmsImportScreen()),
                  const Divider(),
                  item(Icons.settings_outlined, 'Settings', const SettingsScreen()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
