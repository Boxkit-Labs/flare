import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AppStarted>((event, emit) async {
      emit(AuthLoading());
      // Logic to check auth status...
      emit(AuthUnauthenticated());
    });
    
    on<LoggedOut>((event, emit) async {
      emit(AuthUnauthenticated());
    });
  }
}
