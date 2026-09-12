import 'package:flutter/material.dart';

// ================================================================
// APP COLORS
// ================================================================

const Color kPrimaryColor = Color(0xFF0F766E);
const Color kIncomeColor = Color(0xFF2FB380);
const Color kExpenseColor = Color(0xFFE2574C);

const Color kLightBackground = Color(0xFFF3F7F6);
const Color kDarkBackground = Color(0xFF0E1515);

const Color kLightSurface = Colors.white;
const Color kDarkSurface = Color(0xFF182020);

enum AppThemePreset {
  ocean(
    id: 'ocean',
    label: 'Ocean',
    description: 'Calm and focused',
    seed: Color(0xFF0F766E),
    icon: Icons.water_drop_rounded,
  ),
  sunset(
    id: 'sunset',
    label: 'Sunset',
    description: 'Warm and energetic',
    seed: Color(0xFFE4572E),
    icon: Icons.wb_twilight_rounded,
  ),
  forest(
    id: 'forest',
    label: 'Forest',
    description: 'Grounded and fresh',
    seed: Color(0xFF3F7D58),
    icon: Icons.forest_rounded,
  ),
  lavender(
    id: 'lavender',
    label: 'Lavender',
    description: 'Soft and reflective',
    seed: Color(0xFF7567B1),
    icon: Icons.auto_awesome_rounded,
  ),
  rose(
    id: 'rose',
    label: 'Rose',
    description: 'Bright and expressive',
    seed: Color(0xFFC44569),
    icon: Icons.local_florist_rounded,
  ),
  citrus(
    id: 'citrus',
    label: 'Citrus',
    description: 'Optimistic and bold',
    seed: Color(0xFFB7791F),
    icon: Icons.wb_sunny_rounded,
  ),
  midnight(
    id: 'midnight',
    label: 'Midnight',
    description: 'Quiet and confident',
    seed: Color(0xFF334E9B),
    icon: Icons.nightlight_round,
  ),
  mint(
    id: 'mint',
    label: 'Mint',
    description: 'Clean and balanced',
    seed: Color(0xFF159A8C),
    icon: Icons.eco_rounded,
  ),
  coral(
    id: 'coral',
    label: 'Coral',
    description: 'Friendly and lively',
    seed: Color(0xFFE76F51),
    icon: Icons.favorite_rounded,
  ),
  plum(
    id: 'plum',
    label: 'Plum',
    description: 'Creative and rich',
    seed: Color(0xFF7B3F8C),
    icon: Icons.palette_rounded,
  ),
  sky(
    id: 'sky',
    label: 'Sky',
    description: 'Open and optimistic',
    seed: Color(0xFF277DA1),
    icon: Icons.cloud_rounded,
  ),
  amber(
    id: 'amber',
    label: 'Amber',
    description: 'Warm and motivated',
    seed: Color(0xFFD97706),
    icon: Icons.lightbulb_rounded,
  ),
  berry(
    id: 'berry',
    label: 'Berry',
    description: 'Playful and vivid',
    seed: Color(0xFFB83280),
    icon: Icons.local_pizza_rounded,
  ),
  slate(
    id: 'slate',
    label: 'Slate',
    description: 'Minimal and focused',
    seed: Color(0xFF475569),
    icon: Icons.grid_view_rounded,
  ),
  aqua(
    id: 'aqua',
    label: 'Aqua',
    description: 'Fresh and digital',
    seed: Color(0xFF087F8C),
    icon: Icons.waves_rounded,
  ),
  indigo(
    id: 'indigo',
    label: 'Indigo',
    description: 'Deep and thoughtful',
    seed: Color(0xFF4F46A5),
    icon: Icons.insights_rounded,
  ),
  paprika(
    id: 'paprika',
    label: 'Paprika',
    description: 'Confident and active',
    seed: Color(0xFFC2410C),
    icon: Icons.bolt_rounded,
  ),
  eucalyptus(
    id: 'eucalyptus',
    label: 'Eucalyptus',
    description: 'Natural and calm',
    seed: Color(0xFF367C6B),
    icon: Icons.spa_rounded,
  ),
  orchid(
    id: 'orchid',
    label: 'Orchid',
    description: 'Elegant and expressive',
    seed: Color(0xFF9D4EDD),
    icon: Icons.flare_rounded,
  ),
  denim(
    id: 'denim',
    label: 'Denim',
    description: 'Reliable and crisp',
    seed: Color(0xFF2563A6),
    icon: Icons.checkroom_rounded,
  ),
  tomato(
    id: 'tomato',
    label: 'Tomato',
    description: 'Direct and energetic',
    seed: Color(0xFFDC3D43),
    icon: Icons.local_fire_department_rounded,
  ),
  olive(
    id: 'olive',
    label: 'Olive',
    description: 'Steady and earthy',
    seed: Color(0xFF718355),
    icon: Icons.park_rounded,
  ),
  glacier(
    id: 'glacier',
    label: 'Glacier',
    description: 'Light and precise',
    seed: Color(0xFF3A86A8),
    icon: Icons.ac_unit_rounded,
  ),
  mocha(
    id: 'mocha',
    label: 'Mocha',
    description: 'Comfortable and grounded',
    seed: Color(0xFF8B5E3C),
    icon: Icons.coffee_rounded,
  ),
  electric(
    id: 'electric',
    label: 'Electric',
    description: 'Bright and ambitious',
    seed: Color(0xFF6D28D9),
    icon: Icons.flash_on_rounded,
  );

