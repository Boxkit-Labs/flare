import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/services/api_service.dart';
import 'package:flare_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:flare_app/core/utils/error_formatter.dart';
import 'package:flare_app/services/notification_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService apiService;
  final AuthLocalDataSource localDataSource;
  final NotificationService notificationService;

  AuthBloc({
    required this.apiService,
    required this.localDataSource,
    required this.notificationService,
  }) : super(AuthInitial()) {
    on<AppStarted>((event, emit) async {
      emit(const AuthLoading(message: 'Waking up Flare server... (Takes ~40s on first launch)'));
      
      // 1. Wake up the backend (handling cold starts)
      final stopwatch = Stopwatch()..start();
      final isHealthy = await apiService.checkHealth();
      stopwatch.stop();

      if (!isHealthy) {
        debugPrint('AuthBloc: Backend not responding after retries.');
      } else if (stopwatch.elapsed.inSeconds > 5) {
        emit(const AuthLoading(message: 'Flare has awakened! Finalizing setup...'));
        await Future.delayed(const Duration(milliseconds: 1000));
      }


      emit(const AuthLoading(message: 'Checking session...'));
      try {
        final userId = await localDataSource.getUserId();
        if (userId != null) {
          final user = await apiService.getUser(userId);
          apiService.userId = user.userId;
          notificationService.setUserId(user.userId);
          emit(AuthAuthenticated(user));
        } else {
          emit(AuthUnauthenticated());
        }
      } catch (e) {
        emit(AuthUnauthenticated());
      }
    });

    on<UserRegistered>((event, emit) async {
      emit(const AuthLoading(message: 'Finishing setup...'));
      try {
        await localDataSource.cacheUserId(event.user.userId);
        apiService.userId = event.user.userId;
        notificationService.setUserId(event.user.userId);
        emit(AuthAuthenticated(event.user));
      } catch (e) {
        emit(AuthFailure(ErrorFormatter.format(e)));
      }
    });

    on<UpdateUserSettings>((event, emit) async {
      if (state is AuthAuthenticated) {
        final currentUser = (state as AuthAuthenticated).user;
        emit(const AuthLoading(message: 'Updating settings...'));
        try {
          await apiService.updateSettings(currentUser.userId, event.settings);
          final updatedUser = await apiService.getUser(currentUser.userId);
          emit(AuthAuthenticated(updatedUser));
        } catch (e) {
          emit(AuthFailure(ErrorFormatter.format(e)));
        }
      }
    });

    on<LoggedOut>((event, emit) async {
      await localDataSource.clear();
      apiService.userId = null;
      emit(AuthUnauthenticated());
    });
  }
}
