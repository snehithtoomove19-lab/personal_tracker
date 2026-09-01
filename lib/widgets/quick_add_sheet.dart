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

// ============================================================================
// QUICK ADD SHEET
// ============================================================================

void showQuickAddSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (ctx) {
      final app = AppScope.of(ctx);
      final theme = Theme.of(ctx);
      final colors = theme.colorScheme;
      final isDark = theme.brightness == Brightness.dark;

      return SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.92,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 40,
                offset: const Offset(0, -12),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              18,
              10,
              18,
              20 + MediaQuery.of(ctx).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ============================================================
                // HANDLE
                // ============================================================

                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.onSurface.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // ============================================================
                // HERO HEADER
                // ============================================================

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.primary,
                        colors.primary.withOpacity(0.72),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withOpacity(0.22),
                        blurRadius: 22,
                        offset: const Offset(0, 9),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Add',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Capture something in seconds',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ============================================================
                // MONEY
                // ============================================================

                _sectionTitle(
                  context: ctx,
                  title: 'Money',
                  subtitle: 'Keep your finances up to date',
                  icon: Icons.account_balance_wallet_rounded,
                ),

                const SizedBox(height: 11),

                Row(
                  children: [
                    Expanded(
                      child: _quickCard(
                        context: ctx,
                        icon: Icons.arrow_downward_rounded,
                        title: 'Expense',
                        subtitle: 'Add spending',
                        color: const Color(0xFFE2574C),
                        onTap: () {
                          Navigator.pop(ctx);

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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _quickCard(
                        context: ctx,
                        icon: Icons.arrow_upward_rounded,
                        title: 'Income',
                        subtitle: 'Add earnings',
                        color: const Color(0xFF2FB380),
                        onTap: () {
                          Navigator.pop(ctx);

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
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ============================================================
                // PRODUCTIVITY
                // ============================================================

                _sectionTitle(
                  context: ctx,
                  title: 'Productivity',
                  subtitle: 'Turn ideas into progress',
                  icon: Icons.auto_awesome_rounded,
                ),

                const SizedBox(height: 11),

                Row(
                  children: [
                    Expanded(
                      child: _quickCard(
                        context: ctx,
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Task',
                        subtitle: 'Stay organized',
                        color: const Color(0xFF4285F4),
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: _quickCard(
                        context: ctx,
                        icon: Icons.note_add_outlined,
                        title: 'Note',
                        subtitle: 'Save an idea',
                        color: const Color(0xFFF59E0B),
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: _quickCard(
                        context: ctx,
                        icon: Icons.flag_outlined,
                        title: 'Goal',
                        subtitle: 'Set a target',
                        color: const Color(0xFF8B5CF6),
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

                const SizedBox(height: 24),

                // ============================================================
                // LIFESTYLE
                // ============================================================

                _sectionTitle(
                  context: ctx,
                  title: 'Lifestyle',
                  subtitle: 'Track the things that matter',
                  icon: Icons.favorite_rounded,
                ),

                const SizedBox(height: 11),

                _largeLifestyleCard(
                  context: ctx,
                  icon: Icons.fitness_center_rounded,
                  title: 'Gym',
                  subtitle: 'Track your workout & activity',
                  color: const Color(0xFFF97316),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showGymDialog(context);
                  },
                ),

                const SizedBox(height: 10),

                _largeLifestyleCard(
                  context: ctx,
                  icon: Icons.bedtime_rounded,
                  title: 'Sleep',
                  subtitle: 'Track sleep & recovery',
                  color: const Color(0xFF6366F1),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showSleepDialog(context);
                  },
                ),

                const SizedBox(height: 10),

                _largeLifestyleCard(
                  context: ctx,
                  icon: Icons.restaurant_rounded,
                  title: 'Cook',
                  subtitle: 'Track meals you prepare',
                  color: const Color(0xFF14B8A6),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showCookDialog(context);
                  },
                ),

                const SizedBox(height: 24),

                // ============================================================
                // TOOLS
                // ============================================================

                _sectionTitle(
                  context: ctx,
                  title: 'Tools',
                  subtitle: 'Useful shortcuts',
                  icon: Icons.tune_rounded,
                ),

                const SizedBox(height: 11),

                _toolTile(
                  context: ctx,
                  icon: Icons.code_rounded,
                  title: 'GitHub',
                  subtitle: 'Open your GitHub profile',
                  color: isDark ? Colors.white : Colors.black87,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showGitHubDialog(context);
                  },
                ),

                const SizedBox(height: 9),

                _toolTile(
                  context: ctx,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'Manage your app',
                  color: colors.primary,
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

                // ============================================================
                // DARK MODE
                // ============================================================

                Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant.withOpacity(
                      isDark ? 0.55 : 0.48,
                    ),
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(
                      color: colors.outline.withOpacity(0.06),
                    ),
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 3,
                    ),
                    secondary: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.11),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        app.darkMode
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: colors.primary,
                        size: 22,
                      ),
                    ),
                    title: const Text(
                      'Dark Mode',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      app.darkMode
                          ? 'Dark appearance enabled'
                          : 'Use the light appearance',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurface.withOpacity(0.55),
                      ),
                    ),
                    value: app.darkMode,
                    activeColor: colors.primary,
                    onChanged: (value) {
                      app.setDarkMode(value);
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // ============================================================
                // FOOTER
                // ============================================================

                Center(
                  child: Text(
                    'Quick Add â€¢ Personal Tracker',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                      color: colors.onSurface.withOpacity(0.30),
                    ),
                  ),
                ),
              ],
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
  required String subtitle,
  required IconData icon,
}) {
  final colors = Theme.of(context).colorScheme;

  return Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: colors.primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 19,
          color: colors.primary,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: colors.onSurface.withOpacity(0.48),
              ),
            ),
          ],
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
  final colors = Theme.of(context).colorScheme;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(19),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: color.withOpacity(0.075),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: color.withOpacity(0.13),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.20),
                    color.withOpacity(0.09),
                  ],
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: color,
                size: 21,
              ),
            ),
            const SizedBox(height: 11),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: colors.onSurface.withOpacity(0.50),
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
  final colors = Theme.of(context).colorScheme;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(21),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.14),
              color.withOpacity(0.045),
            ],
          ),
          borderRadius: BorderRadius.circular(21),
          border: Border.all(
            color: color.withOpacity(0.14),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 51,
              height: 51,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.20),
                    color.withOpacity(0.09),
                  ],
                ),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurface.withOpacity(0.52),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 17,
                color: color,
              ),
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
  final colors = Theme.of(context).colorScheme;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceVariant.withOpacity(0.46),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.outline.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: color.withOpacity(0.09),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: color,
                size: 21,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: colors.onSurface.withOpacity(0.48),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.onSurface.withOpacity(0.35),
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
          return _bottomSheetContainer(
            context: context,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dialogHeader(
                    context: context,
                    icon: Icons.fitness_center_rounded,
                    title: 'Gym',
                    subtitle: 'Track your workout & activity',
                    color: const Color(0xFFF97316),
                  ),
                  const SizedBox(height: 22),
                  _fieldLabel('Workout type'),
                  const SizedBox(height: 9),
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
                      return ChoiceChip(
                        label: Text(type),
                        selected: selectedWorkout == type,
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
                    color: const Color(0xFFF97316),
                    onPressed: () {
                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            'ðŸ‹ï¸ $selectedWorkout workout added',
                          ),
                        ),
                      );
                    },
                  ),
                ],
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
          return _bottomSheetContainer(
            context: context,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dialogHeader(
                    context: context,
                    icon: Icons.bedtime_rounded,
                    title: 'Sleep',
                    subtitle: 'Track sleep & recovery',
                    color: const Color(0xFF6366F1),
                  ),
                  const SizedBox(height: 22),
                  _timeButton(
                    context: context,
                    icon: Icons.nightlight_round,
                    title: 'Bedtime',
                    value: sleepTime == null
                        ? 'Select bedtime'
                        : sleepTime!.format(context),
                    color: const Color(0xFF6366F1),
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
                  _fieldLabel('Sleep quality'),
                  const SizedBox(height: 9),
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
                    color: const Color(0xFF6366F1),
                    onPressed: () {
                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            'ðŸ˜´ Sleep recorded â€¢ Quality: $quality',
                          ),
                        ),
                      );
                    },
                  ),
                ],
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
          return _bottomSheetContainer(
            context: context,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dialogHeader(
                    context: context,
                    icon: Icons.restaurant_rounded,
                    title: 'Cook',
                    subtitle: 'Track meals you prepare',
                    color: const Color(0xFF14B8A6),
                  ),
                  const SizedBox(height: 22),
                  _fieldLabel('Meal'),
                  const SizedBox(height: 9),
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
                    color: const Color(0xFF14B8A6),
                    onPressed: () {
                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            'ðŸ³ $mealType added',
                          ),
                        ),
                      );
                    },
                  ),
                ],
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

  final colors = Theme.of(context).colorScheme;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colors.onSurface.withOpacity(0.08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.code_rounded,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'GitHub',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: colors.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const SelectableText(
            githubUrl,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(
                const ClipboardData(text: githubUrl),
              );

              Navigator.pop(dialogContext);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('GitHub link copied!'),
                ),
              );
            },
            child: const Text('Copy Link'),
          ),
          FilledButton.icon(
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
                      content: Text('Could not open GitHub'),
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open GitHub'),
                    ),
                  );
                }
              }
            },
            icon: const Icon(
              Icons.open_in_new_rounded,
              size: 17,
            ),
            label: const Text('Open GitHub'),
          ),
        ],
      );
    },
  );
}

// ============================================================================
// BOTTOM SHEET CONTAINER
// ============================================================================

Widget _bottomSheetContainer({
  required BuildContext context,
  required Widget child,
}) {
  final colors = Theme.of(context).colorScheme;

  return Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,
    ),
    child: Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        25,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: child,
    ),
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
  final colors = Theme.of(context).colorScheme;

  return Row(
    children: [
      Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.19),
              color.withOpacity(0.07),
            ],
          ),
          borderRadius: BorderRadius.circular(17),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                color: colors.onSurface.withOpacity(0.52),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// ============================================================================
// FIELD LABEL
// ============================================================================

Widget _fieldLabel(String text) {
  return Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
    ),
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
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          width: 1.8,
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
  final colors = Theme.of(context).colorScheme;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.065),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withOpacity(0.13),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: color.withOpacity(0.13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: color,
                size: 21,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      color: colors.onSurface.withOpacity(0.52),
                      fontSize: 11,
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
    height: 54,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 20,
      ),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
        ),
      ),
    ),
  );
}
