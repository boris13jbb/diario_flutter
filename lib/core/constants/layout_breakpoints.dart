import 'package:flutter/material.dart';

/// Anchos de referencia para layouts adaptativos de NotasPro.
class LayoutBreakpoints {
  LayoutBreakpoints._();

  /// Celular: lista a pantalla completa / detalle a pantalla completa.
  static const double compact = 700;

  /// Tableta: sidebar + detalle (info debajo del contenido).
  static const double tablet = 1200;

  /// Ancho por defecto del panel de notas en escritorio.
  static const double sidebarDefault = 360;

  /// Límites al redimensionar el panel de notas.
  static const double sidebarMin = 280;
  static const double sidebarMax = 420;

  /// Ancho de sidebar sugerido en tableta.
  static const double sidebarTablet = 300;

  /// A partir de este ancho del panel de detalle se muestra info a la derecha.
  static const double detailWide = 900;

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) => widthOf(context) < compact;

  static bool isTablet(BuildContext context) {
    final w = widthOf(context);
    return w >= compact && w < tablet;
  }

  static bool isDesktop(BuildContext context) => widthOf(context) >= tablet;

  /// Ancho inicial del sidebar según el tamaño de ventana.
  static double sidebarFor(BuildContext context) {
    if (isDesktop(context)) return sidebarDefault;
    if (isTablet(context)) return sidebarTablet;
    return sidebarDefault;
  }
}
