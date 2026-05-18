import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'service_locator.config.dart';

final GetIt getIt = GetIt.instance;

/// Inicializa el service locator con injectable
@injectableInit
Future<void> setupServiceLocator() async {
  getIt.init();
}
