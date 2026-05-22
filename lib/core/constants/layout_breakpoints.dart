import 'package:flutter/material.dart';

/// Anchos de referencia para layouts adaptativos.
class LayoutBreakpoints {
  LayoutBreakpoints._();

  /// Por debajo de este ancho se usa navegación tipo móvil (una columna).
  static const double compact = 720;

  static bool isCompact(BuildContext context) {
    return MediaQuery.sizeOf(context).width < compact;
  }
}
