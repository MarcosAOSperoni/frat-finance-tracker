import 'package:frat_finance_tracker/features/payments/domain/brother_dues.dart';
import 'package:frat_finance_tracker/features/payments/domain/payment_plan.dart';
import 'package:frat_finance_tracker/features/auth/domain/app_user.dart';
import 'package:frat_finance_tracker/shared/services/supabase_service.dart';
import 'package:frat_finance_tracker/shared/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frat_finance_tracker/features/notifications/data/notification_repository.dart';
import 'package:frat_finance_tracker/features/notifications/domain/notification.dart';
import 'package:intl/intl.dart';

class PaymentsRepository {
  final _client = SupabaseService.client;
  final _auth = SupabaseService.auth;
  final _notificationRepository = NotificationRepository();

  // Helper: Get current user profile
  Future<AppUser?> _getCurrentUserProfile() async {
    final session = _auth.currentSession;
    if (session == null) return null;

    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', session.user.id)
          .single();

      return AppUser.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Get all dues for a specific brother
  Future<List<BrotherDues>> getBrotherDues(String brotherId) async {
    try {
      final response = await _client
          .from('brother_dues')
          .select('*, dues_periods(name)')
          .eq('brother_id', brotherId)
          .order('due_date', ascending: true);

      return (response as List)
          .map((json) => BrotherDues.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching brother dues: $e');
      return [];
    }
  }

  // Get payment history for a specific dues
  Future<List<Payment>> getPaymentHistory(String brotherDuesId) async {
    try {
      final response = await _client
          .from('payments')
          .select()
          .eq('brother_dues_id', brotherDuesId)
          .order('payment_date', ascending: false);

      return (response as List).map((json) => Payment.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching payment history: $e');
      return [];
    }
  }

  // Get all payment history for a brother (across all dues)
  Future<List<Payment>> getAllBrotherPayments(String brotherId) async {
    try {
      // First get all brother_dues IDs for this brother
      final duesResponse = await _client
          .from('brother_dues')
          .select('id')
          .eq('brother_id', brotherId);

      final duesIds = (duesResponse as List)
          .map((item) => item['id'] as String)
          .toList();

      if (duesIds.isEmpty) return [];

      // Then get all payments for those dues
      final paymentsResponse = await _client
          .from('payments')
          .select()
          .inFilter('brother_dues_id', duesIds)
          .order('payment_date', ascending: false);

      return (paymentsResponse as List)
          .map((json) => Payment.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching all brother payments: $e');
      return [];
    }
  }

  // VP of Finance: Get all brothers with their dues
  Future<List<Map<String, dynamic>>> getAllBrothersDues() async {
    try {
      final response = await _client
          .from('brother_dues')
          .select('*, users(id, full_name, email), dues_periods(name)')
          .order('due_date', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching all brothers dues: $e');
      return [];
    }
  }

  // VP of Finance: Record a payment for a brother
  Future<Map<String, dynamic>> recordPayment({
    required String brotherDuesId,
    required double amount,
    required DateTime paymentDate,
    required String recordedBy, // VP user ID who is recording the payment
    String? paymentMethod,
    String? notes,
    String? scheduledPaymentId, // Optional: link to a scheduled payment
  }) async {
    try {
      // SECURITY: Verify current user is VP of Finance
      final currentUser = await _getCurrentUserProfile();
      if (currentUser == null) {
        return {
          'success': false,
          'error': 'Not authenticated'
        };
      }

      if (currentUser.role != UserRole.vpFinance) {
        return {
          'success': false,
          'error': 'Unauthorized: Only VP of Finance can record payments'
        };
      }

      // Verify recordedBy matches current user
      if (recordedBy != currentUser.id) {
        return {
          'success': false,
          'error': 'Invalid payment data: recordedBy must match current user'
        };
      }

      // Security: Validate inputs
      if (brotherDuesId.isEmpty || recordedBy.isEmpty) {
        return {
          'success': false,
          'error': 'Invalid payment data: missing required IDs'
        };
      }

      if (amount <= 0) {
        return {
          'success': false,
          'error': 'Payment amount must be greater than zero'
        };
      }

      if (amount > 100000) {
        return {
          'success': false,
          'error': 'Payment amount exceeds maximum allowed (\$100,000)'
        };
      }

      // Security: Validate payment date
      final now = DateTime.now();
      final maxPastDate = now.subtract(const Duration(days: 365 * 2)); // 2 years ago

      if (paymentDate.isAfter(now)) {
        return {
          'success': false,
          'error': 'Payment date cannot be in the future'
        };
      }

      if (paymentDate.isBefore(maxPastDate)) {
        return {
          'success': false,
          'error': 'Payment date cannot be more than 2 years in the past'
        };
      }

      // Security: Sanitize notes and payment method (prevent XSS)
      final sanitizedNotes = notes?.trim().replaceAll(RegExp(r'[<>]'), '');
      final sanitizedMethod = paymentMethod?.trim().replaceAll(RegExp(r'[<>]'), '');

      if (sanitizedMethod != null && sanitizedMethod.length > 50) {
        return {
          'success': false,
          'error': 'Payment method name is too long (max 50 characters)'
        };
      }

      // Get the brother_dues to validate against remaining amount
      final duesResponse = await _client
          .from('brother_dues')
          .select('total_amount, amount_paid')
          .eq('id', brotherDuesId)
          .single();

      final totalAmount = (duesResponse['total_amount'] as num).toDouble();
      final amountPaid = (duesResponse['amount_paid'] as num).toDouble();
      final remaining = totalAmount - amountPaid;

      // Security: Prevent overpayment
      if (amount > remaining + 0.01) { // Allow 1 cent tolerance for rounding
        return {
          'success': false,
          'error': 'Payment amount (\$${amount.toStringAsFixed(2)}) exceeds remaining balance (\$${remaining.toStringAsFixed(2)})'
        };
      }

      // Insert the payment
      final paymentResponse = await _client.from('payments').insert({
        'brother_dues_id': brotherDuesId,
        'amount': amount,
        'payment_date': paymentDate.toIso8601String(),
        'payment_method': sanitizedMethod,
        'notes': sanitizedNotes,
        'recorded_by': recordedBy,
      }).select().single();

      // If linked to a scheduled payment, mark it as paid
      if (scheduledPaymentId != null) {
        final paymentId = paymentResponse['id'] as String;

        // Get this scheduled payment's info for overflow calculation
        final spResponse = await _client
            .from('scheduled_payments')
            .select('scheduled_amount, payment_plan_id')
            .eq('id', scheduledPaymentId)
            .single();

        final spScheduledAmount = (spResponse['scheduled_amount'] as num).toDouble();
        final paymentPlanId = spResponse['payment_plan_id'] as String;

        // Mark this SP as paid (for its scheduled amount, not the full payment which may overflow)
        await _client.from('scheduled_payments').update({
          'status': 'paid',
          'paid_amount': spScheduledAmount,
          'paid_date': paymentDate.toIso8601String().split('T')[0],
          'payment_id': paymentId,
        }).eq('id', scheduledPaymentId);

        // Handle overflow: apply excess to subsequent pending SPs in order
        double overflow = amount - spScheduledAmount;
        if (overflow > 0.01) {
          final nextSPsResponse = await _client
              .from('scheduled_payments')
              .select()
              .eq('payment_plan_id', paymentPlanId)
              .eq('status', 'pending')
              .order('payment_number', ascending: true);

          for (final nextSP in nextSPsResponse as List) {
            if (overflow <= 0.01) break;
            final nextAmount = (nextSP['scheduled_amount'] as num).toDouble();

            if (overflow >= nextAmount - 0.01) {
              // Fully cover this SP with overflow
              await _client.from('scheduled_payments').update({
                'status': 'paid',
                'paid_amount': nextAmount,
                'paid_date': paymentDate.toIso8601String().split('T')[0],
                'payment_id': paymentId,
              }).eq('id', nextSP['id'] as String);
              overflow -= nextAmount;
            } else {
              // Partially reduce this SP's scheduled amount
              await _client.from('scheduled_payments').update({
                'scheduled_amount': nextAmount - overflow,
              }).eq('id', nextSP['id'] as String);
              overflow = 0;
            }
          }
        }
      }

      return {'success': true};
    } on PostgrestException catch (e) {
      print('Database error recording payment: ${e.message}');
      return {
        'success': false,
        'error': 'Database error: ${e.message}'
      };
    } catch (e) {
      print('Unexpected error recording payment: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred. Please try again.'
      };
    }
  }

  // VP of Finance: Get all brothers (including VP, since VP is also a brother)
  Future<List<Map<String, dynamic>>> getAllBrothers() async {
    try {
      final response = await _client
          .from('users')
          .select('id, full_name, email, role, brother_status')
          .inFilter('role', ['brother', 'vp_finance']) // Include both brothers and VP
          .order('full_name', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching brothers: $e');
      return [];
    }
  }

  // VP of Finance: Create a dues period and assign to selected brothers
  Future<Map<String, dynamic>> createDuesPeriod({
    required String name,
    required double totalAmount,
    required DateTime startDate,
    required DateTime dueDate,
    required Map<String, int> brotherPaymentCounts, // brotherId -> number of payments
    required String createdBy, // VP user ID
    String? notes,
    Map<String, List<DateTime>>? brotherCustomDates,
  }) async {
    try {
      // SECURITY: Verify current user is VP of Finance
      final currentUser = await _getCurrentUserProfile();
      if (currentUser == null) {
        return {
          'success': false,
          'error': 'Not authenticated'
        };
      }

      if (currentUser.role != UserRole.vpFinance) {
        return {
          'success': false,
          'error': 'Unauthorized: Only VP of Finance can create dues periods'
        };
      }

      // Verify createdBy matches current user
      if (createdBy != currentUser.id) {
        return {
          'success': false,
          'error': 'Invalid data: createdBy must match current user'
        };
      }

      // Security: Validate inputs
      if (name.trim().isEmpty) {
        return {
          'success': false,
          'error': 'Dues period name cannot be empty'
        };
      }

      if (name.length > 100) {
        return {
          'success': false,
          'error': 'Dues period name is too long (max 100 characters)'
        };
      }

      if (totalAmount <= 0) {
        return {
          'success': false,
          'error': 'Dues amount must be greater than zero'
        };
      }

      if (totalAmount > 100000) {
        return {
          'success': false,
          'error': 'Dues amount exceeds maximum allowed (\$100,000)'
        };
      }

      // Security: Validate dates
      final now = DateTime.now();
      final maxDate = now.add(const Duration(days: 365 * 2));

      if (dueDate.isAfter(maxDate)) {
        return {
          'success': false,
          'error': 'Due date cannot be more than 2 years in the future'
        };
      }

      if (dueDate.isBefore(startDate)) {
        return {
          'success': false,
          'error': 'Due date must be after start date'
        };
      }

      if (brotherPaymentCounts.isEmpty) {
        return {
          'success': false,
          'error': 'You must select at least one brother'
        };
      }

      if (createdBy.isEmpty) {
        return {
          'success': false,
          'error': 'Invalid creator ID'
        };
      }

      // Security: Sanitize inputs (prevent XSS)
      final sanitizedName = name.trim().replaceAll(RegExp(r'[<>]'), '');
      final sanitizedNotes = notes?.trim().replaceAll(RegExp(r'[<>]'), '');

      final brotherIds = brotherPaymentCounts.keys.toList();

      // 1. Create the dues period
      final duesPeriodResponse = await _client
          .from('dues_periods')
          .insert({
            'name': sanitizedName,
            'total_amount': totalAmount,
            'start_date': startDate.toIso8601String().split('T')[0],
            'due_date': dueDate.toIso8601String().split('T')[0],
            'created_by': createdBy,
          })
          .select()
          .single();

      final duesPeriodId = duesPeriodResponse['id'] as String;

      // 2. Manually create brother_dues for each selected brother
      final brotherDuesInserts = brotherIds.map((brotherId) => {
        'brother_id': brotherId,
        'dues_period_id': duesPeriodId,
        'total_amount': totalAmount,
        'amount_paid': 0,
        'status': 'pending',
        'due_date': dueDate.toIso8601String().split('T')[0],
      }).toList();

      final brotherDuesResponse = await _client
          .from('brother_dues')
          .insert(brotherDuesInserts)
          .select();

      // 3. Create payment plans for each brother
      final totalDays = dueDate.difference(startDate).inDays;

      for (final brotherDues in brotherDuesResponse as List) {
        final brotherDuesId = brotherDues['id'] as String;
        final brotherId = brotherDues['brother_id'] as String;
        final numberOfPayments = brotherPaymentCounts[brotherId] ?? 1;

        if (numberOfPayments < 1 || totalDays < numberOfPayments) continue;

        // Create payment plan
        final planResponse = await _client
            .from('payment_plans')
            .insert({
              'brother_dues_id': brotherDuesId,
              'total_payments': numberOfPayments,
            })
            .select()
            .single();

        final paymentPlanId = planResponse['id'] as String;

        // Calculate payment amounts and dates (use custom dates if provided)
        final amountPerPayment = totalAmount / numberOfPayments;
        final daysPerPayment = totalDays / numberOfPayments;
        final customDates = brotherCustomDates?[brotherId];

        final scheduledPayments = <Map<String, dynamic>>[];
        for (int i = 0; i < numberOfPayments; i++) {
          DateTime scheduledDate;
          if (customDates != null && i < customDates.length) {
            scheduledDate = customDates[i];
          } else {
            final daysToAdd = (daysPerPayment * (i + 1)).round();
            scheduledDate = startDate.add(Duration(days: daysToAdd));
          }

          scheduledPayments.add({
            'payment_plan_id': paymentPlanId,
            'payment_number': i + 1,
            'scheduled_amount': amountPerPayment,
            'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
            'status': 'pending',
          });
        }

        await _client.from('scheduled_payments').insert(scheduledPayments);
      }

      // 4. Send push notifications to selected brothers
      final dateFormat = DateFormat('MMM dd, yyyy');
      await NotificationService.sendDuesCreatedNotification(
        duesPeriodId: duesPeriodId,
        duesPeriodName: sanitizedName,
        totalAmount: totalAmount,
        dueDate: dateFormat.format(dueDate),
      );

      final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

      await _notificationRepository.createNotificationsForUsers(
        userIds: brotherIds,
        title: 'New Dues Period Created',
        body: '$sanitizedName: ${currencyFormat.format(totalAmount)} due by ${dateFormat.format(dueDate)}',
        type: NotificationType.duesCreated,
        relatedDuesId: duesPeriodId,
      );

      return {'success': true};
    } on PostgrestException catch (e) {
      print('Database error creating dues period: ${e.message}');
      return {
        'success': false,
        'error': 'Database error: ${e.message}'
      };
    } catch (e) {
      print('Unexpected error creating dues period: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred. Please try again.'
      };
    }
  }

  // ============================================
  // PAYMENT PLAN METHODS
  // ============================================

  /// Create a payment plan for brother dues
  /// Automatically calculates and creates scheduled payments
  Future<Map<String, dynamic>> createPaymentPlan({
    required String brotherDuesId,
    required int numberOfPayments,
  }) async {
    try {
      // Validate inputs
      if (numberOfPayments < 1 || numberOfPayments > 10) {
        return {
          'success': false,
          'error': 'Number of payments must be between 1 and 10'
        };
      }

      // Get the brother_dues to calculate payment schedule
      final duesResponse = await _client
          .from('brother_dues')
          .select('total_amount, amount_paid, due_date, created_at')
          .eq('id', brotherDuesId)
          .single();

      final totalAmount = (duesResponse['total_amount'] as num).toDouble();
      final amountPaid = (duesResponse['amount_paid'] as num).toDouble();
      final remaining = totalAmount - amountPaid;
      final dueDate = DateTime.parse(duesResponse['due_date'] as String);
      final createdDate = DateTime.parse(duesResponse['created_at'] as String);

      if (remaining <= 0) {
        return {
          'success': false,
          'error': 'No remaining balance to create payment plan'
        };
      }

      // Check if payment plan already exists
      final existingPlan = await _client
          .from('payment_plans')
          .select()
          .eq('brother_dues_id', brotherDuesId)
          .maybeSingle();

      if (existingPlan != null) {
        return {
          'success': false,
          'error': 'A payment plan already exists for these dues. Delete it first to create a new one.'
        };
      }

      // Create the payment plan
      final planResponse = await _client
          .from('payment_plans')
          .insert({
            'brother_dues_id': brotherDuesId,
            'total_payments': numberOfPayments,
          })
          .select()
          .single();

      final paymentPlanId = planResponse['id'] as String;

      // Calculate payment schedule
      final now = DateTime.now();
      final startDate = now.isAfter(createdDate) ? now : createdDate;
      final totalDays = dueDate.difference(startDate).inDays;

      if (totalDays < numberOfPayments) {
        // Not enough days to space payments, delete the plan
        await _client.from('payment_plans').delete().eq('id', paymentPlanId);
        return {
          'success': false,
          'error': 'Not enough time to schedule $numberOfPayments payments before due date'
        };
      }

      // Calculate payment amount and dates
      final amountPerPayment = remaining / numberOfPayments;
      final daysPerPayment = totalDays / numberOfPayments;

      // Create scheduled payments
      final scheduledPayments = <Map<String, dynamic>>[];
      for (int i = 0; i < numberOfPayments; i++) {
        final daysToAdd = (daysPerPayment * (i + 1)).round();
        final scheduledDate = startDate.add(Duration(days: daysToAdd));

        scheduledPayments.add({
          'payment_plan_id': paymentPlanId,
          'payment_number': i + 1,
          'scheduled_amount': amountPerPayment,
          'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
          'status': 'pending',
        });
      }

      await _client.from('scheduled_payments').insert(scheduledPayments);

      return {'success': true, 'payment_plan_id': paymentPlanId};
    } on PostgrestException catch (e) {
      print('Database error creating payment plan: ${e.message}');
      return {
        'success': false,
        'error': 'Failed to create payment plan: ${e.message}'
      };
    } catch (e) {
      print('Error creating payment plan: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred. Please try again.'
      };
    }
  }

  /// Get payment plan for brother dues
  Future<PaymentPlanWithPayments?> getPaymentPlan(String brotherDuesId) async {
    try {
      // Get payment plan
      final planResponse = await _client
          .from('payment_plans')
          .select()
          .eq('brother_dues_id', brotherDuesId)
          .maybeSingle();

      if (planResponse == null) return null;

      final plan = PaymentPlan.fromJson(planResponse);

      // Get scheduled payments
      final paymentsResponse = await _client
          .from('scheduled_payments')
          .select()
          .eq('payment_plan_id', plan.id)
          .order('payment_number', ascending: true);

      final scheduledPayments = (paymentsResponse as List)
          .map((json) => ScheduledPayment.fromJson(json))
          .toList();

      return PaymentPlanWithPayments(
        plan: plan,
        scheduledPayments: scheduledPayments,
      );
    } catch (e) {
      print('Error fetching payment plan: $e');
      return null;
    }
  }

  /// Get all payment plans for a brother
  Future<List<PaymentPlanWithPayments>> getBrotherPaymentPlans(
      String brotherId) async {
    try {
      // Get all dues for brother
      final duesResponse = await _client
          .from('brother_dues')
          .select('id')
          .eq('brother_id', brotherId);

      final duesIds =
          (duesResponse as List).map((d) => d['id'] as String).toList();

      if (duesIds.isEmpty) return [];

      // Get payment plans for these dues
      final plansResponse = await _client
          .from('payment_plans')
          .select('*')
          .inFilter('brother_dues_id', duesIds);

      final plans = <PaymentPlanWithPayments>[];
      for (final planJson in plansResponse as List) {
        final plan = PaymentPlan.fromJson(planJson);

        // Get scheduled payments
        final paymentsResponse = await _client
            .from('scheduled_payments')
            .select()
            .eq('payment_plan_id', plan.id)
            .order('payment_number', ascending: true);

        final scheduledPayments = (paymentsResponse as List)
            .map((json) => ScheduledPayment.fromJson(json))
            .toList();

        plans.add(PaymentPlanWithPayments(
          plan: plan,
          scheduledPayments: scheduledPayments,
        ));
      }

      return plans;
    } catch (e) {
      print('Error fetching brother payment plans: $e');
      return [];
    }
  }

  /// Bulk fetch payment plans for multiple brother_dues IDs (2 queries total)
  Future<Map<String, PaymentPlanWithPayments>> getPaymentPlansForDuesIds(
      List<String> brotherDuesIds) async {
    if (brotherDuesIds.isEmpty) return {};

    try {
      // Fetch all payment plans in one query
      final plansResponse = await _client
          .from('payment_plans')
          .select()
          .inFilter('brother_dues_id', brotherDuesIds);

      final plans =
          (plansResponse as List).map((j) => PaymentPlan.fromJson(j)).toList();

      if (plans.isEmpty) return {};

      final planIds = plans.map((p) => p.id).toList();

      // Fetch all scheduled payments in one query
      final scheduledResponse = await _client
          .from('scheduled_payments')
          .select()
          .inFilter('payment_plan_id', planIds)
          .order('payment_number', ascending: true);

      final allScheduled = (scheduledResponse as List)
          .map((j) => ScheduledPayment.fromJson(j))
          .toList();

      // Group by plan ID
      final scheduledByPlan = <String, List<ScheduledPayment>>{};
      for (final sp in allScheduled) {
        scheduledByPlan.putIfAbsent(sp.paymentPlanId, () => []).add(sp);
      }

      // Build result map keyed by brotherDuesId
      final result = <String, PaymentPlanWithPayments>{};
      for (final plan in plans) {
        result[plan.brotherDuesId] = PaymentPlanWithPayments(
          plan: plan,
          scheduledPayments: scheduledByPlan[plan.id] ?? [],
        );
      }

      return result;
    } catch (e) {
      print('Error bulk fetching payment plans: $e');
      return {};
    }
  }

  /// Delete a brother's dues entry and all associated data
  /// (payment plan, scheduled payments, and recorded payments)
  Future<Map<String, dynamic>> deleteBrotherDues(String brotherDuesId) async {
    try {
      // SECURITY: Verify current user is VP of Finance
      final currentUser = await _getCurrentUserProfile();
      if (currentUser == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }
      if (currentUser.role != UserRole.vpFinance) {
        return {
          'success': false,
          'error': 'Unauthorized: Only VP of Finance can delete dues'
        };
      }

      // 1. Delete scheduled payments (via payment plan)
      final planResponse = await _client
          .from('payment_plans')
          .select('id')
          .eq('brother_dues_id', brotherDuesId)
          .maybeSingle();

      if (planResponse != null) {
        final paymentPlanId = planResponse['id'] as String;
        await _client
            .from('scheduled_payments')
            .delete()
            .eq('payment_plan_id', paymentPlanId);
        await _client
            .from('payment_plans')
            .delete()
            .eq('id', paymentPlanId);
      }

      // 2. Delete the brother_dues record (payments CASCADE delete automatically)
      await _client.from('brother_dues').delete().eq('id', brotherDuesId);

      return {'success': true};
    } on PostgrestException catch (e) {
      print('Database error deleting brother dues: ${e.message}');
      return {
        'success': false,
        'error': 'Database error: ${e.message}'
      };
    } catch (e) {
      print('Error deleting brother dues: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred. Please try again.'
      };
    }
  }

  /// Delete a payment plan
  Future<Map<String, dynamic>> deletePaymentPlan(String paymentPlanId) async {
    try {
      await _client.from('payment_plans').delete().eq('id', paymentPlanId);

      return {'success': true};
    } catch (e) {
      print('Error deleting payment plan: $e');
      return {
        'success': false,
        'error': 'Failed to delete payment plan. Please try again.'
      };
    }
  }

  /// Update basic brother dues info (amount, due date, notes)
  Future<Map<String, dynamic>> updateBrotherDues({
    required String brotherDuesId,
    double? newTotalAmount,
    DateTime? newDueDate,
    String? newNotes,
  }) async {
    try {
      final currentUser = await _getCurrentUserProfile();
      if (currentUser == null) return {'success': false, 'error': 'Not authenticated'};
      if (currentUser.role != UserRole.vpFinance) {
        return {'success': false, 'error': 'Unauthorized: Only VP of Finance can edit dues'};
      }

      // Validate new amount against what's already paid
      if (newTotalAmount != null) {
        final duesResponse = await _client
            .from('brother_dues')
            .select('amount_paid')
            .eq('id', brotherDuesId)
            .single();
        final amountPaid = (duesResponse['amount_paid'] as num).toDouble();
        if (newTotalAmount < amountPaid - 0.01) {
          return {
            'success': false,
            'error': 'New amount (\$${newTotalAmount.toStringAsFixed(2)}) cannot be less than amount already paid (\$${amountPaid.toStringAsFixed(2)})'
          };
        }
        if (newTotalAmount <= 0 || newTotalAmount > 100000) {
          return {'success': false, 'error': 'Amount must be between \$0.01 and \$100,000'};
        }
      }

      final updates = <String, dynamic>{};
      if (newTotalAmount != null) updates['total_amount'] = newTotalAmount;
      if (newDueDate != null) updates['due_date'] = newDueDate.toIso8601String().split('T')[0];
      if (newNotes != null) updates['notes'] = newNotes.trim().replaceAll(RegExp(r'[<>]'), '');

      if (updates.isEmpty) return {'success': true};

      await _client.from('brother_dues').update(updates).eq('id', brotherDuesId);
      return {'success': true};
    } on PostgrestException catch (e) {
      return {'success': false, 'error': 'Database error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'error': 'An unexpected error occurred.'};
    }
  }

  /// Replace a brother's payment plan with a new one (keeps paid SPs, replaces pending ones)
  Future<Map<String, dynamic>> replaceBrotherDuesPaymentPlan({
    required String brotherDuesId,
    required int numberOfPayments,
    List<DateTime>? customDates,
  }) async {
    try {
      final currentUser = await _getCurrentUserProfile();
      if (currentUser == null) return {'success': false, 'error': 'Not authenticated'};
      if (currentUser.role != UserRole.vpFinance) {
        return {'success': false, 'error': 'Unauthorized'};
      }

      if (numberOfPayments < 1 || numberOfPayments > 10) {
        return {'success': false, 'error': 'Number of payments must be between 1 and 10'};
      }

      // Get dues info
      final duesResponse = await _client
          .from('brother_dues')
          .select('total_amount, amount_paid, due_date')
          .eq('id', brotherDuesId)
          .single();

      final totalAmount = (duesResponse['total_amount'] as num).toDouble();
      final amountPaid = (duesResponse['amount_paid'] as num).toDouble();
      final remaining = totalAmount - amountPaid;
      final dueDate = DateTime.parse(duesResponse['due_date'] as String);

      if (remaining <= 0) {
        return {'success': false, 'error': 'No remaining balance to create payment plan'};
      }

      // Delete existing payment plan (pending SPs only)
      final existingPlan = await _client
          .from('payment_plans')
          .select('id')
          .eq('brother_dues_id', brotherDuesId)
          .maybeSingle();

      if (existingPlan != null) {
        final planId = existingPlan['id'] as String;
        await _client
            .from('scheduled_payments')
            .delete()
            .eq('payment_plan_id', planId)
            .eq('status', 'pending');
        await _client.from('payment_plans').delete().eq('id', planId);
      }

      if (numberOfPayments == 1) {
        // Single payment - no plan needed (will show as single payment card)
        return {'success': true};
      }

      // Create new payment plan
      final planResponse = await _client
          .from('payment_plans')
          .insert({'brother_dues_id': brotherDuesId, 'total_payments': numberOfPayments})
          .select()
          .single();

      final paymentPlanId = planResponse['id'] as String;

      // Calculate schedule
      final now = DateTime.now();
      final totalDays = dueDate.difference(now).inDays;
      final daysPerPayment = totalDays > 0 ? totalDays / numberOfPayments : 1.0;
      final amountPerPayment = remaining / numberOfPayments;

      final scheduledPayments = <Map<String, dynamic>>[];
      for (int i = 0; i < numberOfPayments; i++) {
        DateTime scheduledDate;
        if (customDates != null && i < customDates.length) {
          scheduledDate = customDates[i];
        } else {
          final daysToAdd = (daysPerPayment * (i + 1)).round();
          scheduledDate = now.add(Duration(days: daysToAdd));
        }
        scheduledPayments.add({
          'payment_plan_id': paymentPlanId,
          'payment_number': i + 1,
          'scheduled_amount': amountPerPayment,
          'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
          'status': 'pending',
        });
      }

      await _client.from('scheduled_payments').insert(scheduledPayments);
      return {'success': true};
    } on PostgrestException catch (e) {
      return {'success': false, 'error': 'Database error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'error': 'An unexpected error occurred.'};
    }
  }

  /// Recalculate scheduled payments when a payment is made
  /// This redistributes the remaining balance across remaining payments
  Future<void> recalculateScheduledPayments(String brotherDuesId) async {
    try {
      // Get payment plan
      final planResponse = await _client
          .from('payment_plans')
          .select()
          .eq('brother_dues_id', brotherDuesId)
          .maybeSingle();

      if (planResponse == null) return;

      final paymentPlanId = planResponse['id'] as String;

      // Get dues information
      final duesResponse = await _client
          .from('brother_dues')
          .select('total_amount, amount_paid')
          .eq('id', brotherDuesId)
          .single();

      final totalAmount = (duesResponse['total_amount'] as num).toDouble();
      final amountPaid = (duesResponse['amount_paid'] as num).toDouble();
      final remaining = totalAmount - amountPaid;

      // Get pending scheduled payments
      final scheduledResponse = await _client
          .from('scheduled_payments')
          .select()
          .eq('payment_plan_id', paymentPlanId)
          .eq('status', 'pending')
          .order('payment_number', ascending: true);

      final pendingPayments = scheduledResponse as List;

      if (pendingPayments.isEmpty) return;

      // Recalculate amount per payment
      final amountPerPayment = remaining / pendingPayments.length;

      // Update each pending payment
      for (final payment in pendingPayments) {
        await _client
            .from('scheduled_payments')
            .update({'scheduled_amount': amountPerPayment})
            .eq('id', payment['id']);
      }
    } catch (e) {
      print('Error recalculating scheduled payments: $e');
    }
  }
}
