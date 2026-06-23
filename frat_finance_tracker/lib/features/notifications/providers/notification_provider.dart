import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frat_finance_tracker/features/auth/providers/auth_provider.dart';
import 'package:frat_finance_tracker/features/notifications/data/notification_repository.dart';
import 'package:frat_finance_tracker/features/notifications/domain/notification.dart';

// Repository provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

// Get all notifications for current user
final notificationsProvider = StreamProvider.autoDispose<List<AppNotification>>((ref) async* {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    yield [];
    return;
  }

  final repository = ref.watch(notificationRepositoryProvider);

  // Initial fetch
  yield await repository.getNotifications(user.id);

  // Refresh every 30 seconds to check for new notifications
  await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
    final notifications = await repository.getNotifications(user.id);
    yield notifications;
  }
});

// Get unread notification count
final unreadCountProvider = StreamProvider.autoDispose<int>((ref) async* {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    yield 0;
    return;
  }

  final repository = ref.watch(notificationRepositoryProvider);

  // Initial fetch
  yield await repository.getUnreadCount(user.id);

  // Refresh every 30 seconds
  await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
    final count = await repository.getUnreadCount(user.id);
    yield count;
  }
});

// Mark notification as read
final markAsReadProvider = Provider<Future<bool> Function(String)>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return (String notificationId) async {
    final result = await repository.markAsRead(notificationId);
    if (result) {
      // Invalidate providers to refresh data
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadCountProvider);
    }
    return result;
  };
});

// Mark all notifications as read
final markAllAsReadProvider = Provider<Future<bool> Function()>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  final user = ref.watch(authStateProvider).value;

  return () async {
    if (user == null) return false;

    final result = await repository.markAllAsRead(user.id);
    if (result) {
      // Invalidate providers to refresh data
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadCountProvider);
    }
    return result;
  };
});

// Send payment reminders to all brothers with outstanding dues
final sendPaymentRemindersProvider = Provider<Future<Map<String, dynamic>> Function()>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);

  return () async {
    final result = await repository.sendPaymentReminders();
    if (result['success'] == true) {
      // Invalidate providers to refresh notification counts
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadCountProvider);
    }
    return result;
  };
});
