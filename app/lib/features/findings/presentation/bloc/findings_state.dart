import 'package:equatable/equatable.dart';
import 'package:flare_app/core/models/models.dart';

abstract class FindingsState extends Equatable {
  const FindingsState();

  @override
  List<Object?> get props => [];
}

class FindingsInitial extends FindingsState {}

class FindingsLoading extends FindingsState {}

class FindingsLoaded extends FindingsState {
  final List<FindingModel> findings;
  final int unreadCount;
  const FindingsLoaded(this.findings, this.unreadCount);

  @override
  List<Object?> get props => [findings, unreadCount];
}

class FindingDetailLoaded extends FindingsState {
  final FindingModel finding;
  const FindingDetailLoaded(this.finding);

  @override
  List<Object?> get props => [finding];
}

class FindingsError extends FindingsState {
  final String message;
  const FindingsError(this.message);

  @override
  List<Object?> get props => [message];
}
