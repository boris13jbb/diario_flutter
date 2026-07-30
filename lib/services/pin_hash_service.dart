import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Hash seguro de PIN de notas (nunca almacena el PIN en texto plano).
class PinHashService {
  static const _pepper = 'notaspro_pin_v1';

  String hashPin(String pin, {required String noteId, required String userId}) {
    final normalized = pin.trim();
    final payload = utf8.encode('$_pepper|$userId|$noteId|$normalized');
    return sha256.convert(payload).toString();
  }

  bool verify({
    required String pin,
    required String noteId,
    required String userId,
    required String storedHash,
  }) {
    if (storedHash.isEmpty) return false;
    return hashPin(pin, noteId: noteId, userId: userId) == storedHash;
  }
}
