import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/add_transaction_screen.dart';
import '../screens/add_task_screen.dart';
import '../screens/add_note_screen.dart';
import '../screens/add_goal_screen.dart';
import '../models/transaction.dart';
import '../services/app_scope.dart';

void showQuickAddSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (ctx) {
      final app = AppScope.of(ctx);

      Widget option(
        IconData icon,
        String label,
        Color color,
        VoidCallback onTap,
      ) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          title: Text(label),
          onTap: () {
            Navigator.pop(ctx);
            onTap();
          },
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              // Title
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Quick Add',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              // Add Expense
              option(
                Icons.remove_circle_outline,
                'Add Expense',
                Colors.redAccent,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddTransactionScreen(
                        type: TxType.expense,
                      ),
                    ),
                  );
                },
              ),

              // Add Income
              option(
                Icons.add_circle_outline,
                'Add Income',
                Colors.green,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddTransactionScreen(
                        type: TxType.income,
                      ),
                    ),
                  );
                },
              ),

              // Add Task
              option(
                Icons.check_circle_outline,
                'Add Task',
                Colors.blue,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddTaskScreen(),
                    ),
                  );
                },
              ),

              // Add Note
              option(
                Icons.note_add_outlined,
                'Add Note',
                Colors.orange,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddNoteScreen(),
                    ),
                  );
                },
              ),

              // Add Goal
              option(
                Icons.flag_outlined,
                'Add Goal',
                Colors.purple,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddGoalScreen(),
                    ),
                  );
                },
              ),

              // GitHub
              option(
                Icons.code,
                'GitHub',
                Colors.black,
                () async {
                  final url = Uri.parse(
                    'https://github.com/YOUR_USERNAME',
                  );

                  if (await canLaunchUrl(url)) {
                    await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
              ),

              const Divider(height: 20),

              // Dark Mode
              SwitchListTile(
                secondary: Icon(
                  app.darkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: Colors.indigo,
                ),
                title: const Text('Dark Mode'),
                value: app.darkMode,
                onChanged: (v) {
                  app.setDarkMode(v);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}