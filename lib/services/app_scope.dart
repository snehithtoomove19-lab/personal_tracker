import 'package:flutter/material.dart';
import 'app_state.dart';

/// Lightweight dependency-injection widget so any descendant can call
/// `AppScope.of(context)` to get the shared [AppState] and rebuild when it
/// changes. Avoids pulling in an extra state-management package.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState appState, required super.child})
      : super(notifier: appState);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in context');
    return scope!.notifier!;
  }
}