  const AppThemePreset({
    required this.id,
    required this.label,
    required this.description,
    required this.seed,
    required this.icon,
  });

  final String id;
  final String label;
  final String description;
  final Color seed;
  final IconData icon;

  static AppThemePreset fromId(String? id) {
    return AppThemePreset.values.firstWhere(
      (preset) => preset.id == id,
      orElse: () => AppThemePreset.ocean,
    );
  }
}

ThemeData buildAppTheme({
  required AppThemePreset preset,
  required bool darkMode,
}) {
  final base = darkMode ? buildDarkTheme() : buildLightTheme();
  if (preset == AppThemePreset.ocean) return base;

  final generated = ColorScheme.fromSeed(
    seedColor: preset.seed,
    brightness: base.brightness,
  );
  final scheme = base.colorScheme.copyWith(
    primary: generated.primary,
    onPrimary: generated.onPrimary,
    primaryContainer: generated.primaryContainer,
    onPrimaryContainer: generated.onPrimaryContainer,
    secondary: generated.secondary,
    onSecondary: generated.onSecondary,
    secondaryContainer: generated.secondaryContainer,
    onSecondaryContainer: generated.onSecondaryContainer,
    tertiary: generated.tertiary,
    onTertiary: generated.onTertiary,
  );

  return base.copyWith(
    colorScheme: scheme,
    primaryColor: scheme.primary,
    splashColor: scheme.primary.withValues(alpha: 0.12),
    focusColor: scheme.primary.withValues(alpha: 0.12),
    hoverColor: scheme.primary.withValues(alpha: 0.08),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: base.elevatedButtonTheme.style?.copyWith(
        backgroundColor: WidgetStatePropertyAll(scheme.primary),
        foregroundColor: WidgetStatePropertyAll(scheme.onPrimary),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: base.filledButtonTheme.style?.copyWith(
        backgroundColor: WidgetStatePropertyAll(scheme.primary),
        foregroundColor: WidgetStatePropertyAll(scheme.onPrimary),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: base.outlinedButtonTheme.style?.copyWith(
        foregroundColor: WidgetStatePropertyAll(scheme.primary),
        side: WidgetStatePropertyAll(
          BorderSide(color: scheme.primary.withValues(alpha: 0.28)),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: base.textButtonTheme.style?.copyWith(
        foregroundColor: WidgetStatePropertyAll(scheme.primary),
      ),
    ),
    floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: base.navigationBarTheme.backgroundColor,
      surfaceTintColor: base.navigationBarTheme.surfaceTintColor,
      elevation: base.navigationBarTheme.elevation,
      height: base.navigationBarTheme.height,
      labelBehavior: base.navigationBarTheme.labelBehavior,
      indicatorColor: scheme.primary.withValues(alpha: 0.15),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : base.iconTheme.color,
          size: states.contains(WidgetState.selected) ? 23 : 21,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : base.colorScheme.onSurfaceVariant,
        ),
      ),
    ),
    progressIndicatorTheme: base.progressIndicatorTheme.copyWith(
      color: scheme.primary,
    ),
  );
}

