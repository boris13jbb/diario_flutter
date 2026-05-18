import 'package:flutter/material.dart';

/// Colores personalizados estilo Microsoft Fluent + Notion
class FluentColors {
  // Colores primarios - Azul Microsoft
  static const primary = Color(0xFF0078D4);
  static const primaryLight = Color(0xFF2B88D8);
  static const primaryDark = Color(0xFF005A9E);
  
  // Superficies
  static const surfaceLight = Color(0xFFFAFAFA);
  static const surfaceDark = Color(0xFF202020);
  static const surfaceVariantLight = Color(0xFFF3F3F3);
  static const surfaceVariantDark = Color(0xFF2D2D2D);
  
  // Sidebar
  static const sidebarLight = Color(0xFFFBFBFB);
  static const sidebarDark = Color(0xFF1E1E1E);
  static const sidebarItemLight = Color(0xFFFFFFFF);
  static const sidebarItemDark = Color(0xFF252526);
  static const sidebarItemHoverLight = Color(0xFFF3F3F3);
  static const sidebarItemHoverDark = Color(0xFF2A2D2E);
  static const sidebarItemSelectedLight = Color(0xFFE8F0FE);
  static const sidebarItemSelectedDark = Color(0xFF094771);
  
  // Bordes
  static const borderLight = Color(0xFFE0E0E0);
  static const borderDark = Color(0xFF3E3E3E);
  
  // Texto
  static const textPrimaryLight = Color(0xFF242424);
  static const textPrimaryDark = Color(0xFFCCCCCC);
  static const textSecondaryLight = Color(0xFF616161);
  static const textSecondaryDark = Color(0xFF999999);
  
  // Estados
  static const success = Color(0xFF107C10);
  static const warning = Color(0xFFFFB900);
  static const error = Color(0xFFD13438);
  
  // Sombras Fluent
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

/// Constantes de diseño Fluent
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
}
