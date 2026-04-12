import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/services/api_service.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';
import 'package:flare_app/core/utils/error_formatter.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final ApiService apiService;

  NotificationsBloc(this.apiService) : super(NotificationsInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<LoadUnreadCount>(_onLoadUnreadCount);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    if (!event.isRefresh) emit(NotificationsLoading());
    try {
      final notifications = await apiService.getNotifications(event.userId);
      final unreadCount = await apiService.getUnreadNotificationCount(event.userId);
      emit(NotificationsLoaded(
        notifications: notifications,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      emit(NotificationsError(ErrorFormatter.format(e)));
    }
  }

  Future<void> _onLoadUnreadCount(
    LoadUnreadCount event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      final count = await apiService.getUnreadNotificationCount(event.userId);
      if (state is NotificationsLoaded) {
        final currentState = state as NotificationsLoaded;
        emit(NotificationsLoaded(
          notifications: currentState.notifications,
          unreadCount: count,
        ));
      } else {
        emit(NotificationsLoaded(
          notifications: const [],
          unreadCount: count,
        ));
      }
    } catch (e) {

    }
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      await apiService.markNotificationRead(event.notificationId, event.userId);
      if (state is NotificationsLoaded) {
        final currentState = state as NotificationsLoaded;
        final updatedNotifications = currentState.notifications.map((n) {
          if (n.notificationId == event.notificationId) {
            return n.copyWith(read: true);
          }
          return n;
        }).toList();

        final newCount = (currentState.unreadCount - 1).clamp(0, double.infinity).toInt();
        emit(NotificationsLoaded(
          notifications: updatedNotifications,
          unreadCount: newCount,
        ));
      }
    } catch (e) {

    }
  }
}
