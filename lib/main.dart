import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/app_state.dart';
import 'services/app_scope.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/mood_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/reminders_screen.dart';
import 'widgets/app_drawer.dart';
import 'utils/app_navigation.dart';

void main() {
  // Makes any widget-build error show its actual message on-screen instead
  // of a blank grey box ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â Flutter's default error widget only shows details
  // in debug mode, so on a release build a crash can otherwise look exactly
  // like "the app won't open" with zero information to go on.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Something went wrong',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red)),
                const SizedBox(height: 12),
                Text(details.exceptionAsString(),
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  };

  // Catches any error that escapes normal Flutter error handling (e.g. from
  // an async gap) so the app can't silently die without any trace of why.
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Color(0xFFF6F7FB),
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    runApp(const AppRoot());
  }, (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
  });
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final AppState appState = AppState();
  String? _startupError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await appState.load();
      if (!mounted) return;
    } catch (e, st) {
      debugPrint('Failed to load app data: $e\n$st');
      // Even if loading saved data fails, mark the app as loaded (with
      // whatever defaults AppState already has) so the UI can still open
      // rather than being stuck on a spinner forever.
      if (mounted) {
        setState(() => _startupError = e.toString());
      }
      appState.forceMarkLoaded();
    }
  }

  @override
  void dispose() {
    appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      appState: appState,
      child: MaterialApp(
        title: 'Personal Tracker',
        debugShowCheckedModeBanner: false,
        navigatorKey: appNavigatorKey,
        scaffoldMessengerKey: appMessengerKey,
        theme: buildLightTheme(),
        home: _AppHome(
          appState: appState,
          startupError: _startupError,
        ),
      ),
    );
  }
}

class _AppHome extends StatelessWidget {
  final AppState appState;
  final String? startupError;

  const _AppHome({
    required this.appState,
    required this.startupError,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        if (!appState.loaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final content = appState.pinEnabled
            ? LockScreen(child: RootShell(startupError: startupError))
            : RootShell(startupError: startupError);

        return Theme(
          data: appState.darkMode ? buildDarkTheme() : buildLightTheme(),
          child: content,
        );
      },
    );
  }
}

class RootShell extends StatefulWidget {
  final String? startupError;
  const RootShell({super.key, this.startupError});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  bool _digestShown = false;
  bool _birthdayShown = false;

  final _screens = const [
    HomeScreen(),
    ExpensesScreen(),
    MoodScreen(),
    TasksScreen(),
    ProfileScreen(),
  ];

  final _titles = const ['Home', 'Expenses', 'Mood', 'Tasks', 'Profile'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_digestShown) {
      _digestShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.startupError != null) {
          _showStartupErrorBanner();
        } else {
          _maybeShowBirthdayCelebration();
        }
      });
    }
  }

  void _showStartupErrorBanner() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Some saved data could not be loaded: ${widget.startupError}'),
        duration: const Duration(seconds: 6),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _maybeShowBirthdayCelebration() {
    if (!mounted || _birthdayShown) return;
    final app = AppScope.of(context);
    final todaysContacts = app.todayBirthdayContacts;
    if (!app.isMyBirthdayToday && todaysContacts.isEmpty) {
      _maybeShowDigest();
      return;
    }

    _birthdayShown = true;
    showDialog(
      context: context,
      builder: (ctx) {
        final children = <Widget>[];
        if (app.isMyBirthdayToday) {
          children.add(const Text('Happy birthday! \u{1F389}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
          children.add(const SizedBox(height: 10));
          children.add(Text('Today is your special day, ${app.userName}.',
              style: const TextStyle(fontSize: 14)));
          if (app.age != null) {
            children.add(const SizedBox(height: 8));
            children.add(Text('You are ${app.age} years young today.',
                style: const TextStyle(fontSize: 14)));
          }
        }
        if (todaysContacts.isNotEmpty) {
          if (children.isNotEmpty) children.add(const SizedBox(height: 14));
          children.add(const Text('Today is also a birthday for:',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)));
          children.add(const SizedBox(height: 8));
          children.addAll(todaysContacts.map((c) => Text(
              '\u2022 ${c.name} (${c.relation})',
              style: const TextStyle(fontSize: 14))));
        }

        return AlertDialog(
          title: const Text('Birthday Celebration'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Celebrate'),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) _maybeShowDigest();
    });
  }

  void _maybeShowDigest() {
    if (!mounted) return;
    final app = AppScope.of(context);
    if (!app.showLaunchDigest) return;
    final digest = app.launchDigest;
    if (!digest.hasAnything) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Welcome back'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (digest.overdueTaskCount > 0)
              _digestRow(Icons.warning_amber, Colors.red,
                  '${digest.overdueTaskCount} overdue task${digest.overdueTaskCount == 1 ? '' : 's'}'),
            if (digest.todayTaskCount > 0)
              _digestRow(Icons.check_circle_outline, Colors.blue,
                  '${digest.todayTaskCount} task${digest.todayTaskCount == 1 ? '' : 's'} due today'),
            if (!digest.moodLoggedToday)
              _digestRow(Icons.sentiment_neutral, Colors.orange,
                  "You haven't logged today's mood yet"),
            if (digest.overBudgetCategoryCount > 0)
              _digestRow(Icons.pie_chart_outline, Colors.red,
                  '${digest.overBudgetCategoryCount} categor${digest.overBudgetCategoryCount == 1 ? 'y is' : 'ies are'} over budget'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              app.setShowLaunchDigest(false);
              Navigator.pop(ctx);
            },
            child: const Text("Don't show this again"),
          ),
          FilledButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
        ],
      ),
    );
  }

  Widget _digestRow(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          Builder(builder: (context) {
            final app = AppScope.of(context);
            final count = app.overdueTasks.length + app.todayTasks.length;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Reminders',
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RemindersScreen())),
                ),
                if (count > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
      drawer: const AppDrawer(),
      body: SafeArea(child: _screens[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Expenses'),
          NavigationDestination(
              icon: Icon(Icons.emoji_emotions_outlined),
              selectedIcon: Icon(Icons.emoji_emotions),
              label: 'Mood'),
          NavigationDestination(
              icon: Icon(Icons.check_circle_outline),
              selectedIcon: Icon(Icons.check_circle),
              label: 'Tasks'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}
