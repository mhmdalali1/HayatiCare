import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationsState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final ApiService _api;

  NotificationsNotifier(this._api) : super(const NotificationsState());

  Future<void> load() async {
    state = NotificationsState(isLoading: true);
    try {
      final list = await _api.getNotifications();
      state = NotificationsState(notifications: list);
    } catch (e) {
      state = NotificationsState(error: e.toString());
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _api.markNotificationRead(id);
      state = NotificationsState(
        notifications: state.notifications
            .map((n) => n.notificationId == id
                ? NotificationModel(
                    notificationId: n.notificationId,
                    userId: n.userId,
                    type: n.type,
                    title: n.title,
                    message: n.message,
                    isRead: true,
                    createdAt: n.createdAt,
                  )
                : n)
            .toList(),
      );
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    final unread = state.notifications.where((n) => !n.isRead).toList();
    for (final n in unread) {
      await markRead(n.notificationId);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _api.deleteNotification(id);
      state = NotificationsState(
        notifications:
            state.notifications.where((n) => n.notificationId != id).toList(),
      );
    } catch (_) {}
  }

  Future<void> deleteAll() async {
    for (final n in state.notifications) {
      await delete(n.notificationId);
    }
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ApiService());
});
