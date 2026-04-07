import 'package:equatable/equatable.dart';

abstract class BriefingEvent extends Equatable {
  const BriefingEvent();

  @override
  List<Object?> get props => [];
}

class LoadTodayBriefing extends BriefingEvent {
  final String userId;
  final bool isRefresh;
  const LoadTodayBriefing(this.userId, {this.isRefresh = false});

  @override
  List<Object?> get props => [userId, isRefresh];
}

class LoadBriefingHistory extends BriefingEvent {
  final String userId;
  final int limit;
  const LoadBriefingHistory(this.userId, {this.limit = 7});

  @override
  List<Object?> get props => [userId, limit];
}

class GenerateManualBriefing extends BriefingEvent {
  final String userId;
  const GenerateManualBriefing(this.userId);

  @override
  List<Object?> get props => [userId];
}

class MarkBriefingRead extends BriefingEvent {
  final String briefingId;
  const MarkBriefingRead(this.briefingId);

  @override
  List<Object?> get props => [briefingId];
}

class LoadBriefingByDate extends BriefingEvent {
  final String userId;
  final DateTime date;
  
  const LoadBriefingByDate(this.userId, this.date);

  @override
  List<Object?> get props => [userId, date];
}
