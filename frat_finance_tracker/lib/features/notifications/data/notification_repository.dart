import 'package:frat_finance_tracker/features/notifications/domain/notification.dart';
import 'package:frat_finance_tracker/shared/services/supabase_service.dart';

class NotificationRepository {
  final _client = SupabaseService.client;

  // Get all notifications for a user
  Future<List<AppNotification>> getNotifications(String userId) async {
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  // Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('read', false);

      return (response as List).length;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'read': true})
          .eq('id', notificationId);
      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllAsRead(String userId) async {
    try {
      await _client
          .from('notifications')
          .update({'read': true})
          .eq('user_id', userId)
          .eq('read', false);
      return true;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  // Create notification (used when dues are created)
  Future<bool> createNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? relatedDuesId,
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type.value,
        'related_dues_id': relatedDuesId,
      });
      return true;
    } catch (e) {
      print('Error creating notification: $e');
      return false;
    }
  }

  // Create notifications for multiple users (bulk create when dues assigned)
  Future<bool> createNotificationsForUsers({
    required List<String> userIds,
    required String title,
    required String body,
    required NotificationType type,
    String? relatedDuesId,
  }) async {
    try {
      final notifications = userIds.map((userId) => {
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type.value,
        'related_dues_id': relatedDuesId,
      }).toList();

      await _client.from('notifications').insert(notifications);
      return true;
    } catch (e) {
      print('Error creating bulk notifications: $e');
      return false;
    }
  }

  // Get users with outstanding dues (for Monday reminders)
  Future<List<Map<String, dynamic>>> getUsersWithOutstandingDues() async {
    try {
      final response = await _client
          .from('brother_dues')
          .select('brother_id, total_amount, amount_paid, dues_periods(name)')
          .gt('total_amount', 0) // Has dues
          .neq('status', 'paid'); // Not fully paid

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching users with outstanding dues: $e');
      return [];
    }
  }

  // Check if Monday reminder already sent this week
  Future<bool> hasReminderThisWeek(String userId, String duesId) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('related_dues_id', duesId)
          .eq('type', 'payment_reminder')
          .gte('created_at', startOfWeek.toIso8601String());

      return (response as List).isNotEmpty;
    } catch (e) {
      print('Error checking reminder: $e');
      return false;
    }
  }

  // Send payment reminders to all brothers with outstanding dues
  Future<Map<String, dynamic>> sendPaymentReminders() async {
    try {
      // Get all brothers with outstanding dues
      final usersWithDues = await getUsersWithOutstandingDues();

      if (usersWithDues.isEmpty) {
        return {
          'success': true,
          'message': 'No brothers with outstanding dues',
          'count': 0
        };
      }

      int remindersSent = 0;
      int remindersSkipped = 0;

      // For each brother with outstanding dues
      for (final duesData in usersWithDues) {
        final brotherId = duesData['brother_id'] as String;
        final totalAmount = (duesData['total_amount'] as num).toDouble();
        final amountPaid = (duesData['amount_paid'] as num).toDouble();
        final remaining = totalAmount - amountPaid;

        // Extract dues period name from nested object
        final duesPeriodData = duesData['dues_periods'];
        final duesPeriodName = duesPeriodData is Map
            ? (duesPeriodData['name'] as String?) ?? 'Dues'
            : 'Dues';

        // Get the brother_dues ID (we'll use it as relatedDuesId)
        // Note: The query doesn't return the brother_dues id, so we'll need to fetch it
        final brotherDuesResponse = await _client
            .from('brother_dues')
            .select('id')
            .eq('brother_id', brotherId)
            .neq('status', 'paid')
            .single();

        final brotherDuesId = brotherDuesResponse['id'] as String;

        // Check if reminder already sent this week for this dues
        final alreadySent = await hasReminderThisWeek(brotherId, brotherDuesId);

        if (alreadySent) {
          remindersSkipped++;
          continue;
        }

        // Send reminder notification
        await createNotification(
          userId: brotherId,
          title: 'Payment Reminder',
          body: 'You have \$${remaining.toStringAsFixed(2)} remaining for $duesPeriodName',
          type: NotificationType.paymentReminder,
          relatedDuesId: brotherDuesId,
        );

        remindersSent++;
      }

      return {
        'success': true,
        'message': 'Sent $remindersSent reminders (skipped $remindersSkipped already sent this week)',
        'count': remindersSent,
        'skipped': remindersSkipped
      };
    } catch (e) {
      print('Error sending payment reminders: $e');
      return {
        'success': false,
        'error': 'Failed to send reminders: $e'
      };
    }
  }
}
