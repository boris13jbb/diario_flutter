import '../remote/auth_service.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repositorio de autenticación - Fuente única de verdad para auth
@LazySingleton()
class AuthRepository {
  final AuthService _authService;

  AuthRepository(this._authService);

  /// Inicia sesión con email y contraseña
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _authService.signIn(email: email, password: password);
  }

  /// Registra un nuevo usuario
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    await _authService.signUp(email: email, password: password);
  }

  /// Cierra la sesión del usuario actual
  Future<void> signOut() async {
    await _authService.signOut();
  }

  /// Envía email de recuperación de contraseña
  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  /// Actualiza la contraseña del usuario
  Future<void> updatePassword(String newPassword) async {
    await _authService.updatePassword(newPassword);
  }

  /// Verifica si el usuario está autenticado
  bool get isAuthenticated => _authService.isAuthenticated;

  /// Obtiene el ID del usuario actual
  String? get userId => _authService.userId;

  /// Stream de cambios en el estado de autenticación
  Stream<AuthState> get authStateChanges => _authService.authStateChanges;
}
