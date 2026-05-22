import 'package:injectable/injectable.dart';
import '../../data/remote/auth_service.dart';
import '../../data/remote/firestore_category_service.dart';
import '../../data/remote/firestore_diary_service.dart';
import '../../data/local/database.dart';
import '../../data/local/dao/diary_dao.dart';

/// Configuración del módulo principal de inyección de dependencias
@module
abstract class InjectableConfig {
  // Registro de AuthService
  @lazySingleton
  AuthService get authService => AuthService();

  @lazySingleton
  FirestoreDiaryService get firestoreDiaryService => FirestoreDiaryService();

  @lazySingleton
  FirestoreCategoryService get firestoreCategoryService =>
      FirestoreCategoryService();

  // Registro de AppDatabase
  @lazySingleton
  AppDatabase get appDatabase => AppDatabase();

  // Registro de DiaryDao
  @lazySingleton
  DiaryDao diaryDao(AppDatabase db) => db.diaryDao;
}
