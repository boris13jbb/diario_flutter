import 'package:diario_flutter/core/utils/form_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FormValidators.email', () {
    test('rechaza vacío', () {
      expect(FormValidators.email(null), isNotNull);
      expect(FormValidators.email(''), isNotNull);
      expect(FormValidators.email('   '), isNotNull);
    });

    test('rechaza formato inválido', () {
      expect(FormValidators.email('sinarroba'), isNotNull);
      expect(FormValidators.email('a@'), isNotNull);
      expect(FormValidators.email('@b.com'), isNotNull);
    });

    test('acepta correo válido', () {
      expect(FormValidators.email('user@example.com'), isNull);
      expect(FormValidators.email('  user@example.com  '), isNull);
    });
  });

  group('FormValidators.password', () {
    test('exige longitud mínima', () {
      expect(FormValidators.password('12345'), isNotNull);
      expect(FormValidators.password('123456'), isNull);
    });
  });

  group('FormValidators.passwordStrong', () {
    test('exige letra y número', () {
      expect(FormValidators.passwordStrong('abcdef'), isNotNull);
      expect(FormValidators.passwordStrong('123456'), isNotNull);
      expect(FormValidators.passwordStrong('abc123'), isNull);
    });
  });

  group('FormValidators.confirmPassword', () {
    test('exige coincidencia', () {
      expect(FormValidators.confirmPassword(null, 'abc123'), isNotNull);
      expect(FormValidators.confirmPassword('abc124', 'abc123'), isNotNull);
      expect(FormValidators.confirmPassword('abc123', 'abc123'), isNull);
    });
  });

  group('FormValidators.requiredTitle', () {
    test('valida título', () {
      expect(FormValidators.requiredTitle(''), isNotNull);
      expect(FormValidators.requiredTitle('  '), isNotNull);
      expect(FormValidators.requiredTitle('Mi nota'), isNull);
    });
  });

  group('FormValidators.categoryName', () {
    test('valida nombre de categoría', () {
      expect(FormValidators.categoryName('a'), isNotNull);
      expect(FormValidators.categoryName('Trabajo'), isNull);
    });
  });
}
