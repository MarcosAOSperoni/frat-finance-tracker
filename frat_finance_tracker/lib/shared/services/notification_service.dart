import 'package:frat_finance_tracker/shared/services/supabase_service.dart';

class NotificationService {
  /// Send personalized payment reminder push notifications to all brothers with unpaid dues.
  /// Each brother receives: "You owe $[next payment amount] due on [next payment date]"
  /// Only brothers with unpaid dues and a registered device token are notified.
  static Future<Map<String, dynamic>> sendPaymentReminderNotifications() async {
    try {
      final client = SupabaseService.client;

      final response = await client.functions.invoke(
        'send-payment-reminders',
        body: {},
      );

      if (response.status == 200) {
        print('✅ Payment reminders sent successfully');
        print('Response: ${response.data}');
        return {
          'success': true,
          'data': response.data,
        };
      } else {
        print('⚠️ Failed to send payment reminders: ${response.status}');
        print('Error: ${response.data}');
        return {
          'success': false,
          'error': 'Failed to send notifications (status ${response.status})',
        };
      }
    } catch (e) {
      print('❌ Error calling payment reminder function: $e');
      return {
        'success': false,
        'error': 'An error occurred while sending notifications.',
      };
    }
  }

  /// Send notification when new dues period is created
  static Future<void> sendDuesCreatedNotification({
    required String duesPeriodId,
    required String duesPeriodName,
    required double totalAmount,
    required String dueDate,
  }) async {
    try {
      final client = SupabaseService.client;

      // Call the Edge Function
      final response = await client.functions.invoke(
        'send-dues-notification',
        body: {
          'duesPeriodId': duesPeriodId,
          'duesPeriodName': duesPeriodName,
          'totalAmount': totalAmount,
          'dueDate': dueDate,
        },
      );

      if (response.status == 200) {
        print('✅ Notifications sent successfully');
        print('Response: ${response.data}');
      } else {
        print('⚠️ Failed to send notifications: ${response.status}');
        print('Error: ${response.data}');
      }
    } catch (e) {
      print('❌ Error calling notification function: $e');
      // Don't throw - we don't want dues creation to fail if notifications fail
    }
  }
}
