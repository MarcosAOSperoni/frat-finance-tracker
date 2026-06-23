import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frat_finance_tracker/features/auth/providers/auth_provider.dart';
import 'package:frat_finance_tracker/features/auth/domain/app_user.dart';
import 'package:frat_finance_tracker/features/payments/providers/payments_provider.dart';
import 'package:frat_finance_tracker/features/payments/domain/brother_dues.dart';
import 'package:frat_finance_tracker/features/payments/domain/payment_plan.dart';
import 'package:frat_finance_tracker/features/dashboard/widgets/dues_detail_view.dart';
import 'package:frat_finance_tracker/shared/widgets/desktop_scaffold.dart';

class BrotherDashboard extends ConsumerWidget {
  const BrotherDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final duesAsync = ref.watch(brotherDuesProvider(currentUser.id));

    final content = RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(brotherDuesProvider(currentUser.id));
      },
      child: duesAsync.when(
        data: (duesList) {
          if (duesList.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No dues assigned yet'),
              ),
            );
          }
          return _DuesWithPlans(
            currentUser: currentUser,
            duesList: duesList,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error loading dues: $error'),
          ),
        ),
      ),
    );

    if (!isDesktopPlatform) {
      return MobileScaffold(
        currentRoute: '/dashboard',
        appBar: AppBar(title: const Text('My Dues')),
        body: content,
      );
    }

    return DesktopScaffold(
      currentRoute: '/dashboard',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Dues',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    Text(
                      'Hello, ${currentUser.fullName ?? "Brother"}',
                      style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _DuesWithPlans extends ConsumerWidget {
  final AppUser currentUser;
  final List<BrotherDues> duesList;

  const _DuesWithPlans({
    required this.currentUser,
    required this.duesList,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch payment plans for each dues individually
    final planFutures = <String, AsyncValue<PaymentPlanWithPayments?>>{};
    for (final dues in duesList) {
      planFutures[dues.id] = ref.watch(paymentPlanProvider(dues.id));
    }

    final anyLoading = planFutures.values.any((v) => v.isLoading);
    if (anyLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Build the payment plans map
    final paymentPlans = <String, PaymentPlanWithPayments>{};
    for (final entry in planFutures.entries) {
      final plan = entry.value.valueOrNull;
      if (plan != null) {
        paymentPlans[entry.key] = plan;
      }
    }

    return DuesDetailView(
      brotherName: currentUser.fullName ?? 'Brother',
      brotherEmail: currentUser.email,
      duesList: duesList,
      paymentPlans: paymentPlans,
      isAdmin: false,
    );
  }
}
