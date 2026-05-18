import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import '../remote/auth_service.dart';

/// Repositorio de autenticación - Fuente única de verdad para auth.
@LazySingleton()
class AuthRepository {
  final AuthService _authService;

  AuthRepository(this._authService);

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _authService.signIn(email: email, password: password);
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    await _authService.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  Future<void> updatePassword(String newPassword) async {
    await _authService.updatePassword(newPassword);
  }

  bool get isAuthenticated => _authService.isAuthenticated;

  String? get userId => _authService.userId;

  User? get currentUser => _authService.currentUser;

  Stream<User?> get authStateChanges => _authService.authStateChanges;
}
