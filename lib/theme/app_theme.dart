import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFFE50914);
  static const Color secondary = Color(0xFF8B0000);
  static const Color background = Color(0xFF0D0D0D);
  static const Color card = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFF151515);
  static const Color text = Color(0xFFFFFFFF);
  static const Color subtleText = Color(0xFFB8B8B8);
  static const Color border = Color(0xFF2B2B2B);
  static const Color success = Color(0xFF21C76A);
  static const Color warning = Color(0xFFFFB020);

  static ThemeData get darkTheme {
    final base = GoogleFonts.rajdhaniTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: text,
      displayColor: text,
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: card,
        onPrimary: text,
        onSecondary: text,
        onSurface: text,
      ),
      textTheme: base.copyWith(
        headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: text,
      ),
      cardColor: card,
      dividerColor: border,
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: subtleText),
        labelStyle: const TextStyle(color: subtleText),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: text,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary.withOpacity(0.22),
        side: const BorderSide(color: border),
        labelStyle: const TextStyle(color: text),
        secondaryLabelStyle: const TextStyle(color: text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primary;
          return subtleText;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primary.withOpacity(0.35);
          return border;
        }),
      ),
    );
  }

  static BoxDecoration glowCard({Color? accent}) {
    final useColor = accent ?? primary;
    return BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: useColor.withOpacity(0.12)),
      boxShadow: [
        BoxShadow(
          color: useColor.withOpacity(0.14),
          blurRadius: 26,
          spreadRadius: 0,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}
