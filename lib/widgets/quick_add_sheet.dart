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
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final app = AppScope.of(ctx);

      return SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 30,
                spreadRadius: 5,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ------------------------------------------------------
                  // HANDLE
                  // ------------------------------------------------------

                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ------------------------------------------------------
                  // HEADER
                  // ------------------------------------------------------

                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Colors.indigo,
                              Colors.deepPurple,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Add',
                              style: Theme.of(ctx)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Track something in seconds',
                              style: Theme.of(ctx)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------------------
                  // MONEY
                  // ------------------------------------------------------

                  _sectionTitle(
                    context: ctx,
                    title: 'Money',
                    icon: Icons.account_balance_wallet_outlined,
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _quickCard(
                          context: ctx,
                          icon: Icons.remove_circle_outline,
                          title: 'Expense',
                          subtitle: 'Add spending',
                          color: Colors.redAccent,
                          onTap: () {
                            Navigator.pop(ctx);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AddTransactionScreen(
                                  type: TxType.expense,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _quickCard(
                          context: ctx,
                          icon: Icons.add_circle_outline,
                          title: 'Income',
                          subtitle: 'Add earnings',
                          color: Colors.green,
                          onTap: () {
                            Navigator.pop(ctx);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AddTransactionScreen(
                                  type: TxType.income,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ------------------------------------------------------
                  // PRODUCTIVITY
                  // ------------------------------------------------------

                  _sectionTitle(
                    context: ctx,
                    title: 'Productivity',
                    icon: Icons.auto_awesome_outlined,
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _quickCard(
                          context: ctx,
                          icon: Icons.check_circle_outline,
                          title: 'Task',
                          subtitle: 'Stay organized',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.pop(ctx);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddTaskScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _quickCard(
                          context: ctx,
                          icon: Icons.note_add_outlined,
                          title: 'Note',
                          subtitle: 'Save an idea',
                          color: Colors.orange,
                          onTap: () {
                            Navigator.pop(ctx);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddNoteScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _quickCard(
                          context: ctx,
                          icon: Icons.flag_outlined,
                          title: 'Goal',
                          subtitle: 'Set a target',
                          color: Colors.purple,
                          onTap: () {
                            Navigator.pop(ctx);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddGoalScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ------------------------------------------------------
                  // LIFESTYLE
                  // ------------------------------------------------------

                  _sectionTitle(
                    context: ctx,
                    title: 'Lifestyle',
                    icon: Icons.favorite_outline,
                  ),

                  const SizedBox(height: 10),

                  // GYM
                  _largeLifestyleCard(
                    context: ctx,
                    icon: Icons.fitness_center_rounded,
                    title: 'Gym',
                    subtitle: 'Track your workout',
                    color: Colors.deepOrange,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showGymDialog(context);
                    },
                  ),

                  const SizedBox(height: 12),

                  // SLEEP
                  _largeLifestyleCard(
                    context: ctx,
                    icon: Icons.bedtime_rounded,
                    title: 'Sleep',
                    subtitle: 'Track your sleep & recovery',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showSleepDialog(context);
                    },
                  ),

                  const SizedBox(height: 12),

                  // COOK
                  _largeLifestyleCard(
                    context: ctx,
                    icon: Icons.restaurant_rounded,
                    title: 'Cook',
                    subtitle: 'Track meals you prepare',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showCookDialog(context);
                    },
                  ),

                  const SizedBox(height: 22),

                  // ------------------------------------------------------
                  // TOOLS
                  // ------------------------------------------------------

                  _sectionTitle(
                    context: ctx,
                    title: 'Tools',
                    icon: Icons.tune_rounded,
                  ),

                  const SizedBox(height: 10),

                  // GitHub
                  _toolTile(
                    context: ctx,
                    icon: Icons.code_rounded,
                    title: 'GitHub',
                    subtitle: 'Open your GitHub profile',
                    color: Colors.black,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showGitHubDialog(context);
                    },
                  ),

                  const SizedBox(height: 8),

                  // Settings
                  _toolTile(
                    context: ctx,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'Manage your app',
                    color: Colors.grey,
                    onTap: () {
                      Navigator.pop(ctx);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  // ------------------------------------------------------
                  // DARK MODE
                  // ------------------------------------------------------

                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(ctx)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      secondary: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          app.darkMode
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: Colors.indigo,
                        ),
                      ),
                      title: const Text(
                        'Dark Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        app.darkMode ? 'Enabled' : 'Disabled',
                      ),
                      value: app.darkMode,
                      onChanged: (value) {
                        app.setDarkMode(value);
                      },
                    ),
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

// ============================================================================
// SECTION TITLE
// ============================================================================

Widget _sectionTitle({
  required BuildContext context,
  required String title,
  required IconData icon,
}) {
  return Row(
    children: [
      Icon(
        icon,
        size: 18,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(width: 7),
      Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
      ),
    ],
  );
}

// ============================================================================
// QUICK CARD
// ============================================================================

Widget _quickCard({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 21,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ============================================================================
// LIFESTYLE CARD
// ============================================================================

Widget _largeLifestyleCard({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.17),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 27,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: color,
            ),
          ],
        ),
      ),
    ),
  );
}

// ============================================================================
// TOOL TILE
// ============================================================================

Widget _toolTile({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    ),
  );
}

// ============================================================================
// GYM
// ============================================================================

void _showGymDialog(BuildContext context) {
  final workoutController = TextEditingController();
  final durationController = TextEditingController();
  final caloriesController = TextEditingController();

  String selectedWorkout = 'Strength';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dialogHeader(
                      context: context,
                      icon: Icons.fitness_center_rounded,
                      title: 'Gym',
                      subtitle: 'Track your workout',
                      color: Colors.deepOrange,
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'Workout type',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Strength',
                        'Cardio',
                        'Running',
                        'Walking',
                        'Yoga',
                        'Other',
                      ].map((type) {
                        final selected = selectedWorkout == type;

                        return ChoiceChip(
                          label: Text(type),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              selectedWorkout = type;
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 18),

                    _inputField(
                      controller: workoutController,
                      label: 'Workout name',
                      hint: 'e.g. Chest & Triceps',
                      icon: Icons.edit_outlined,
                    ),

                    const SizedBox(height: 12),

                    _inputField(
                      controller: durationController,
                      label: 'Duration',
                      hint: 'Minutes',
                      icon: Icons.timer_outlined,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 12),

                    _inputField(
                      controller: caloriesController,
                      label: 'Calories',
                      hint: 'Optional',
                      icon: Icons.local_fire_department_outlined,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 22),

                    _saveButton(
                      context: context,
                      label: 'Save Workout',
                      icon: Icons.check_rounded,
                      color: Colors.deepOrange,
                      onPressed: () {
                        Navigator.pop(dialogContext);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '🏋️ $selectedWorkout workout added',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// ============================================================================
// SLEEP
// ============================================================================

void _showSleepDialog(BuildContext context) {
  TimeOfDay? sleepTime;
  TimeOfDay? wakeTime;
  String quality = 'Good';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dialogHeader(
                      context: context,
                      icon: Icons.bedtime_rounded,
                      title: 'Sleep',
                      subtitle: 'Track your sleep & recovery',
                      color: Colors.indigo,
                    ),

                    const SizedBox(height: 22),

                    _timeButton(
                      context: context,
                      icon: Icons.nightlight_round,
                      title: 'Bedtime',
                      value: sleepTime == null
                          ? 'Select bedtime'
                          : sleepTime!.format(context),
                      color: Colors.indigo,
                      onTap: () async {
                        final selected = await showTimePicker(
                          context: context,
                          initialTime: sleepTime ?? TimeOfDay.now(),
                        );

                        if (selected != null) {
                          setState(() {
                            sleepTime = selected;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    _timeButton(
                      context: context,
                      icon: Icons.wb_sunny_outlined,
                      title: 'Wake-up',
                      value: wakeTime == null
                          ? 'Select wake-up time'
                          : wakeTime!.format(context),
                      color: Colors.orange,
                      onTap: () async {
                        final selected = await showTimePicker(
                          context: context,
                          initialTime: wakeTime ?? TimeOfDay.now(),
                        );

                        if (selected != null) {
                          setState(() {
                            wakeTime = selected;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Sleep quality',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      children: [
                        'Poor',
                        'Okay',
                        'Good',
                        'Great',
                      ].map((value) {
                        return ChoiceChip(
                          label: Text(value),
                          selected: quality == value,
                          onSelected: (_) {
                            setState(() {
                              quality = value;
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 22),

                    _saveButton(
                      context: context,
                      label: 'Save Sleep',
                      icon: Icons.bedtime_rounded,
                      color: Colors.indigo,
                      onPressed: () {
                        Navigator.pop(dialogContext);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '😴 Sleep recorded • Quality: $quality',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// ============================================================================
// COOK
// ============================================================================

void _showCookDialog(BuildContext context) {
  final mealController = TextEditingController();
  final durationController = TextEditingController();

  String mealType = 'Dinner';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dialogHeader(
                      context: context,
                      icon: Icons.restaurant_rounded,
                      title: 'Cook',
                      subtitle: 'Track meals you prepare',
                      color: Colors.teal,
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'Meal',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Breakfast',
                        'Lunch',
                        'Dinner',
                        'Meal Prep',
                      ].map((type) {
                        return ChoiceChip(
                          label: Text(type),
                          selected: mealType == type,
                          onSelected: (_) {
                            setState(() {
                              mealType = type;
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 18),

                    _inputField(
                      controller: mealController,
                      label: 'What did you cook?',
                      hint: 'e.g. Chicken rice',
                      icon: Icons.restaurant_menu_outlined,
                    ),

                    const SizedBox(height: 12),

                    _inputField(
                      controller: durationController,
                      label: 'Cooking time',
                      hint: 'Minutes',
                      icon: Icons.timer_outlined,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 22),

                    _saveButton(
                      context: context,
                      label: 'Save Meal',
                      icon: Icons.restaurant_rounded,
                      color: Colors.teal,
                      onPressed: () {
                        Navigator.pop(dialogContext);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '🍳 $mealType added',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// ============================================================================
// GITHUB
// ============================================================================

void _showGitHubDialog(BuildContext context) {
  const githubUrl = 'https://github.com/snehithtoomove19-lab';

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.code_rounded,
              color: Colors.black,
            ),
            SizedBox(width: 10),
            Text('GitHub'),
          ],
        ),
        content: const SelectableText(
          githubUrl,
          style: TextStyle(
            fontSize: 14,
          ),
        ),
        actions: [
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
          ElevatedButton(
            onPressed: () async {
              final url = Uri.parse(githubUrl);

              try {
                final opened = await launchUrl(
                  url,
                  mode: LaunchMode.externalApplication,
                );

                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not open GitHub',
                      ),
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
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
}

// ============================================================================
// DIALOG HEADER
// ============================================================================

Widget _dialogHeader({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
}) {
  return Row(
    children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: color,
          size: 28,
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// ============================================================================
// INPUT FIELD
// ============================================================================

Widget _inputField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  TextInputType? keyboardType,
}) {
  return TextField(
    controller: controller,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          width: 2,
        ),
      ),
    ),
  );
}

// ============================================================================
// TIME BUTTON
// ============================================================================

Widget _timeButton({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String value,
  required Color color,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: color.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color,
            ),
          ],
        ),
      ),
    ),
  );
}

// ============================================================================
// SAVE BUTTON
// ============================================================================

Widget _saveButton({
  required BuildContext context,
  required String label,
  required IconData icon,
  required Color color,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  );
}