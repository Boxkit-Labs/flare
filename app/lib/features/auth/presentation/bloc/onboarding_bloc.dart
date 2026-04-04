import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/services/api_service.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final ApiService apiService;

  OnboardingBloc(this.apiService) : super(OnboardingInitial()) {
    on<StartRegistration>((event, emit) async {
      emit(OnboardingGeneratingWallet());
      try {
        final user = await apiService.register(event.deviceId);
        emit(OnboardingWalletCreated(user));
      } catch (e) {
        emit(OnboardingFailure(e.toString()));
      }
    });

    on<FundWallet>((event, emit) async {
      emit(OnboardingFundingWallet());
      try {
        await apiService.fundWallet(event.userId);
        final wallet = await apiService.getWallet(event.userId);
        emit(OnboardingWalletFunded(wallet.balanceUsdc));
      } catch (e) {
        emit(OnboardingFailure(e.toString()));
      }
    });

    on<CreateInitialWatcher>((event, emit) async {
      emit(OnboardingCreatingWatcher());
      try {
        await apiService.createWatcher(event.watcherData);
        emit(OnboardingWatcherCreated());
      } catch (e) {
        emit(OnboardingFailure(e.toString()));
      }
    });

    on<CompleteOnboarding>((event, emit) async {
      emit(OnboardingCompleting());
      try {
        await apiService.updateSettings(event.userId, {
          'briefing_time': event.briefingTime,
        });
        final user = await apiService.getUser(event.userId);
        emit(OnboardingSuccess(user));
      } catch (e) {
        emit(OnboardingFailure(e.toString()));
      }
    });
  }
}
