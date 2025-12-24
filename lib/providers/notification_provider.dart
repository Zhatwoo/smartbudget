import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';

/// Notification Service Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Notifications Stream Provider
/// Streams all notifications for the current user
/// Used by Notifications screen
final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.getNotifications();
});

/// Unread Notifications Count Provider
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  if (notifications.value == null) return 0;
  return notifications.value!.where((n) => !n.isRead).length;
});


