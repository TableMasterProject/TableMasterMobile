import 'package:get_it/get_it.dart';
import '../features/auth/data/datasources/auth_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/restaurant/data/datasources/restaurant_datasource.dart';
import '../features/restaurant/data/repositories/restaurant_repository_impl.dart';
import '../features/restaurant/domain/repositories/restaurant_repository.dart';
import '../features/table/data/datasources/table_datasource.dart';
import '../features/table/data/repositories/table_repository_impl.dart';
import '../features/table/domain/repositories/table_repository.dart';
import '../features/user/data/datasources/user_datasource.dart';
import '../features/user/data/repositories/user_repository_impl.dart';
import '../features/user/domain/repositories/user_repository.dart';
import 'api_client.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Client HTTP unique
  getIt.registerLazySingleton<ApiClient>(() => ApiClient());

  // region Auth
  // DataSource Auth
  getIt.registerLazySingleton<AuthDataSource>(
        () => AuthDataSource(getIt<ApiClient>()),
  );

  // Repository Auth
  getIt.registerLazySingleton<IAuthRepository>(
        () => AuthRepositoryImpl(getIt<AuthDataSource>()),
  );
  // endregion

  // region User
  // DataSource User
  getIt.registerLazySingleton<UserDataSource>(
        () => UserDataSource(getIt<ApiClient>()),
  );
  // Repository User
  getIt.registerLazySingleton<IUserRepository>(
        () => UserRepositoryImpl(getIt<UserDataSource>()),
  );
  // endregion

  // region Restaurant
  // DataSource Restaurant
  getIt.registerLazySingleton<RestaurantDataSource>(
        () => RestaurantDataSource(getIt<ApiClient>()),
  );
  // Repository Restaurant
  getIt.registerLazySingleton<IRestaurantRepository>(
        () => RestaurantRepositoryImpl(getIt<RestaurantDataSource>()),
  );
  // endregion

  // region Table
  // DataSource Table
  getIt.registerLazySingleton<TableDataSource>(
        () => TableDataSource(getIt<ApiClient>()),
  );

  // Repository Table
  getIt.registerLazySingleton<ITableRepository>(
        () => TableRepositoryImpl(getIt<TableDataSource>()),
  );
  // endregion
}