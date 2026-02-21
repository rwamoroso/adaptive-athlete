import 'package:flutter/material.dart';

class ClinicalPalette {
  static const Color bgTop = Color(0xFF0B1020);
  static const Color bgMid = Color(0xFF171B3A);
  static const Color bgBottom = Color(0xFF2A2150);
  static const Color accent = Color(0xFF8B7CFF);
  static const Color accentSecondary = Color(0xFF4FD1C5);
  static const Color warningMuted = Color(0xFFD49758);
}

ThemeData buildClinicalTheme() {
  final baseScheme = ColorScheme.fromSeed(
    seedColor: ClinicalPalette.accent,
    brightness: Brightness.dark,
  );

  final scheme = baseScheme.copyWith(
    primary: ClinicalPalette.accent,
    secondary: ClinicalPalette.accentSecondary,
    surface: const Color(0xFF151935),
    surfaceContainerHighest: const Color(0xFF20264A),
    outline: Colors.white.withOpacity(0.18),
    onSurface: const Color(0xFFF3F5FF),
    onSurfaceVariant: const Color(0xFFD6DBF5),
    onPrimary: Colors.white,
    error: const Color(0xFFD26D6D),
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: Colors.transparent,
  );

  final textTheme = base.textTheme.apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );

  return base.copyWith(
    textTheme: textTheme.copyWith(
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      labelLarge: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.25,
      ),
      bodySmall: textTheme.bodySmall?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: const Color(0x8A141A38),
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xB3161D3D),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: ClinicalPalette.accent.withOpacity(0.28),
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
        (states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        },
      ),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
        );
      }),
    ),
    cardTheme: CardTheme(
      color: Colors.white.withOpacity(0.06),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.35),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 46),
        shape: const StadiumBorder(),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 46),
        side: BorderSide(color: Colors.white.withOpacity(0.22)),
        shape: const StadiumBorder(),
        foregroundColor: scheme.onSurface,
        textStyle: textTheme.labelLarge,
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: Colors.white.withOpacity(0.08),
      side: BorderSide(color: Colors.white.withOpacity(0.12)),
      labelStyle: textTheme.labelSmall?.copyWith(
        color: scheme.onSurface,
      ),
    ),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: ClinicalPalette.accent,
      inactiveTrackColor: Colors.white.withOpacity(0.2),
      thumbColor: const Color(0xFFDFE5FF),
      overlayColor: ClinicalPalette.accent.withOpacity(0.22),
      trackHeight: 8,
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      labelStyle:
          textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.14)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            BorderSide(color: ClinicalPalette.accent.withOpacity(0.7)),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return scheme.onSurfaceVariant;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return ClinicalPalette.accent.withOpacity(0.6);
        }
        return Colors.white.withOpacity(0.2);
      }),
    ),
    dividerColor: Colors.white.withOpacity(0.14),
  );
}
