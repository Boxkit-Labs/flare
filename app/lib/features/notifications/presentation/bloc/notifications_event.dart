import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationsEvent {
  final String userId;
  final bool isRefresh;

  const LoadNotifications(this.userId, {this.isRefresh = false});

  @override
  List<Object?> get props => [userId, isRefresh];
}

class LoadUnreadCount extends NotificationsEvent {
  final String userId;

  const LoadUnreadCount(this.userId);

  @override
  List<Object?> get props => [userId];
}

class MarkNotificationAsRead extends NotificationsEvent {
  final String notificationId;
  final String userId;

  const MarkNotificationAsRead(this.notificationId, this.userId);

  @override
  List<Object?> get props => [notificationId, userId];
}
