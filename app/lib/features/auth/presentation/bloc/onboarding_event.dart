import 'package:equatable/equatable.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

class StartRegistration extends OnboardingEvent {
  final String deviceId;
  const StartRegistration(this.deviceId);

  @override
  List<Object?> get props => [deviceId];
}

class FundWallet extends OnboardingEvent {
  final String userId;
  const FundWallet(this.userId);

  @override
  List<Object?> get props => [userId];
}

class CreateInitialWatcher extends OnboardingEvent {
  final Map<String, dynamic> watcherData;
  const CreateInitialWatcher(this.watcherData);

  @override
  List<Object?> get props => [watcherData];
}

class CompleteOnboarding extends OnboardingEvent {
  final String userId;
  final String briefingTime;
  const CompleteOnboarding(this.userId, this.briefingTime);

  @override
  List<Object?> get props => [userId, briefingTime];
}

class UpdateBriefingTime extends OnboardingEvent {
  final String userId;
  final String briefingTime;
  const UpdateBriefingTime(this.userId, this.briefingTime);

  @override
  List<Object?> get props => [userId, briefingTime];
}
