// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:diario_flutter/core/di/injectable_config.dart' as _i232;
import 'package:diario_flutter/data/local/dao/diary_dao.dart' as _i827;
import 'package:diario_flutter/data/local/database.dart' as _i588;
import 'package:diario_flutter/data/remote/auth_service.dart' as _i217;
import 'package:diario_flutter/data/remote/supabase_diary_service.dart'
    as _i544;
import 'package:diario_flutter/data/repositories/auth_repository.dart' as _i149;
import 'package:diario_flutter/data/repositories/diary_repository.dart'
    as _i971;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final injectableConfig = _$InjectableConfig();
    gh.lazySingleton<_i217.AuthService>(() => injectableConfig.authService);
    gh.lazySingleton<_i544.SupabaseDiaryService>(
      () => injectableConfig.supabaseDiaryService,
    );
    gh.lazySingleton<_i588.AppDatabase>(() => injectableConfig.appDatabase);
    gh.lazySingleton<_i827.DiaryDao>(
      () => injectableConfig.diaryDao(gh<_i588.AppDatabase>()),
    );
    gh.lazySingleton<_i971.DiaryRepository>(
      () => _i971.DiaryRepository(
        gh<_i827.DiaryDao>(),
        gh<_i544.SupabaseDiaryService>(),
      ),
    );
    gh.lazySingleton<_i149.AuthRepository>(
      () => _i149.AuthRepository(gh<_i217.AuthService>()),
    );
    return this;
  }
}

class _$InjectableConfig extends _i232.InjectableConfig {}
