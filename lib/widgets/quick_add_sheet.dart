import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/add_transaction_screen.dart';
import '../screens/add_task_screen.dart';
import '../screens/add_note_screen.dart';
import '../screens/add_goal_screen.dart';
import '../screens/settings_screen.dart';
import '../models/transaction.dart';
import '../services/app_scope.dart';

void showQuickAddSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
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
          dense: true,
          leading: CircleAvatar(
            radius: 20,
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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
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
                    padding: EdgeInsets.only(bottom: 4),
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
                    () {
                      const githubUrl =
                          'https://github.com/snehithtoomove19-lab';

                      showDialog(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title: const Row(
                              children: [
                                Icon(
                                  Icons.code,
                                  color: Colors.black,
                                ),
                                SizedBox(width: 10),
                                Text('GitHub'),
                              ],
                            ),
                            content: SelectableText(
                              githubUrl,
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            actions: [
                              // Copy Link
                              TextButton(
                                onPressed: () {
                                  Clipboard.setData(
                                    const ClipboardData(
                                      text: githubUrl,
                                    ),
                                  );

                                  Navigator.pop(dialogContext);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'GitHub link copied!',
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Copy Link'),
                              ),

                              // Open GitHub
                              ElevatedButton(
                                onPressed: () async {
                                  final url = Uri.parse(githubUrl);

                                  try {
                                    final opened = await launchUrl(
                                      url,
                                      mode: LaunchMode.externalApplication,
                                    );

                                    if (!opened && context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Could not open GitHub',
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Could not open GitHub',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Open GitHub'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                  // Settings
                  option(
                    Icons.settings_outlined,
                    'Settings',
                    Colors.grey,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 12),

                  // Dark Mode
                  SwitchListTile(
                    dense: true,
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
          ),
        ),
      );
    },
  );
}