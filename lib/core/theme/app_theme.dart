import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../presentation/widgets/fluent_colors.dart';

/// Configuración del tema Material 3 para la aplicación
class AppTheme {
  // Colores primarios
  static const Color primaryColor = Color(0xFF6750A4);
  static const Color primaryContainer = Color(0xFFEADDFF);
  static const Color onPrimary = Colors.white;
  static const Color onPrimaryContainer = Color(0xFF21005D);

  // Colores secundarios
  static const Color secondaryColor = Color(0xFF625B71);
  static const Color secondaryContainer = Color(0xFFE8DEF8);
  static const Color onSecondary = Colors.white;
  static const Color onSecondaryContainer = Color(0xFF1D192B);

  // Colores de superficie
  static const Color surfaceColor = Color(0xFFFFFBFE);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color surfaceVariant = Color(0xFFE7E0EC);
  static const Color onSurfaceVariant = Color(0xFF49454F);

  // Colores de error
  static const Color errorColor = Color(0xFFB3261E);
  static const Color onError = Colors.white;

  /// Tema claro - Estilo Microsoft Fluent
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: FluentColors.primary,
        primaryContainer: FluentColors.primaryLight,
        onPrimary: Colors.white,
        onPrimaryContainer: FluentColors.primaryDark,
        secondary: FluentColors.primaryLight,
        secondaryContainer: FluentColors.sidebarItemSelectedLight,
        onSecondary: Colors.white,
        onSecondaryContainer: FluentColors.primary,
        surface: FluentColors.surfaceLight,
        onSurface: FluentColors.textPrimaryLight,
        surfaceContainerHighest: FluentColors.surfaceVariantLight,
        onSurfaceVariant: FluentColors.textSecondaryLight,
        error: FluentColors.error,
        onError: Colors.white,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: FluentColors.textPrimaryLight,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: FluentColors.textPrimaryLight,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: FluentColors.textPrimaryLight,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: FluentColors.textPrimaryLight,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: FluentColors.textPrimaryLight,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: FluentColors.textSecondaryLight,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: FluentColors.surfaceLight,
        foregroundColor: FluentColors.textPrimaryLight,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FluentColors.surfaceVariantLight.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FluentRadius.lg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FluentRadius.lg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FluentRadius.lg),
          borderSide: const BorderSide(color: FluentColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FluentColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FluentRadius.lg),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FluentColors.textPrimaryLight,
          side: const BorderSide(color: FluentColors.borderLight),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FluentRadius.lg),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: FluentColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FluentRadius.xl),
          side: const BorderSide(color: FluentColors.borderLight, width: 1),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: FluentColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(FluentRadius.lg)),
        ),
      ),
    );
  }

  /// Tema oscuro - Estilo Microsoft Fluent Dark
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: FluentColors.primaryLight,
        primaryContainer: FluentColors.primary,
        onPrimary: Colors.white,
        onPrimaryContainer: Colors.white,
        secondary: FluentColors.primaryLight,
        secondaryContainer: FluentColors.sidebarItemSelectedDark,
        onSecondary: Colors.white,
        onSecondaryContainer: Colors.white,
        surface: FluentColors.surfaceDark,
        onSurface: FluentColors.textPrimaryDark,
        surfaceContainerHighest: FluentColors.surfaceVariantDark,
        onSurfaceVariant: FluentColors.textSecondaryDark,
        error: FluentColors.error,
        onError: Colors.white,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: FluentColors.textPrimaryDark,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: FluentColors.textPrimaryDark,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: FluentColors.textPrimaryDark,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: FluentColors.textPrimaryDark,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: FluentColors.textPrimaryDark,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: FluentColors.textSecondaryDark,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: FluentColors.surfaceDark,
        foregroundColor: FluentColors.textPrimaryDark,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FluentColors.surfaceVariantDark.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FluentRadius.lg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FluentRadius.lg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FluentRadius.lg),
          borderSide: const BorderSide(color: FluentColors.primaryLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FluentColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FluentRadius.lg),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FluentColors.textPrimaryDark,
          side: const BorderSide(color: FluentColors.borderDark),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FluentRadius.lg),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: FluentColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FluentRadius.xl),
          side: const BorderSide(color: FluentColors.borderDark, width: 1),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: FluentColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(FluentRadius.lg)),
        ),
      ),
    );
  }
}
