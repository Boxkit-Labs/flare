import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghost_app/services/api_service.dart';
import 'package:ghost_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService apiService;
  final AuthLocalDataSource localDataSource;

  AuthBloc({
    required this.apiService,
    required this.localDataSource,
  }) : super(AuthInitial()) {
    on<AppStarted>((event, emit) async {
      emit(const AuthLoading(message: 'Checking session...'));
      try {
        final userId = await localDataSource.getUserId();
        if (userId != null) {
          final user = await apiService.getUser(userId);
          apiService.userId = user.userId;
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
        emit(AuthAuthenticated(event.user));
      } catch (e) {
        emit(AuthFailure(e.toString()));
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
          emit(AuthFailure(e.toString()));
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
