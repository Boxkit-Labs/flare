import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flare_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flare_app/features/auth/presentation/bloc/onboarding_bloc.dart';
import 'package:flare_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:flare_app/features/findings/presentation/bloc/findings_bloc.dart';
import 'package:flare_app/features/watchers/presentation/bloc/watchers_bloc.dart';
import 'package:flare_app/features/briefing/presentation/bloc/briefing_bloc.dart';
import 'package:flare_app/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flare_app/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:flare_app/features/events/presentation/bloc/event_search_bloc.dart';
import 'package:flare_app/features/events/presentation/bloc/event_detail_bloc.dart';
import 'package:flare_app/features/events/presentation/bloc/event_price_history_bloc.dart';
import 'package:flare_app/features/events/presentation/bloc/event_watch_setup_bloc.dart';
import 'package:flare_app/features/events/domain/repositories/event_repository.dart';
import 'package:flare_app/features/events/data/repositories/event_repository_impl.dart';
import 'package:flare_app/features/events/data/datasources/event_remote_data_source.dart';
import 'package:flare_app/features/events/domain/usecases/search_events_usecase.dart';
import 'package:flare_app/features/events/domain/usecases/get_event_detail_usecase.dart';
import 'package:flare_app/features/events/domain/usecases/get_event_price_history_usecase.dart';
import 'package:flare_app/features/events/domain/usecases/create_event_watcher_usecase.dart';
import 'package:flare_app/features/events/domain/usecases/get_platforms_usecase.dart';
import 'package:flare_app/features/events/domain/usecases/get_countries_usecase.dart';
import 'package:flare_app/features/events/domain/usecases/get_categories_usecase.dart';
import 'package:flare_app/features/watchers/domain/repositories/watcher_repository.dart';
import 'package:flare_app/features/watchers/data/repositories/watcher_repository_impl.dart';
import 'package:flare_app/features/watchers/data/datasources/watcher_remote_data_source.dart';
import 'package:flare_app/services/api_service.dart';
import 'package:flare_app/services/notification_service.dart';
import 'package:flare_app/core/config/app_constants.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Reset GetIt on hot restart to prevent stale singletons
  if (sl.isRegistered<ApiService>()) {
    await sl.reset();
  }
  //! Features - Auth
  // Bloc
  sl.registerLazySingleton(() => AuthBloc(
        apiService: sl(),
        localDataSource: sl(),
        notificationService: sl(),
      ));
  sl.registerFactory(() => OnboardingBloc(sl()));

  // Data sources
  final authBox = await Hive.openBox('auth_box');
  sl.registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(authBox));

  //! Features - Watchers
  sl.registerFactory(() => WatchersBloc(sl()));

  sl.registerLazySingleton<WatcherRepository>(
      () => WatcherRepositoryImpl(sl()));
  sl.registerLazySingleton<WatcherRemoteDataSource>(
      () => WatcherRemoteDataSourceImpl(sl()));

  //! Features - Findings
  sl.registerFactory(() => FindingsBloc(sl()));

  //! Features - Briefing
  sl.registerFactory(() => BriefingBloc(sl()));

  //! Features - Wallet
  sl.registerFactory(() => WalletBloc(sl()));

  //! Features - Notifications
  sl.registerFactory(() => NotificationsBloc(sl()));

  //! Features - Events
  // Bloc
  sl.registerFactory(() => EventSearchBloc(searchEventsUseCase: sl()));
  sl.registerFactory(() => EventDetailBloc(getEventDetailUseCase: sl()));
  sl.registerFactory(() => EventPriceHistoryBloc(getPriceHistoryUseCase: sl()));
  sl.registerFactory(() => EventWatchSetupBloc(createEventWatcherUseCase: sl()));

  // Use cases
  sl.registerLazySingleton(() => SearchEventsUseCase(sl()));
  sl.registerLazySingleton(() => GetEventDetailUseCase(sl()));
  sl.registerLazySingleton(() => GetEventPriceHistoryUseCase(sl()));
  sl.registerLazySingleton(() => CreateEventWatcherUseCase(sl()));
  sl.registerLazySingleton(() => GetPlatformsUseCase(sl()));
  sl.registerLazySingleton(() => GetCountriesUseCase(sl()));
  sl.registerLazySingleton(() => GetCategoriesUseCase(sl()));

  // Repository
  sl.registerLazySingleton<EventRepository>(
      () => EventRepositoryImpl(sl()));

  // Data sources
  sl.registerLazySingleton<EventRemoteDataSource>(
      () => EventRemoteDataSourceImpl(sl()));

  //! Services
  sl.registerLazySingleton(() => ApiService());
  sl.registerLazySingleton(() => NotificationService(sl<ApiService>()));

  //! External
  sl.registerLazySingleton(() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));
    return dio;
  });
}
