import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frat_finance_tracker/features/payments/domain/payment_plan.dart';
import 'package:frat_finance_tracker/features/payments/providers/payment_plan_provider.dart';

/// Card widget to display scheduled payments for a payment plan
class ScheduledPaymentsCard extends ConsumerWidget {
  final String brotherDuesId;
  final VoidCallback? onPlanDeleted;

  const ScheduledPaymentsCard({
    super.key,
    required this.brotherDuesId,
    this.onPlanDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(paymentPlanProvider(brotherDuesId));

    return planAsync.when(
      data: (planWithPayments) {
        if (planWithPayments == null) {
          return const SizedBox.shrink();
        }

        return _PaymentPlanCard(
          planWithPayments: planWithPayments,
          onPlanDeleted: onPlanDeleted,
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error loading payment plan: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}

class _PaymentPlanCard extends ConsumerStatefulWidget {
  final PaymentPlanWithPayments planWithPayments;
  final VoidCallback? onPlanDeleted;

  const _PaymentPlanCard({
    required this.planWithPayments,
    this.onPlanDeleted,
  });

  @override
  ConsumerState<_PaymentPlanCard> createState() => _PaymentPlanCardState();
}

class _PaymentPlanCardState extends ConsumerState<_PaymentPlanCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM d, yyyy');

    final planWithPayments = widget.planWithPayments;
    final nextPayment = planWithPayments.nextPayment;
    final overduePayments = planWithPayments.overduePayments;
    final upcomingPayments = planWithPayments.upcomingPayments;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Header with summary
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Payment Plan',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red,
                            tooltip: 'Delete Payment Plan',
                            onPressed: () => _confirmDeletePlan(context),
                          ),
                          Icon(
                            _isExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress indicator
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${planWithPayments.paidCount} of ${planWithPayments.plan.totalPayments} payments made',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  '${((planWithPayments.paidCount / planWithPayments.plan.totalPayments) * 100).toStringAsFixed(0)}%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: planWithPayments.paidCount /
                                  planWithPayments.plan.totalPayments,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Amount summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Paid',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                          ),
                          Text(
                            currencyFormat.format(planWithPayments.totalPaid),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Remaining',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                          ),
                          Text(
                            currencyFormat
                                .format(planWithPayments.totalRemaining),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Next payment info
                  if (nextPayment != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: nextPayment.isOverdue
                            ? Colors.red.shade50
                            : nextPayment.isUpcoming
                                ? Colors.orange.shade50
                                : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: nextPayment.isOverdue
                              ? Colors.red.shade200
                              : nextPayment.isUpcoming
                                  ? Colors.orange.shade200
                                  : Colors.blue.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            nextPayment.isOverdue
                                ? Icons.warning
                                : Icons.schedule,
                            color: nextPayment.isOverdue
                                ? Colors.red
                                : nextPayment.isUpcoming
                                    ? Colors.orange
                                    : Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nextPayment.isOverdue
                                      ? 'Payment Overdue!'
                                      : nextPayment.isUpcoming
                                          ? 'Upcoming Payment'
                                          : 'Next Payment',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: nextPayment.isOverdue
                                        ? Colors.red.shade900
                                        : nextPayment.isUpcoming
                                            ? Colors.orange.shade900
                                            : Colors.blue.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${currencyFormat.format(nextPayment.scheduledAmount)} due ${dateFormat.format(nextPayment.scheduledDate)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: nextPayment.isOverdue
                                        ? Colors.red.shade900
                                        : nextPayment.isUpcoming
                                            ? Colors.orange.shade900
                                            : Colors.blue.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Alerts for overdue/upcoming
                  if (overduePayments.length > 1) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${overduePayments.length} payments are overdue',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (upcomingPayments.isNotEmpty &&
                      overduePayments.isEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${upcomingPayments.length} ${upcomingPayments.length == 1 ? "payment" : "payments"} due in the next 7 days',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Expandable list of scheduled payments
          if (_isExpanded) ...[
            const Divider(height: 1),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: planWithPayments.scheduledPayments.length,
              itemBuilder: (context, index) {
                final payment = planWithPayments.scheduledPayments[index];
                return _ScheduledPaymentTile(
                  payment: payment,
                  currencyFormat: currencyFormat,
                  dateFormat: dateFormat,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDeletePlan(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Plan?'),
        content: const Text(
          'Are you sure you want to delete this payment plan? This will remove all scheduled payments but will not affect your existing payment history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _deletePlan(context);
    }
  }

  Future<void> _deletePlan(BuildContext context) async {
    try {
      final deletePlan = ref.read(deletePaymentPlanProvider);
      final result = await deletePlan(widget.planWithPayments.plan.id);

      if (context.mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment plan deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onPlanDeleted?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to delete payment plan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ScheduledPaymentTile extends StatelessWidget {
  final ScheduledPayment payment;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;

  const _ScheduledPaymentTile({
    required this.payment,
    required this.currencyFormat,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (payment.status) {
      case ScheduledPaymentStatus.paid:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Paid';
        break;
      case ScheduledPaymentStatus.skipped:
        statusColor = Colors.grey;
        statusIcon = Icons.skip_next;
        statusText = 'Skipped';
        break;
      case ScheduledPaymentStatus.pending:
        if (payment.isOverdue) {
          statusColor = Colors.red;
          statusIcon = Icons.warning;
          statusText = 'Overdue';
        } else if (payment.isUpcoming) {
          statusColor = Colors.orange;
          statusIcon = Icons.schedule;
          statusText = 'Due Soon';
        } else {
          statusColor = Colors.blue;
          statusIcon = Icons.schedule;
          statusText = 'Pending';
        }
        break;
    }

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: statusColor.withOpacity(0.1),
        child: Icon(
          statusIcon,
          color: statusColor,
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Text(
            'Payment ${payment.paymentNumber}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 10,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Due: ${dateFormat.format(payment.scheduledDate)}',
            style: const TextStyle(fontSize: 12),
          ),
          if (payment.status == ScheduledPaymentStatus.paid &&
              payment.paidDate != null)
            Text(
              'Paid: ${dateFormat.format(payment.paidDate!)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.green.shade700,
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            currencyFormat.format(payment.scheduledAmount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: payment.status == ScheduledPaymentStatus.paid
                  ? Colors.green
                  : null,
            ),
          ),
          if (payment.status == ScheduledPaymentStatus.paid &&
              payment.paidAmount != payment.scheduledAmount)
            Text(
              'Actual: ${currencyFormat.format(payment.paidAmount)}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}
