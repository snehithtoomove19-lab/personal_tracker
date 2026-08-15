import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFF5B67CA);
const Color kIncomeColor = Color(0xFF2FB380);
const Color kExpenseColor = Color(0xFFE2574C);

ThemeData buildLightTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor, brightness: Brightness.light),
    scaffoldBackgroundColor: const Color(0xFFF6F7FB),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black87,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: base.cardTheme.copyWith(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFFF6F7FB),
      indicatorColor: kPrimaryColor.withOpacity(0.12),
      labelTextStyle: MaterialStateProperty.all(const TextStyle(fontSize: 12)),
    ),
  );
}

ThemeData buildDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor, brightness: Brightness.dark),
    scaffoldBackgroundColor: const Color(0xFF14151A),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: base.cardTheme.copyWith(
      elevation: 0,
      color: const Color(0xFF1E2027),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: const Color(0xFF1E2027),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF14151A),
      indicatorColor: Colors.white12,
      labelTextStyle: MaterialStateProperty.all(const TextStyle(fontSize: 12)),
    ),
  );
}
