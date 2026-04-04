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
import 'package:flare_app/services/api_service.dart';
import 'package:flare_app/services/notification_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Auth
  // Bloc
  sl.registerLazySingleton(() => AuthBloc(
        apiService: sl(),
        localDataSource: sl(),
      ));
  sl.registerFactory(() => OnboardingBloc(sl()));

  // Data sources
  final authBox = await Hive.openBox('auth_box');
  sl.registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(authBox));

  //! Features - Watchers
  sl.registerFactory(() => WatchersBloc(sl()));

  //! Features - Findings
  sl.registerFactory(() => FindingsBloc(sl()));

  //! Features - Briefing
  sl.registerFactory(() => BriefingBloc(sl()));

  //! Features - Wallet
  sl.registerFactory(() => WalletBloc(sl()));

  //! Services
  sl.registerLazySingleton(() => ApiService());
  sl.registerLazySingleton(() => NotificationService(sl<ApiService>()));

  //! External
  sl.registerLazySingleton(() => Dio());
}
