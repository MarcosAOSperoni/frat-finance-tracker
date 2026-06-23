import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frat_finance_tracker/features/payments/domain/brother_dues.dart';
import 'package:frat_finance_tracker/features/payments/domain/payment_plan.dart';
import 'package:frat_finance_tracker/features/payments/providers/payments_provider.dart';
import 'package:frat_finance_tracker/features/dashboard/presentation/vp_dashboard.dart';

class DuesDetailView extends ConsumerStatefulWidget {
  final String brotherName;
  final String brotherEmail;
  final List<BrotherDues> duesList;
  final Map<String, PaymentPlanWithPayments> paymentPlans;
  final bool isAdmin;
  final VoidCallback? onActionCompleted;

  const DuesDetailView({
    super.key,
    required this.brotherName,
    required this.brotherEmail,
    required this.duesList,
    required this.paymentPlans,
    this.isAdmin = false,
    this.onActionCompleted,
  });

  @override
  ConsumerState<DuesDetailView> createState() => _DuesDetailViewState();
}

class _DuesDetailViewState extends ConsumerState<DuesDetailView> {
  Future<void> _confirmDeleteDues(
    BuildContext context,
    String brotherDuesId,
    String paymentLabel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Due'),
        content: Text(
          'Are you sure you want to delete "$paymentLabel" for ${widget.brotherName}?\n\n'
          'This will permanently remove this due and all associated payments and scheduled payments. '
          'This action cannot be undone.',
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

    if (confirmed == true && mounted) {
      final repository = ref.read(paymentsRepositoryProvider);
      final result = await repository.deleteBrotherDues(brotherDuesId);

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Due deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onActionCompleted?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to delete due'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM d, yyyy');

    // Calculate overall stats
    double totalOwed = 0;
    double totalPaid = 0;
    int overdueCount = 0;

    for (final dues in widget.duesList) {
      totalOwed += dues.totalAmount;
      totalPaid += dues.amountPaid;
      final plan = widget.paymentPlans[dues.id];
      if (plan != null) {
        overdueCount += plan.overduePayments.length;
      } else if (dues.isOverdue) {
        overdueCount += 1;
      }
    }
    final totalRemaining = totalOwed - totalPaid;
    final progress = totalOwed > 0 ? totalPaid / totalOwed : 0.0;
    final progressPercent = (progress * 100).toStringAsFixed(0);

    // Group payments by dues period
    final groupedDues = <String, List<BrotherDues>>{};
    for (final dues in widget.duesList) {
      groupedDues.putIfAbsent(dues.duesPeriodName, () => []).add(dues);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // Summary Header Card
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Square avatar with rounded corners
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.brotherName.isNotEmpty
                          ? widget.brotherName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.brotherName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (overdueCount > 0) ...[
                              const SizedBox(width: 8),
                              _StatusBadge(
                                label: '$overdueCount overdue',
                                color: const Color(0xFFDC2626),
                                bgColor: const Color(0xFFFEE2E2),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.brotherEmail,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Progress bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$progressPercent% paid',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: progress >= 1.0
                              ? const Color(0xFF16A34A)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    '${currencyFormat.format(totalPaid)} of ${currencyFormat.format(totalOwed)}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? const Color(0xFF16A34A) : const Color(0xFFEEAA00),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _buildStatColumn(
                      context,
                      'Total Owed',
                      currencyFormat.format(totalOwed),
                      Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      context,
                      'Paid',
                      currencyFormat.format(totalPaid),
                      const Color(0xFF16A34A),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      context,
                      'Remaining',
                      currencyFormat.format(totalRemaining),
                      totalRemaining > 0
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Payment cards grouped by dues period
        for (final entry in groupedDues.entries) ...[
          // Section header
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  entry.key,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: -0.1,
                      ),
                ),
              ],
            ),
          ),
          // Payment cards for this period
          for (final dues in entry.value)
            ..._buildPaymentCardsForDues(
              context,
              dues,
              widget.paymentPlans[dues.id],
              currencyFormat,
              dateFormat,
            ),
        ],
      ],
    );
  }

  Widget _buildStatColumn(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPaymentCardsForDues(
    BuildContext context,
    BrotherDues dues,
    PaymentPlanWithPayments? plan,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    if (plan != null && plan.scheduledPayments.isNotEmpty) {
      return plan.scheduledPayments.map((sp) {
        final isPaid = sp.status == ScheduledPaymentStatus.paid;
        final isOverdue = sp.isOverdue;

        return _PaymentCard(
          label: 'Payment ${sp.paymentNumber} of ${plan.plan.totalPayments}',
          amount: currencyFormat.format(sp.scheduledAmount),
          dueDate: dateFormat.format(sp.scheduledDate),
          isPaid: isPaid,
          isOverdue: isOverdue,
          paidDateLabel: (isPaid && sp.paidDate != null)
              ? 'Paid ${dateFormat.format(sp.paidDate!)}'
              : null,
          adminActions: widget.isAdmin && !isPaid
              ? _PaymentCardActions(
                  onRecord: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => RecordPaymentDialog(
                        brotherName: widget.brotherName,
                        duesPeriodName:
                            '${dues.duesPeriodName} Payment #${sp.paymentNumber}/${plan.plan.totalPayments}',
                        brotherDuesId: dues.id,
                        remainingAmount: dues.amountRemaining,
                        scheduledAmount: sp.scheduledAmount,
                        scheduledPaymentId: sp.id,
                      ),
                    );
                    if (result == true && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment recorded')),
                      );
                      widget.onActionCompleted?.call();
                    }
                  },
                  onEdit: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditDuesScreen(dues: dues, existingPlan: plan),
                      ),
                    );
                    if (result == true && mounted) {
                      widget.onActionCompleted?.call();
                    }
                  },
                  onDelete: () => _confirmDeleteDues(
                    context,
                    dues.id,
                    '${dues.duesPeriodName} Payment #${sp.paymentNumber}/${plan.plan.totalPayments}',
                  ),
                )
              : null,
        );
      }).toList();
    } else {
      // No payment plan – single payment
      final isPaid = dues.isPaid;
      final isOverdue = dues.isOverdue;

      return [
        _PaymentCard(
          label: 'Payment 1 of 1',
          amount: currencyFormat.format(dues.totalAmount),
          dueDate: dateFormat.format(dues.dueDate),
          isPaid: isPaid,
          isOverdue: isOverdue,
          statusLabel: dues.status.displayName,
          adminActions: widget.isAdmin && dues.amountRemaining > 0
              ? _PaymentCardActions(
                  onRecord: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => RecordPaymentDialog(
                        brotherName: widget.brotherName,
                        duesPeriodName: dues.duesPeriodName,
                        brotherDuesId: dues.id,
                        remainingAmount: dues.amountRemaining,
                      ),
                    );
                    if (result == true && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment recorded')),
                      );
                      widget.onActionCompleted?.call();
                    }
                  },
                  onEdit: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditDuesScreen(dues: dues, existingPlan: plan),
                      ),
                    );
                    if (result == true && mounted) {
                      widget.onActionCompleted?.call();
                    }
                  },
                  onDelete: () => _confirmDeleteDues(
                    context,
                    dues.id,
                    '${dues.duesPeriodName} Payment #1/1',
                  ),
                )
              : null,
        ),
      ];
    }
  }
}

