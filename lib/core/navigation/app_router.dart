import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../constants/app_routes.dart';
import '../constants/layout_breakpoints.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/widgets/fluent_ui.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';

/// Configuración del enrutador de la aplicación
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  redirect: (context, state) {
    // Obtener el estado de autenticación usando ProviderScope
    final container = ProviderScope.containerOf(context, listen: false);
    final authState = container.read(authViewModelProvider);
    final isAuthenticated = authState.isAuthenticated;
    final isAuthRoute = state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.register ||
        state.matchedLocation == AppRoutes.forgotPassword;

    // Si no está autenticado y no está en una ruta de auth, redirigir a login
    if (!isAuthenticated && !isAuthRoute && state.matchedLocation != AppRoutes.splash) {
      return AppRoutes.login;
    }

    // Si está autenticado y está en una ruta de auth, redirigir a home
    if (isAuthenticated && isAuthRoute) {
      return AppRoutes.home;
    }

    return null;
  },
  routes: [
    // Splash Screen
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),

    // Auth Routes
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),

    // Main Routes - Usando Fluent UI
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) {
        if (LayoutBreakpoints.isCompact(context)) {
          return const FluentHomeScreen(
            content: SizedBox.shrink(),
          );
        }
        return const FluentHomeScreen(
          content: FluentHomePlaceholder(),
        );
      },
    ),

    GoRoute(
      path: '${AppRoutes.entryDetail}/:id',
      builder: (context, state) {
        final entryId = state.pathParameters['id']!;
        if (LayoutBreakpoints.isCompact(context)) {
          return FluentDetailScreen(entryId: entryId);
        }
        return FluentHomeScreen(
          selectedEntryId: entryId,
          content: FluentDetailScreen(entryId: entryId),
        );
      },
    ),

    // Create/Edit Entry - Usando Fluent Editor
    GoRoute(
      path: AppRoutes.createEntry,
      builder: (context, state) => const FluentEditorScreen(isEditing: false),
    ),
    GoRoute(
      path: '${AppRoutes.editEntry}/:id',
      builder: (context, state) {
        final entryId = state.pathParameters['id']!;
        return FluentEditorScreen(isEditing: true, entryId: entryId);
      },
    ),

    // Profile
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);

/// Splash Screen - Verifica autenticación y redirige
class SplashScreen extends HookConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);

    useEffect(() {
      // Pequeño delay para mostrar el splash
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!context.mounted) return;
        
        if (authState.isAuthenticated) {
          context.go(AppRoutes.home);
        } else {
          context.go(AppRoutes.login);
        }
      });
      return null;
    }, [authState.isAuthenticated]);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Diario de Aprendizaje',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}
