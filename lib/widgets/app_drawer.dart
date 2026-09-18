
import 'package:flutter/material.dart';
import '../screens/ai_chat_screen.dart';
import '../screens/budgets_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/goals_screen.dart';
import '../screens/monthly_review_screen.dart';
import '../screens/notes_screen.dart';
import '../screens/reminders_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/sms_import_screen.dart';
import '../screens/theme_picker_screen.dart';
import '../services/app_scope.dart';
import '../utils/app_navigation.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isDark = theme.brightness == Brightness.dark;

    final surface = colors.surface;
    final textPrimary = colors.onSurface;
    final textSecondary = colors.onSurface.withValues(alpha: 0.58);

    Widget sectionHeader(
      String title,
      IconData icon,
    ) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 9),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                size: 15,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 9),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.35,
                color: textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    Widget menuItem({
      required IconData icon,
      required String title,
      required String subtitle,
      required Color accent,
      required Widget screen,
      bool featured = false,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 3,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            splashColor: accent.withValues(alpha: 0.08),
            highlightColor: accent.withValues(alpha: 0.045),
            onTap: () {
              dismissAndPush(screen);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: featured
                    ? accent.withValues(alpha: isDark ? 0.13 : 0.075)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: featured
                    ? Border.all(
                        color: accent.withValues(alpha: 0.13),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: 0.20),
                          accent.withValues(alpha: 0.075),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: accent,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.8,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: textPrimary.withValues(alpha: 0.22),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.86,
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 20,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // ============================================================
            // PREMIUM HEADER
            // ============================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                22,
                58,
                22,
                20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.primary,
                    colors.primary.withValues(alpha: 0.88),
                    colors.secondary.withValues(alpha: 0.82),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    right: -35,
                    top: -45,
                    child: Container(
                      width: 145,
                      height: 145,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.055),
                      ),
                    ),
                  ),

                  Positioned(
                    right: 45,
                    top: 60,
                    child: Container(
                      width: 45,
                      height: 45,
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
                          // Avatar
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.55),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 16,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.16),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WELCOME BACK',
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.70),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.55,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  app.userName.isEmpty
                                      ? 'My Tracker'
                                      : app.userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.10),
                              ),
                            ),
                            child: const Icon(
                              Icons.more_horiz_rounded,
                              color: Colors.white,
                              size: 21,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Streak card
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.115),
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.11),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 37,
                              height: 37,
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_fire_department_rounded,
                                color: Colors.orangeAccent,
                                size: 21,
                              ),
                            ),

                            const SizedBox(width: 11),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${app.streak} day streak',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    app.streak > 0
                                        ? 'Keep the momentum going!'
                                        : 'Start your streak today',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.65),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Icon(
                              Icons.trending_up_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ============================================================
            // MENU
            // ============================================================
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                  top: 3,
                  bottom: 20,
                ),
                children: [
                  // --------------------------------------------------------
                  // ASSISTANT
                  // --------------------------------------------------------
                  sectionHeader(
                    'Assistant',
                    Icons.auto_awesome_rounded,
                  ),

                  menuItem(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Ask AI',
                    subtitle: 'Your personal smart assistant',
                    accent: Colors.deepPurple,
                    screen: const AiChatScreen(),
                    featured: true,
                  ),

                  menuItem(
                    icon: Icons.search_rounded,
                    title: 'Search Everything',
                    subtitle: 'Find anything in your tracker',
                    accent: Colors.blueGrey,
                    screen: const SearchScreen(),
                  ),

                  // --------------------------------------------------------
                  // MONEY
                  // --------------------------------------------------------
                  sectionHeader(
                    'Money',
                    Icons.account_balance_wallet_rounded,
                  ),

                  menuItem(
                    icon: Icons.bar_chart_rounded,
                    title: 'Reports',
                    subtitle: 'Understand your spending',
                    accent: Colors.indigo,
                    screen: const ReportsScreen(),
                  ),

                  menuItem(
                    icon: Icons.pie_chart_outline_rounded,
                    title: 'Budgets',
                    subtitle: 'Plan and control your money',
                    accent: Colors.teal,
                    screen: const BudgetsScreen(),
                    featured: true,
                  ),

                  menuItem(
                    icon: Icons.sms_outlined,
                    title: 'Add from SMS',
                    subtitle: 'Import transactions quickly',
                    accent: Colors.blue,
                    screen: const SmsImportScreen(),
                  ),

                  // --------------------------------------------------------
                  // LIFE
                  // --------------------------------------------------------
                  sectionHeader(
                    'Life',
                    Icons.favorite_outline_rounded,
                  ),

                  menuItem(
                    icon: Icons.note_alt_outlined,
                    title: 'Notes',
                    subtitle: 'Capture your thoughts',
                    accent: Colors.orange,
                    screen: const NotesScreen(),
                  ),

                  menuItem(
                    icon: Icons.flag_outlined,
                    title: 'Goals',
                    subtitle: 'Build your future',
                    accent: Colors.purple,
                    screen: const GoalsScreen(),
                  ),

                  menuItem(
                    icon: Icons.calendar_month_rounded,
                    title: 'Calendar',
                    subtitle: 'See your life at a glance',
                    accent: Colors.pink,
                    screen: const CalendarScreen(),
                  ),

                  menuItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Reminders',
                    subtitle: 'Never miss something important',
                    accent: Colors.redAccent,
                    screen: const RemindersScreen(),
                  ),

                  menuItem(
                    icon: Icons.event_available_rounded,
                    title: 'Monthly Review',
                    subtitle: 'Reflect on your progress',
                    accent: Colors.green,
                    screen: const MonthlyReviewScreen(),
                  ),

                  const SizedBox(height: 10),

                  // --------------------------------------------------------
                  // DIVIDER
                  // --------------------------------------------------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(
                      height: 1,
                      color: colors.outlineVariant.withValues(alpha: 0.55),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // --------------------------------------------------------
                  // CUSTOMIZATION
                  // --------------------------------------------------------
                  menuItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'Customize your experience',
                    accent: isDark
                        ? Colors.blueGrey.shade200
                        : Colors.grey.shade700,
                    screen: const SettingsScreen(),
                  ),

                  menuItem(
                    icon: Icons.palette_outlined,
                    title: 'Themes',
                    subtitle: 'Choose from 36 color styles',
                    accent: Colors.deepPurple,
                    screen: const ThemePickerScreen(),
                    featured: true,
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),

            // ============================================================
            // FOOTER
            // ============================================================
            Container(
              padding: const EdgeInsets.fromLTRB(
                20,
                9,
                20,
                15,
              ),
              decoration: BoxDecoration(
                color: surface,
                border: Border(
                  top: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 11,
                    color: colors.primary.withValues(alpha: 0.55),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'PERSONAL TRACKER',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: textPrimary.withValues(alpha: 0.30),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 11,
                    color: colors.primary.withValues(alpha: 0.55),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

