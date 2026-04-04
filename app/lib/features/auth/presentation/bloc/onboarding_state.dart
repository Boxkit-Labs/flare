import 'package:equatable/equatable.dart';
import 'package:flare_app/core/models/models.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {}

class OnboardingGeneratingWallet extends OnboardingState {}

class OnboardingWalletCreated extends OnboardingState {
  final UserModel user;
  const OnboardingWalletCreated(this.user);

  @override
  List<Object?> get props => [user];
}

class OnboardingFundingWallet extends OnboardingState {}

class OnboardingWalletFunded extends OnboardingState {
  final double balance;
  const OnboardingWalletFunded(this.balance);

  @override
  List<Object?> get props => [balance];
}

class OnboardingCreatingWatcher extends OnboardingState {}

class OnboardingWatcherCreated extends OnboardingState {}

class OnboardingCompleting extends OnboardingState {}

class OnboardingSuccess extends OnboardingState {
  final UserModel user;
  const OnboardingSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

class OnboardingFailure extends OnboardingState {
  final String errorMessage;
  const OnboardingFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
