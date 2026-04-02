import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:ghost_app/features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Auth
  // Bloc
  sl.registerFactory(() => AuthBloc());

  //! Core
  // No core dependencies yet (e.g. NetworkInfo)

  //! External
  sl.registerLazySingleton(() => Dio());
}
