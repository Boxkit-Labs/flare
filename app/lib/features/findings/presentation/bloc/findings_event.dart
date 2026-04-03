import 'package:equatable/equatable.dart';

abstract class FindingsEvent extends Equatable {
  const FindingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadFindings extends FindingsEvent {
  final String userId;
  final int limit;
  final int offset;
  const LoadFindings(this.userId, {this.limit = 50, this.offset = 0});

  @override
  List<Object?> get props => [userId, limit, offset];
}

class MarkFindingAsRead extends FindingsEvent {
  final String findingId;
  const MarkFindingAsRead(this.findingId);

  @override
  List<Object?> get props => [findingId];
}

class LoadFindingDetail extends FindingsEvent {
  final String findingId;
  const LoadFindingDetail(this.findingId);

  @override
  List<Object?> get props => [findingId];
}
