/// Prioridad de una nota (0 = ninguna … 3 = urgente).
class NotePriority {
  static const int none = 0;
  static const int low = 1;
  static const int medium = 2;
  static const int high = 3;

  static String label(int value) {
    switch (value) {
      case low:
        return 'Baja';
      case medium:
        return 'Media';
      case high:
        return 'Alta';
      default:
        return 'Sin prioridad';
    }
  }

  static int clamp(int value) {
    if (value < none) return none;
    if (value > high) return high;
    return value;
  }
}
