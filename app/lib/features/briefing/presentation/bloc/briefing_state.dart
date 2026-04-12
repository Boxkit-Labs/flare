import 'package:equatable/equatable.dart';
import 'package:flare_app/core/models/models.dart';

abstract class BriefingState extends Equatable {
  const BriefingState();

  @override
  List<Object?> get props => [];
}

class BriefingInitial extends BriefingState {}

class BriefingLoading extends BriefingState {}

class BriefingLoaded extends BriefingState {
  final BriefingModel? todayBriefing;
  final List<BriefingModel> history;
  final Map<String, BriefingModel?> briefingsByDate;

  const BriefingLoaded({
    this.todayBriefing,
    this.history = const [],
    this.briefingsByDate = const {},
  });

  @override
  List<Object?> get props => [todayBriefing, history, briefingsByDate];
}

class BriefingError extends BriefingState {
  final String message;
  const BriefingError(this.message);

  @override
  List<Object?> get props => [message];
}

class BriefingGenerating extends BriefingState {}

class BriefingGenerated extends BriefingState {
  final BriefingModel briefing;
  const BriefingGenerated(this.briefing);

  @override
  List<Object?> get props => [briefing];
}
