import 'package:flutter/material.dart';

/// Paleta profesional del diario: teal sobrio + superficies neutrales.
/// Evita acentos genéricos (púrpura M3 por defecto / cream-terracotta).
class FluentColors {
  // Primarios — teal profundo (aprendizaje / foco)
  static const primary = Color(0xFF0F766E);
  static const primaryLight = Color(0xFF14B8A6);
  static const primaryDark = Color(0xFF115E59);

  // Superficies
  static const surfaceLight = Color(0xFFF8FAFC);
  static const surfaceDark = Color(0xFF0F172A);
  static const surfaceVariantLight = Color(0xFFF1F5F9);
  static const surfaceVariantDark = Color(0xFF1E293B);

  // Sidebar
  static const sidebarLight = Color(0xFFFFFFFF);
  static const sidebarDark = Color(0xFF111827);
  static const sidebarItemLight = Color(0xFFFFFFFF);
  static const sidebarItemDark = Color(0xFF1F2937);
  static const sidebarItemHoverLight = Color(0xFFF1F5F9);
  static const sidebarItemHoverDark = Color(0xFF334155);
  static const sidebarItemSelectedLight = Color(0xFFCCFBF1);
  static const sidebarItemSelectedDark = Color(0xFF134E4A);

  // Bordes
  static const borderLight = Color(0xFFE2E8F0);
  static const borderDark = Color(0xFF334155);

  // Texto
  static const textPrimaryLight = Color(0xFF0F172A);
  static const textPrimaryDark = Color(0xFFF1F5F9);
  static const textSecondaryLight = Color(0xFF64748B);
  static const textSecondaryDark = Color(0xFF94A3B8);

  // Estados
  static const success = Color(0xFF15803D);
  static const warning = Color(0xFFD97706);
  static const error = Color(0xFFDC2626);

  static const List<BoxShadow> shadow2 = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadow4 = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 2,
      offset: Offset(0, 0),
    ),
  ];

  static const List<BoxShadow> shadow8 = [
    BoxShadow(
      color: Color(0x1E000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
}

class FluentSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

class FluentRadius {
  static const double sm = 4.0;
  static const double md = 6.0;
  static const double lg = 8.0;
  static const double xl = 12.0;
  static const double xxl = 16.0;
}
