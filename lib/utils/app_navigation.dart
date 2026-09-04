import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void dismissAndPush(Widget screen) {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;

    navigator.pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigator.mounted) {
            navigator.push(
                MaterialPageRoute(builder: (_) => screen),
            );
        }
    });
}
