import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central place for BUCKS' colors, typography, and ThemeData.
///
/// Keeping this in one file makes it easy to tweak the whole app's look
/// later. If this file gets too big, we'll split it into
/// `app_colors.dart` and `app_text_styles.dart`.
class AppTheme {
  AppTheme._(); // prevents accidentally creating an instance of this class

  // --- Colors -----------------------------------------------------------
  // Warm, friendly, game-like palette. Not final — easy to adjust once
  // we see real screens.
  static const Color primary = Color(0xFFFFB020); // coin gold
  static const Color secondary = Color(0xFF2ECC71); // healthy-money green
  static const Color danger = Color(0xFFE74C3C); // over-budget warning
  static const Color background = Color(0xFFFFFBF2); // soft warm white
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF2D2A26);

  // --- Theme --------------------------------------------------------------
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        secondary: secondary,
        error: danger,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textDark,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // Headings use Poppins, body text uses Roboto, per the design spec.
  static TextTheme _textTheme(TextTheme base) {
    return base
        .copyWith(
          displayLarge: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          displayMedium: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          headlineLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          headlineMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        )
        .apply(
          bodyColor: textDark,
          displayColor: textDark,
          fontFamily: GoogleFonts.roboto().fontFamily,
        );
  }
}
