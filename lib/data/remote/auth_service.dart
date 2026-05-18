import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio de autenticación con Supabase
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene la sesión actual del usuario
  Session? get currentSession => _supabase.auth.currentSession;

  /// Obtiene el usuario actual
  User? get currentUser => _supabase.auth.currentUser;

  /// Stream de cambios en el estado de autenticación
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Inicia sesión con email y contraseña
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error inesperado al iniciar sesión: $e');
    }
  }

  /// Registra un nuevo usuario
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error inesperado al registrar usuario: $e');
    }
  }

  /// Cierra la sesión del usuario actual
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  /// Envía email de recuperación de contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error al enviar email de recuperación: $e');
    }
  }

  /// Actualiza la contraseña del usuario
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error al actualizar contraseña: $e');
    }
  }

  /// Verifica si el usuario está autenticado
  bool get isAuthenticated => currentUser != null;

  /// Obtiene el ID del usuario actual
  String? get userId => currentUser?.id;

  /// Maneja las excepciones de autenticación y retorna mensajes amigables
  Exception _handleAuthException(AuthException e) {
    switch (e.message.toLowerCase()) {
      case 'invalid login credentials':
        return Exception('Email o contraseña incorrectos');
      case 'User not found':
        return Exception('Usuario no encontrado');
      case 'User already registered':
        return Exception('Este email ya está registrado');
      case 'Weak password':
        return Exception('La contraseña es demasiado débil');
      case 'Email not confirmed':
        return Exception('Por favor, confirma tu email antes de iniciar sesión');
      default:
        return Exception('Error de autenticación: ${e.message}');
    }
  }
}
