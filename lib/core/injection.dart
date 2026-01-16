import 'package:get_it/get_it.dart';
import '../features/auth/data/datasources/auth_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import 'api_client.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // 1. Le "moteur" : Client HTTP unique
  getIt.registerLazySingleton<ApiClient>(() => ApiClient());

  // 2. Les "sources" : Interrogent le réseau
  getIt.registerLazySingleton<AuthDataSource>(
        () => AuthDataSource(getIt<ApiClient>()),
  );

  // 3. Le "cerveau" : Le Repository
  // On lie l'interface (IAuthRepository) à son implémentation (AuthRepositoryImpl)
  getIt.registerLazySingleton<IAuthRepository>(
        () => AuthRepositoryImpl(getIt<AuthDataSource>()),
  );
}