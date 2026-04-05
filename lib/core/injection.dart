import 'package:get_it/get_it.dart';
import 'package:table_master_mobile/core/signalr_service.dart';
import '../features/auth/data/datasources/auth_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/restaurant/data/datasources/restaurant_datasource.dart';
import '../features/restaurant/data/repositories/restaurant_repository_impl.dart';
import '../features/restaurant/domain/repositories/restaurant_repository.dart';
import '../features/table/data/datasources/table_datasource.dart';
import '../features/table/data/repositories/table_repository_impl.dart';
import '../features/table/domain/repositories/table_repository.dart';
import '../features/reservation/data/datasources/reservation_datasource.dart';
import '../features/reservation/data/repositories/reservation_repository_impl.dart';
import '../features/reservation/domain/repositories/reservation_repository.dart';
import '../features/user/data/datasources/user_datasource.dart';
import '../features/user/data/repositories/user_repository_impl.dart';
import '../features/user/domain/repositories/user_repository.dart';
import '../features/menu/data/datasources/menu_datasource.dart';
import '../features/menu/data/repositories/menu_repository_impl.dart';
import '../features/menu/domain/repositories/menu_repository.dart';
import '../features/daily_activity/data/datasources/daily_activity_datasource.dart';
import '../features/daily_activity/data/repositories/daily_activity_repository_impl.dart';
import '../features/daily_activity/domain/repositories/daily_activity_repository.dart';
import '../features/closed_day_exception/data/datasources/closed_day_exception_datasource.dart';
import '../features/closed_day_exception/data/repositories/closed_day_exception_repository_impl.dart';
import '../features/closed_day_exception/domain/repositories/closed_day_exception_repository.dart';
import '../features/review/data/datasources/review_datasource.dart';
import '../features/review/data/repositories/review_repository_impl.dart';
import '../features/review/domain/repositories/review_repository.dart';
import 'api_client.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Client HTTP unique
  getIt.registerLazySingleton<ApiClient>(() => ApiClient());
  getIt.registerLazySingleton<SignalRService>(() => SignalRService());

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

  // region Reservation
  // DataSource Reservation
  getIt.registerLazySingleton<ReservationDataSource>(
    () => ReservationDataSource(getIt<ApiClient>()),
  );

  // Repository Reservation
  getIt.registerLazySingleton<IReservationRepository>(
    () => ReservationRepositoryImpl(getIt<ReservationDataSource>()),
  );
  // endregion

  // region Menu
  getIt.registerLazySingleton<MenuDataSource>(
    () => MenuDataSource(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<IMenuRepository>(
    () => MenuRepositoryImpl(getIt<MenuDataSource>()),
  );
  // endregion

  // region DailyActivity
  getIt.registerLazySingleton<DailyActivityDataSource>(
    () => DailyActivityDataSource(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<IDailyActivityRepository>(
    () => DailyActivityRepositoryImpl(getIt<DailyActivityDataSource>()),
  );
  // endregion

  // region ClosedDayException
  getIt.registerLazySingleton<ClosedDayExceptionDataSource>(
    () => ClosedDayExceptionDataSource(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<IClosedDayExceptionRepository>(
    () =>
        ClosedDayExceptionRepositoryImpl(getIt<ClosedDayExceptionDataSource>()),
  );
  // endregion

  // region Review
  getIt.registerLazySingleton<ReviewDataSource>(
    () => ReviewDataSource(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<IReviewRepository>(
    () => ReviewRepositoryImpl(getIt<ReviewDataSource>()),
  );
  // endregion
}