// ================================================================
// LIGHT THEME
// ================================================================

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kPrimaryColor,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // --------------------------------------------------------------
    // COLOR SCHEME
    // --------------------------------------------------------------

    colorScheme: scheme.copyWith(
      primary: kPrimaryColor,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD8F1EC),
      onPrimaryContainer: const Color(0xFF063D39),
      secondary: const Color(0xFFE08A2E),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFFFE8C7),
      onSecondaryContainer: const Color(0xFF4C2A00),
      tertiary: const Color(0xFFE85D75),
      onTertiary: Colors.white,
      surface: kLightSurface,
      onSurface: const Color(0xFF181A20),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF8FBFA),
      surfaceContainer: const Color(0xFFF0F5F4),
      surfaceContainerHigh: const Color(0xFFE7EFED),
      surfaceContainerHighest: const Color(0xFFDDE9E6),
      outline: const Color(0xFFC7D6D2),
      outlineVariant: const Color(0xFFDCE7E4),
      error: kExpenseColor,
      onError: Colors.white,
    ),

    // --------------------------------------------------------------
    // SCAFFOLD
    // --------------------------------------------------------------

    scaffoldBackgroundColor: kLightBackground,

    // --------------------------------------------------------------
    // APP BAR
    // --------------------------------------------------------------

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF181A20),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w800,
        color: Color(0xFF181A20),
        letterSpacing: -0.4,
      ),
    ),

    // --------------------------------------------------------------
    // CARD
    // --------------------------------------------------------------

    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),

    // --------------------------------------------------------------
    // DIVIDER
    // --------------------------------------------------------------

    dividerTheme: const DividerThemeData(
      color: Color(0xFFE8E8ED),
      thickness: 1,
      space: 1,
    ),

    // --------------------------------------------------------------
    // ICONS
    // --------------------------------------------------------------

    iconTheme: const IconThemeData(
      color: Color(0xFF555966),
      size: 22,
    ),

    // --------------------------------------------------------------
    // TEXT
    // --------------------------------------------------------------

    textTheme: ThemeData.light().textTheme.copyWith(
          headlineLarge: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
            color: Color(0xFF181A20),
          ),
          headlineMedium: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
            color: Color(0xFF181A20),
          ),
          headlineSmall: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: Color(0xFF181A20),
          ),
          titleLarge: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: Color(0xFF181A20),
          ),
          titleMedium: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF252731),
          ),
          titleSmall: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF444752),
          ),
          bodyLarge: const TextStyle(
            fontSize: 15,
            height: 1.45,
            color: Color(0xFF343741),
          ),
          bodyMedium: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: Color(0xFF555966),
          ),
          bodySmall: const TextStyle(
            fontSize: 11,
            height: 1.35,
            color: Color(0xFF777A84),
          ),
          labelLarge: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
          labelMedium: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          labelSmall: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),

    // --------------------------------------------------------------
    // BUTTONS
    // --------------------------------------------------------------

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kPrimaryColor,
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        side: BorderSide(
          color: kPrimaryColor.withValues(alpha: 0.28),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kPrimaryColor,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),

    // --------------------------------------------------------------
    // FLOATING ACTION BUTTON
    // --------------------------------------------------------------

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      elevation: 5,
      focusElevation: 6,
      hoverElevation: 7,
      highlightElevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),

    // --------------------------------------------------------------
    // INPUTS
    // --------------------------------------------------------------

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE4E5EB),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: kPrimaryColor,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: kExpenseColor,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: kExpenseColor,
          width: 1.4,
        ),
      ),
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        fontSize: 13,
        color: Colors.grey.shade500,
      ),
    ),

    // --------------------------------------------------------------
    // NAVIGATION BAR
    // --------------------------------------------------------------

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kLightBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 72,
      indicatorColor: kPrimaryColor.withValues(alpha: 0.15),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: kPrimaryColor,
              size: 23,
            );
          }

          return const IconThemeData(
            color: Color(0xFF777A84),
            size: 21,
          );
        },
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: kPrimaryColor,
            );
          }

          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF777A84),
          );
        },
      ),
    ),

    // --------------------------------------------------------------
    // BOTTOM SHEETS
    // --------------------------------------------------------------

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      modalElevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
    ),

    // --------------------------------------------------------------
    // DIALOGS
    // --------------------------------------------------------------

    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      titleTextStyle: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: Color(0xFF181A20),
      ),
      contentTextStyle: const TextStyle(
        fontSize: 13,
        height: 1.45,
        color: Color(0xFF555966),
      ),
    ),

    // --------------------------------------------------------------
    // CHIPS
    // --------------------------------------------------------------

    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF0F1F6),
      selectedColor: kPrimaryColor.withValues(alpha: 0.12),
      disabledColor: const Color(0xFFE9E9ED),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      labelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      side: BorderSide.none,
    ),

    // --------------------------------------------------------------
    // PROGRESS INDICATORS
    // --------------------------------------------------------------

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: kPrimaryColor,
      linearTrackColor: Color(0xFFE5E6EF),
      circularTrackColor: Color(0xFFE5E6EF),
    ),

    // --------------------------------------------------------------
    // SWITCH
    // --------------------------------------------------------------

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.grey.shade500;
        },
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return kPrimaryColor;
          }
          return const Color(0xFFE0E1E7);
        },
      ),
    ),

    // --------------------------------------------------------------
    // CHECKBOX
    // --------------------------------------------------------------

    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      side: BorderSide(
        color: Colors.grey.shade400,
        width: 1.4,
      ),
      fillColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return kPrimaryColor;
          }
          return Colors.transparent;
        },
      ),
    ),

    // --------------------------------------------------------------
    // SNACKBAR
    // --------------------------------------------------------------

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 8,
      backgroundColor: const Color(0xFF252731),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    ),
  );
}

