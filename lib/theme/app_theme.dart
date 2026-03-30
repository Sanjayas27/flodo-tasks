// theme/app_theme.dart
// A deliberate, distinctive dark theme — deep navy + warm amber + soft mint.
// Uses Playfair Display (serif) for headings and DM Sans for body text.
// This pairing signals craftsmanship and attention to detail.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background      = Color(0xFF0F1117);
  static const surface         = Color(0xFF1A1D27);
  static const surfaceElevated = Color(0xFF232738);
  static const border          = Color(0xFF2E3347);
  static const accent          = Color(0xFFFFB347); // Warm amber
  static const accentDim       = Color(0xFF3D2E0F); // Amber on dark bg
  static const textPrimary     = Color(0xFFF0F2FF);
  static const textSecondary   = Color(0xFF8B90A8);
  static const statusTodo      = Color(0xFF6C8EEF);
  static const statusProgress  = Color(0xFFFFB347);
  static const statusDone      = Color(0xFF56C596);
  static const danger          = Color(0xFFFF6B6B);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark();

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,

      colorScheme: const ColorScheme.dark(
        background: AppColors.background,
        surface: AppColors.surface,
        primary: AppColors.accent,
        secondary: AppColors.statusDone,
        error: AppColors.danger,
        onBackground: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onPrimary: AppColors.background,
      ),

      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
        // Screen headings — Playfair Display gives editorial gravitas
        displayMedium: GoogleFonts.playfairDisplay(
          color: AppColors.textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.dmSans(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        titleMedium: GoogleFonts.dmSans(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.dmSans(
          color: AppColors.textPrimary,
          fontSize: 15,
        ),
        bodyMedium: GoogleFonts.dmSans(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        labelLarge: GoogleFonts.dmSans(
          color: AppColors.background,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: GoogleFonts.dmSans(color: AppColors.textSecondary),
        hintStyle:
            GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 14),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.background,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
        elevation: 0,
        shape: CircleBorder(),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle:
            GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      dividerTheme: const DividerThemeData(
          color: AppColors.border, space: 1, thickness: 1),
    );
  }
}
