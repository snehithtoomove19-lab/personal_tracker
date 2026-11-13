import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker/main.dart';
import 'package:personal_tracker/services/app_scope.dart';
import 'package:personal_tracker/services/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const shareChannel = MethodChannel('personal_tracker/share');

  testWidgets('shared Android text is saved as a note only after confirmation',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final app = AppState();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(shareChannel, (call) async {
      expect(call.method, 'takePendingSharedTexts');
      return ['A thought to remember\nShared from another app.'];
    });
    try {
      await tester.pumpWidget(
        AppScope(
          appState: app,
          child: const MaterialApp(home: RootShell()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Save as a note?'), findsOneWidget);
      expect(app.notes, isEmpty);

      await tester.tap(find.text('Save note'));
      await tester.pumpAndSettle();

      expect(app.notes, hasLength(1));
      expect(app.notes.single.title, 'A thought to remember');
      expect(
        app.notes.single.content,
        'A thought to remember\nShared from another app.',
      );
      expect(find.text('Shared text saved as a note.'), findsOneWidget);
    } finally {
      messenger.setMockMethodCallHandler(shareChannel, null);
      debugDefaultTargetPlatformOverride = null;
      app.dispose();
    }
  });
}