// ── Reusable payment card ────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  final String label;
  final String amount;
  final String dueDate;
  final bool isPaid;
  final bool isOverdue;
  final String? statusLabel;
  final String? paidDateLabel;
  final _PaymentCardActions? adminActions;

  const _PaymentCard({
    required this.label,
    required this.amount,
    required this.dueDate,
    required this.isPaid,
    required this.isOverdue,
    this.statusLabel,
    this.paidDateLabel,
    this.adminActions,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isPaid
        ? const Color(0xFF16A34A)
        : isOverdue
            ? const Color(0xFFDC2626)
            : const Color(0xFF1E3A8A);
    final accentBg = isPaid
        ? const Color(0xFFDCFCE7)
        : isOverdue
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFDEE8FF);
    final statusText = statusLabel ??
        (isPaid ? 'Paid' : isOverdue ? 'Overdue' : 'Pending');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: accentColor, width: 3),
          top: BorderSide(color: Theme.of(context).colorScheme.outline),
          right: BorderSide(color: Theme.of(context).colorScheme.outline),
          bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(
                  label: statusText,
                  color: accentColor,
                  bgColor: accentBg,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Amount + date
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        amount,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Due date',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dueDate,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    if (paidDateLabel != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        paidDateLabel!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF16A34A),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (adminActions != null) ...[
              const SizedBox(height: 14),
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 10),
              adminActions!,
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentCardActions extends StatelessWidget {
  final VoidCallback onRecord;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PaymentCardActions({
    required this.onRecord,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 38,
            child: ElevatedButton.icon(
              onPressed: onRecord,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
              label: const Text('Record Payment'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _ActionIconButton(
          icon: Icons.edit_outlined,
          color: const Color(0xFF3B82F6),
          tooltip: 'Edit dues',
          onTap: onEdit,
        ),
        const SizedBox(width: 2),
        _ActionIconButton(
          icon: Icons.delete_outline_rounded,
          color: const Color(0xFFDC2626),
          tooltip: 'Delete dues',
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11.5,
        ),
      ),
    );
  }
}
