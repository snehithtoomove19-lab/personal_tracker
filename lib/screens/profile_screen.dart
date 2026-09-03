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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final savedPct = app.savingsGoal <= 0
        ? 0.0
        : (app.totalBalance / app.savingsGoal).clamp(0.0, 1.0).toDouble();

    final bottomPadding = MediaQuery.of(context).padding.bottom + 32;

    final completedGoals = app.goals.where((g) => g.completed).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            bottomPadding,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // =========================================================
                // PROFILE HERO
                // =========================================================

                _ProfileHero(
                  name: app.userName,
                  age: app.age,
                  streak: app.streak,
                  onEdit: () => _editName(context, app),
                ),

                const SizedBox(height: 18),

                // =========================================================
                // OVERVIEW
                // =========================================================

                const _SectionHeading(
                  icon: Icons.insights_rounded,
                  title: 'Your Overview',
                  subtitle: 'A snapshot of your progress',
                ),

                const SizedBox(height: 12),

                // Responsive stats grid.
                //
                // Using a fixed mainAxisExtent instead of childAspectRatio
                // prevents tiny bottom-overflow errors on different screens.
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;

                    final columns = width >= 700 ? 3 : 2;

                    final cardWidth = (width - ((columns - 1) * 10)) / columns;

                    final cardHeight = cardWidth < 170 ? 112.0 : 105.0;

                    return GridView.count(
                      crossAxisCount: columns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: cardHeight,
                      children: [
                        StatTile(
                          label: 'Transactions',
                          value: '${app.transactions.length}',
                          icon: Icons.receipt_long_rounded,
                          color: Colors.indigo,
                          subtitle: 'Money records',
                        ),
                        StatTile(
                          label: 'Tasks',
                          value: '${app.tasks.length}',
                          icon: Icons.check_circle_outline_rounded,
                          color: Colors.blue,
                          subtitle: 'Things to do',
                        ),
                        StatTile(
                          label: 'Notes',
                          value: '${app.notes.length}',
                          icon: Icons.note_alt_outlined,
                          color: Colors.orange,
                          subtitle: 'Saved thoughts',
                        ),
                        StatTile(
                          label: 'Goals',
                          value: '${app.goals.length}',
                          icon: Icons.flag_outlined,
                          color: Colors.purple,
                          subtitle: 'Life targets',
                        ),
                        StatTile(
                          label: 'Mood Logs',
                          value: '${app.moods.length}',
                          icon: Icons.mood_rounded,
                          color: Colors.pink,
                          subtitle: 'Mood entries',
                        ),
                        StatTile(
                          label: 'Completed',
                          value: '$completedGoals',
                          icon: Icons.emoji_events_outlined,
                          color: Colors.green,
                          subtitle: 'Goals achieved',
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 18),

                // =========================================================
                // STREAK
                // =========================================================

                _StreakCard(
                  streak: app.streak,
                ),

                const SizedBox(height: 16),

                // =========================================================
                // BIRTHDAY
                // =========================================================

                SectionCard(
                  title: 'Birthday',
                  titleIcon: Icons.cake_outlined,
                  accentColor: Colors.pink,
                  trailing: _EditButton(
                    onPressed: () => _editBirthday(context, app),
                  ),
                  child: app.birthday == null
                      ? _EmptyInfo(
                          icon: Icons.cake_outlined,
                          text: 'Your birthday is not set yet.',
                          action: 'Add birthday',
                          onTap: () => _editBirthday(context, app),
                        )
                      : Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.pink.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.cake_rounded,
                                color: Colors.pink,
                                size: 23,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatDate(app.birthday!),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                  if (app.age != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Age ${app.age}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (app.age != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${app.age} yrs',
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),

                const SizedBox(height: 16),

                // =========================================================
                // SAVINGS GOAL
                // =========================================================

                SectionCard(
                  title: 'Monthly Savings Goal',
                  titleIcon: Icons.savings_outlined,
                  accentColor: Colors.green,
                  trailing: _EditButton(
                    onPressed: () => _editSavings(context, app),
                  ),
                  child: app.savingsGoal <= 0
                      ? _EmptyInfo(
                          icon: Icons.savings_outlined,
                          text: 'Set a monthly savings target.',
                          action: 'Set goal',
                          onTap: () => _editSavings(context, app),
                        )
                      : _SavingsContent(
                          app: app,
                          percentage: savedPct,
                        ),
                ),

                const SizedBox(height: 16),

                // =========================================================
                // FINANCIAL SNAPSHOT
                // =========================================================

                SectionCard(
                  title: 'Financial Snapshot',
                  titleIcon: Icons.account_balance_wallet_outlined,
                  accentColor: Colors.teal,
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.account_balance_rounded,
                        label: 'Current balance',
                        value: formatMoney(
                          app.totalBalance,
                          app.currency,
                        ),
                        color: Colors.teal,
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.savings_rounded,
                        label: 'Savings target',
                        value: app.savingsGoal > 0
                            ? formatMoney(
                                app.savingsGoal,
                                app.currency,
                              )
                            : 'Not set',
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.speed_rounded,
                        label: 'Goal progress',
                        value: app.savingsGoal > 0
                            ? '${(savedPct * 100).toStringAsFixed(0)}%'
                            : 'Not set',
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // =========================================================
                // SETTINGS
                // =========================================================

                SectionCard(
                  title: 'Preferences',
                  titleIcon: Icons.tune_rounded,
                  accentColor: Colors.blueGrey,
                  child: _SettingsTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // =========================================================
                // FOOTER
                // =========================================================

                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 18,
                        color: colors.primary.withValues(alpha: 0.45),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'KEEP BUILDING YOUR BEST LIFE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                          color: colors.onSurface.withValues(alpha: 0.28),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Small progress every day adds up.',
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                ),

                // Extra breathing room at the absolute bottom.
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  // =============================================================
  // EDIT NAME
  // =============================================================

  void _editName(BuildContext context, dynamic app) {
    final controller = TextEditingController(text: app.userName);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.person_outline_rounded),
              SizedBox(width: 10),
              Text('Edit Name'),
            ],
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Your name',
              hintText: 'Enter your name',
              prefixIcon: const Icon(
                Icons.person_outline_rounded,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                final name = controller.text.trim();

                if (name.isNotEmpty) {
                  app.setUserName(name);
                }

                Navigator.pop(dialogContext);
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // =============================================================
  // EDIT BIRTHDAY
  // =============================================================

  Future<void> _editBirthday(
    BuildContext context,
    dynamic app,
  ) async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: app.birthday ?? DateTime(now.year - 20),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Select your birthday',
      confirmText: 'SAVE',
      cancelText: 'CANCEL',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      app.setBirthday(picked);
    }
  }

  // =============================================================
  // EDIT SAVINGS
  // =============================================================

  void _editSavings(
    BuildContext context,
    dynamic app,
  ) {
    final controller = TextEditingController(
      text: app.savingsGoal > 0 ? app.savingsGoal.toString() : '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.savings_outlined),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Monthly Savings Goal',
                ),
              ),
            ],
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: InputDecoration(
              labelText: 'Savings target',
              hintText: 'Enter amount',
              prefixIcon: const Icon(
                Icons.currency_rupee_rounded,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                final value = double.tryParse(
                  controller.text.trim(),
                );

                if (value != null && value >= 0) {
                  app.setSavingsGoal(value);
                }

                Navigator.pop(dialogContext);
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

// =================================================================
// PROFILE HERO
// =================================================================

class _ProfileHero extends StatelessWidget {
  final String name;
  final int? age;
  final int streak;
  final VoidCallback onEdit;

  const _ProfileHero({
    required this.name,
    required this.age,
    required this.streak,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary,
            colors.primary.withValues(alpha: 0.78),
            colors.secondary.withValues(alpha: 0.70),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -35,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 45,
            bottom: -55,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45),
                        width: 2,
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 31,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR PROFILE',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name.isEmpty ? 'Welcome' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        if (age != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            '$age years old',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onEdit,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.13),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 19,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _HeroMiniStat(
                      icon: Icons.local_fire_department_rounded,
                      label: 'STREAK',
                      value: '$streak days',
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: _HeroMiniStat(
                      icon: Icons.auto_awesome_rounded,
                      label: 'TRACKER',
                      value: 'Active',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroMiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.85),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// SECTION HEADING
// =================================================================

class _SectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
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
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: colors.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =================================================================
// STREAK CARD
// =================================================================

class _StreakCard extends StatelessWidget {
  final int streak;

  const _StreakCard({
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.orange,
              size: 26,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streak > 0
                      ? '$streak day streak \u{1F525}'
                      : 'Start your streak',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  streak > 0
                      ? 'Keep showing up every day.'
                      : 'Complete something today to begin.',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurface.withValues(alpha: 0.48),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 13,
            color: Colors.orange.withValues(alpha: 0.55),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// SAVINGS CONTENT
// =================================================================

class _SavingsContent extends StatelessWidget {
  final dynamic app;
  final double percentage;

  const _SavingsContent({
    required this.app,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final months = app.monthsToReachSavingsGoal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                formatMoney(
                  app.savingsGoal,
                  app.currency,
                ),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: colors.onSurface,
                ),
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 12,
            backgroundColor: Colors.green.withValues(alpha: 0.10),
            valueColor: const AlwaysStoppedAnimation<Color>(
              Colors.green,
            ),
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 14,
              color: colors.onSurface.withValues(alpha: 0.42),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                'Based on your current balance',
                style: TextStyle(
                  fontSize: 10,
                  color: colors.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(13),
          ),
          child: _GoalProjection(
            months: months,
          ),
        ),
      ],
    );
  }
}

// =================================================================
// GOAL PROJECTION
// =================================================================

class _GoalProjection extends StatelessWidget {
  final int? months;

  const _GoalProjection({
    required this.months,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (months == null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 17,
            color: colors.onSurface.withValues(alpha: 0.45),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Not enough recent income/expense history to project a timeline yet.',
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: colors.onSurface.withValues(alpha: 0.52),
              ),
            ),
          ),
        ],
      );
    }

    if (months == 0) {
      return const Row(
        children: [
          Icon(
            Icons.celebration_rounded,
            size: 18,
            color: Colors.green,
          ),
          SizedBox(width: 8),
          Text(
            'Goal reached! \u{1F389}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const Icon(
          Icons.schedule_rounded,
          size: 17,
          color: Colors.green,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'At your current pace, about $months month${months == 1 ? '' : 's'} to reach your goal.',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

// =================================================================
// INFO ROW
// =================================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            size: 19,
            color: color,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

// =================================================================
// EMPTY INFO
// =================================================================

class _EmptyInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  final String action;
  final VoidCallback onTap;

  const _EmptyInfo({
    required this.icon,
    required this.text,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: colors.primary.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: colors.onSurface.withValues(alpha: 0.48),
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(action),
        ),
      ],
    );
  }
}

// =================================================================
// EDIT BUTTON
// =================================================================

class _EditButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _EditButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 5,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(
        Icons.edit_outlined,
        size: 14,
      ),
      label: const Text(
        'Edit',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// =================================================================
// SETTINGS TILE
// =================================================================

class _SettingsTile extends StatelessWidget {
  final VoidCallback onTap;

  const _SettingsTile({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 4,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.blueGrey.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Settings',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Customize your personal tracker',
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.onSurface.withValues(alpha: 0.30),
            ),
          ],
        ),
      ),
    );
  }
}
