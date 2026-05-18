import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/di/service_locator.dart';
import 'core/navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase
  await Supabase.initialize(
    url: 'https://swirjlhuxcpcfuvketcv.supabase.co',
    anonKey: 'sb_publishable_cVlswOY8djMMTWsdV222Hw_hJRUOmba',
  );
  
  // Inicializar inyección de dependencias
  await setupServiceLocator();
  
  runApp(const ProviderScope(child: DiarioApp()));
}

class DiarioApp extends ConsumerWidget {
  const DiarioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Diario de Aprendizaje',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
