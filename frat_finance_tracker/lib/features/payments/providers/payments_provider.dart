import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frat_finance_tracker/features/payments/data/payments_repository.dart';
import 'package:frat_finance_tracker/features/payments/domain/brother_dues.dart';
import 'package:frat_finance_tracker/features/payments/domain/payment_plan.dart';

// Payments repository provider
final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository();
});

// Brother dues provider
final brotherDuesProvider =
    FutureProvider.family<List<BrotherDues>, String>((ref, brotherId) async {
  final repository = ref.watch(paymentsRepositoryProvider);
  return repository.getBrotherDues(brotherId);
});

// Brother payment history provider
final brotherPaymentHistoryProvider =
    FutureProvider.family<List<Payment>, String>((ref, brotherId) async {
  final repository = ref.watch(paymentsRepositoryProvider);
  return repository.getAllBrotherPayments(brotherId);
});

// VP of Finance: All brothers dues provider
final allBrothersDuesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(paymentsRepositoryProvider);
  return repository.getAllBrothersDues();
});

// VP of Finance: All brothers provider (for selection when creating dues)
final allBrothersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(paymentsRepositoryProvider);
  return repository.getAllBrothers();
});

// Payment plan for a specific brother_dues
final paymentPlanProvider =
    FutureProvider.family<PaymentPlanWithPayments?, String>(
        (ref, brotherDuesId) async {
  final repository = ref.watch(paymentsRepositoryProvider);
  return repository.getPaymentPlan(brotherDuesId);
});

// Bulk payment plans for all dues (VP dashboard) - keyed by brotherDuesId
final allPaymentPlansProvider =
    FutureProvider<Map<String, PaymentPlanWithPayments>>((ref) async {
  final allDues = await ref.watch(allBrothersDuesProvider.future);
  final duesIds = allDues.map((d) => d['id'] as String).toList();
  final repository = ref.watch(paymentsRepositoryProvider);
  return repository.getPaymentPlansForDuesIds(duesIds);
});
