import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker/screens/cloud_sync_screen.dart';
import 'package:personal_tracker/services/app_scope.dart';
import 'package:personal_tracker/services/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cloud sync explains setup without requiring a configured URL',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState();
    await tester.pumpWidget(
      MaterialApp(
        home: AppScope(
          appState: app,
          child: const CloudSyncScreen(),
        ),
      ),
    );

    expect(find.text('Supabase project'), findsOneWidget);
    expect(find.text('Project URL'), findsOneWidget);
    expect(find.text('Anon / publishable key'), findsOneWidget);
    expect(
      find.textContaining('Never enter a database password'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });
}
