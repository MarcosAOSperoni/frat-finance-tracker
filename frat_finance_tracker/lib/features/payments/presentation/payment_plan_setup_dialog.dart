import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frat_finance_tracker/features/payments/domain/brother_dues.dart';
import 'package:frat_finance_tracker/features/payments/providers/payment_plan_provider.dart';

/// Dialog for setting up a payment plan for dues
class PaymentPlanSetupDialog extends ConsumerStatefulWidget {
  final BrotherDues dues;

  const PaymentPlanSetupDialog({
    super.key,
    required this.dues,
  });

  @override
  ConsumerState<PaymentPlanSetupDialog> createState() =>
      _PaymentPlanSetupDialogState();
}

class _PaymentPlanSetupDialogState
    extends ConsumerState<PaymentPlanSetupDialog> {
  int _numberOfPayments = 3;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM d, yyyy');

    // Calculate payment details
    final amountPerPayment = widget.dues.amountRemaining / _numberOfPayments;
    final now = DateTime.now();
    final startDate = now; // Start payment plan from today
    final totalDays = widget.dues.dueDate.difference(startDate).inDays;
    final daysPerPayment = totalDays / _numberOfPayments;

    // Generate preview of scheduled payments
    final scheduledPayments = List.generate(_numberOfPayments, (index) {
      final daysToAdd = (daysPerPayment * (index + 1)).round();
      final scheduledDate = startDate.add(Duration(days: daysToAdd));
      return {
        'number': index + 1,
        'amount': amountPerPayment,
        'date': scheduledDate,
      };
    });

    return AlertDialog(
      title: const Text('Set Up Payment Plan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dues info
            Card(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.dues.duesPeriodName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          currencyFormat.format(widget.dues.totalAmount),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Amount Paid:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          currencyFormat.format(widget.dues.amountPaid),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Remaining:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          currencyFormat.format(widget.dues.amountRemaining),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Due: ${dateFormat.format(widget.dues.dueDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Number of payments selector
            Text(
              'Number of Payments',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _numberOfPayments.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _numberOfPayments.toString(),
                    onChanged: (value) {
                      setState(() {
                        _numberOfPayments = value.toInt();
                      });
                    },
                  ),
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    '$_numberOfPayments',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Payment preview
            Text(
              'Payment Schedule Preview',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: scheduledPayments.length,
                itemBuilder: (context, index) {
                  final payment = scheduledPayments[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        child: Text(
                          '${payment['number']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      title: Text(
                        currencyFormat.format(payment['amount']),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        dateFormat.format(payment['date'] as DateTime),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Info message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payments will be automatically recalculated if you make a manual payment.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createPaymentPlan,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Plan'),
        ),
      ],
    );
  }

  Future<void> _createPaymentPlan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final createPlan = ref.read(createPaymentPlanProvider);
      final result = await createPlan(
        brotherDuesId: widget.dues.id,
        numberOfPayments: _numberOfPayments,
      );

      if (mounted) {
        if (result['success'] == true) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment plan created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to create payment plan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