// ================================================================
// DARK THEME
// ================================================================

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kPrimaryColor,
    brightness: Brightness.dark,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // --------------------------------------------------------------
    // COLOR SCHEME
    // --------------------------------------------------------------

    colorScheme: scheme.copyWith(
      primary: const Color(0xFF8992F2),
      onPrimary: const Color(0xFF171A48),
      primaryContainer: const Color(0xFF3D458D),
      onPrimaryContainer: const Color(0xFFE4E6FF),
      secondary: const Color(0xFF9CA4F5),
      onSecondary: const Color(0xFF171A48),
      tertiary: const Color(0xFFC19BEA),
      onTertiary: const Color(0xFF26183A),
      surface: kDarkSurface,
      onSurface: const Color(0xFFF0F0F5),
      surfaceContainerLowest: const Color(0xFF101116),
      surfaceContainerLow: const Color(0xFF17181E),
      surfaceContainer: const Color(0xFF1B1D24),
      surfaceContainerHigh: const Color(0xFF22242C),
      surfaceContainerHighest: const Color(0xFF292B34),
      outline: const Color(0xFF444650),
      outlineVariant: const Color(0xFF30323A),
      error: const Color(0xFFFF8075),
      onError: const Color(0xFF3B0805),
    ),

    // --------------------------------------------------------------
    // SCAFFOLD
    // --------------------------------------------------------------

    scaffoldBackgroundColor: kDarkBackground,

    // --------------------------------------------------------------
    // APP BAR
    // --------------------------------------------------------------

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFFF0F0F5),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w800,
        color: Color(0xFFF0F0F5),
        letterSpacing: -0.4,
      ),
    ),

    // --------------------------------------------------------------
    // CARD
    // --------------------------------------------------------------

    cardTheme: CardThemeData(
      elevation: 0,
      color: kDarkSurface,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    // --------------------------------------------------------------
    // DIVIDER
    // --------------------------------------------------------------

    dividerTheme: const DividerThemeData(
      color: Color(0xFF2D2F37),
      thickness: 1,
      space: 1,
    ),

    // --------------------------------------------------------------
    // ICONS
    // --------------------------------------------------------------

    iconTheme: const IconThemeData(
      color: Color(0xFFB7B9C3),
      size: 22,
    ),

    // --------------------------------------------------------------
    // TEXT
    // --------------------------------------------------------------

    textTheme: ThemeData.dark().textTheme.copyWith(
          headlineLarge: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
            color: Color(0xFFF3F3F7),
          ),
          headlineMedium: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
            color: Color(0xFFF3F3F7),
          ),
          headlineSmall: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: Color(0xFFF3F3F7),
          ),
          titleLarge: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: Color(0xFFF3F3F7),
          ),
          titleMedium: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE4E4EA),
          ),
          titleSmall: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFFC3C5CF),
          ),
          bodyLarge: const TextStyle(
            fontSize: 15,
            height: 1.45,
            color: Color(0xFFD0D1D8),
          ),
          bodyMedium: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: Color(0xFFB1B3BD),
          ),
          bodySmall: const TextStyle(
            fontSize: 11,
            height: 1.35,
            color: Color(0xFF8E909A),
          ),
          labelLarge: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
          labelMedium: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          labelSmall: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),

    // --------------------------------------------------------------
    // BUTTONS
    // --------------------------------------------------------------

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFF8992F2),
        foregroundColor: const Color(0xFF171A48),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF8992F2),
        foregroundColor: const Color(0xFF171A48),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF8992F2),
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        side: BorderSide(
          color: const Color(0xFF8992F2).withValues(alpha: 0.32),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF9CA4F5),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),

    // --------------------------------------------------------------
    // FAB
    // --------------------------------------------------------------

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF8992F2),
      foregroundColor: const Color(0xFF171A48),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),

    // --------------------------------------------------------------
    // INPUTS
    // --------------------------------------------------------------

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kDarkSurface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFF2D2F37),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFF8992F2),
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFFF8075),
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFFF8075),
          width: 1.4,
        ),
      ),
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFFC3C5CF),
      ),
      hintStyle: TextStyle(
        fontSize: 13,
        color: Colors.grey.shade600,
      ),
    ),

    // --------------------------------------------------------------
    // NAVIGATION BAR
    // --------------------------------------------------------------

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kDarkBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 72,
      indicatorColor: const Color(0xFF8992F2).withValues(alpha: 0.15),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: Color(0xFF9CA4F5),
              size: 23,
            );
          }

          return const IconThemeData(
            color: Color(0xFF8E909A),
            size: 21,
          );
        },
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF9CA4F5),
            );
          }

          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8E909A),
          );
        },
      ),
    ),

    // --------------------------------------------------------------
    // BOTTOM SHEETS
    // --------------------------------------------------------------

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF1B1D24),
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      modalElevation: 14,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
    ),

    // --------------------------------------------------------------
    // DIALOGS
    // --------------------------------------------------------------

    dialogTheme: DialogThemeData(
      backgroundColor: kDarkSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 14,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      titleTextStyle: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: Color(0xFFF3F3F7),
      ),
      contentTextStyle: const TextStyle(
        fontSize: 13,
        height: 1.45,
        color: Color(0xFFB1B3BD),
      ),
    ),

    // --------------------------------------------------------------
    // CHIPS
    // --------------------------------------------------------------

    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF24262E),
      selectedColor: const Color(0xFF8992F2).withValues(alpha: 0.16),
      disabledColor: const Color(0xFF22242A),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      labelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFFD0D1D8),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      side: BorderSide.none,
    ),

    // --------------------------------------------------------------
    // PROGRESS
    // --------------------------------------------------------------

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFF8992F2),
      linearTrackColor: Color(0xFF2B2D35),
      circularTrackColor: Color(0xFF2B2D35),
    ),

    // --------------------------------------------------------------
    // SWITCH
    // --------------------------------------------------------------

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF171A48);
          }

          return const Color(0xFF9B9DA7);
        },
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF8992F2);
          }

          return const Color(0xFF30323A);
        },
      ),
    ),

    // --------------------------------------------------------------
    // CHECKBOX
    // --------------------------------------------------------------

    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      side: const BorderSide(
        color: Color(0xFF5B5D67),
        width: 1.4,
      ),
      fillColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF8992F2);
          }

          return Colors.transparent;
        },
      ),
      checkColor: WidgetStateProperty.all(
        const Color(0xFF171A48),
      ),
    ),

    // --------------------------------------------------------------
    // SNACKBAR
    // --------------------------------------------------------------

    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 8,
      backgroundColor: Color(0xFF292B34),
      contentTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(15),
        ),
      ),
    ),
  );
}
