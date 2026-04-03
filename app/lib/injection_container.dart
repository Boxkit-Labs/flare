import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:ghost_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ghost_app/services/api_service.dart';
import 'package:ghost_app/services/notification_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! External
  sl.registerLazySingleton(() => Dio());

  //! Services
  sl.registerLazySingleton(() => ApiService());
  sl.registerLazySingleton(() => NotificationService(sl<ApiService>()));

  //! Features - Auth
  // Bloc
  sl.registerFactory(() => AuthBloc());
}
