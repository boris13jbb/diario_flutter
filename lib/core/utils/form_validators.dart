/// Validadores reutilizables para formularios (Auth, Editor, Categorías).
/// Centraliza reglas para evitar duplicación y mensajes inconsistentes.
class FormValidators {
  FormValidators._();

  static final RegExp _emailRegex = RegExp(
    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@'
    r'((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|'
    r'(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
  );

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Ingresa tu correo electrónico';
    }
    if (!_emailRegex.hasMatch(text)) {
      return 'Ingresa un correo electrónico válido';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    final text = value ?? '';
    if (text.isEmpty) {
      return 'Ingresa tu contraseña';
    }
    if (text.length < minLength) {
      return 'La contraseña debe tener al menos $minLength caracteres';
    }
    return null;
  }

  /// Contraseña al registrarse: longitud mínima y un poco más de robustez.
  static String? passwordStrong(String? value, {int minLength = 6}) {
    final base = password(value, minLength: minLength);
    if (base != null) return base;

    final text = value!;
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(text);
    final hasDigit = RegExp(r'[0-9]').hasMatch(text);
    if (!hasLetter || !hasDigit) {
      return 'Usa al menos una letra y un número';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  static String? requiredTitle(String? value, {int maxLength = 200}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'El título es obligatorio';
    }
    if (text.length > maxLength) {
      return 'El título no puede superar $maxLength caracteres';
    }
    return null;
  }

  static String? categoryName(String? value, {int maxLength = 40}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'El nombre de la categoría es obligatorio';
    }
    if (text.length < 2) {
      return 'Usa al menos 2 caracteres';
    }
    if (text.length > maxLength) {
      return 'Máximo $maxLength caracteres';
    }
    return null;
  }
}
