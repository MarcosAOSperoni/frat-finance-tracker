import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frat_finance_tracker/features/payments/data/payments_repository.dart';
import 'package:frat_finance_tracker/features/payments/domain/payment_plan.dart';
import 'package:frat_finance_tracker/features/payments/providers/payments_provider.dart';

/// Provider for payment plan for specific brother dues
final paymentPlanProvider = FutureProvider.family.autoDispose<PaymentPlanWithPayments?, String>(
  (ref, brotherDuesId) async {
    final repository = ref.watch(paymentsRepositoryProvider);
    return await repository.getPaymentPlan(brotherDuesId);
  },
);

/// Provider for all payment plans for a brother
final brotherPaymentPlansProvider = FutureProvider.family.autoDispose<List<PaymentPlanWithPayments>, String>(
  (ref, brotherId) async {
    final repository = ref.watch(paymentsRepositoryProvider);
    return await repository.getBrotherPaymentPlans(brotherId);
  },
);

/// Provider to create a payment plan
final createPaymentPlanProvider = Provider<Future<Map<String, dynamic>> Function({
  required String brotherDuesId,
  required int numberOfPayments,
})>((ref) {
  final repository = ref.watch(paymentsRepositoryProvider);

  return ({
    required String brotherDuesId,
    required int numberOfPayments,
  }) async {
    final result = await repository.createPaymentPlan(
      brotherDuesId: brotherDuesId,
      numberOfPayments: numberOfPayments,
    );

    if (result['success'] == true) {
      // Invalidate providers to refresh data
      ref.invalidate(paymentPlanProvider(brotherDuesId));
      ref.invalidate(brotherPaymentPlansProvider);
    }

    return result;
  };
});

/// Provider to delete a payment plan
final deletePaymentPlanProvider = Provider<Future<Map<String, dynamic>> Function(String)>((ref) {
  final repository = ref.watch(paymentsRepositoryProvider);

  return (String paymentPlanId) async {
    final result = await repository.deletePaymentPlan(paymentPlanId);

    if (result['success'] == true) {
      // Invalidate providers to refresh data
      ref.invalidate(paymentPlanProvider);
      ref.invalidate(brotherPaymentPlansProvider);
    }

    return result;
  };
});
