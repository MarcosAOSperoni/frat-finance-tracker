import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frat_finance_tracker/features/auth/providers/auth_provider.dart';
import 'package:frat_finance_tracker/features/auth/domain/app_user.dart';
import 'package:frat_finance_tracker/features/payments/providers/payments_provider.dart';
import 'package:frat_finance_tracker/shared/services/notification_service.dart';
import 'package:frat_finance_tracker/shared/widgets/desktop_scaffold.dart';

class BrotherManagementScreen extends ConsumerWidget {
  const BrotherManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final brothersAsync = ref.watch(allBrothersProvider);

    Widget buildBrotherList(List<Map<String, dynamic>> brothers, {double padding = 24}) {
      if (brothers.isEmpty) return const Center(child: Text('No brothers found'));

      // Group brothers by status
      final brothersByStatus = <String, List<Map<String, dynamic>>>{
        'active': [],
        'inactive': [],
      };

      for (final brother in brothers) {
        final status = brother['brother_status'] as String? ?? 'active';
        // Map any legacy statuses to inactive
        final normalizedStatus = status == 'active' ? 'active' : 'inactive';
        brothersByStatus[normalizedStatus]?.add(brother);
      }

      return RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allBrothersProvider);
        },
        child: ListView(
          padding: EdgeInsets.all(padding),
          children: [
            // Statistics Card
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      label: 'Active Brothers',
                      count: brothersByStatus['active']!.length,
                      color: const Color(0xFF16A34A),
                      bgColor: const Color(0xFFDCFCE7),
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatChip(
                      label: 'Inactive Brothers',
                      count: brothersByStatus['inactive']!.length,
                      color: const Color(0xFFD97706),
                      bgColor: const Color(0xFFFFF7ED),
                      icon: Icons.pause_circle_outline_rounded,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Brother List
            ...['active', 'inactive'].expand((status) {
              final statusBrothers = brothersByStatus[status]!;
              if (statusBrothers.isEmpty) return <Widget>[];

              return [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    BrotherStatus.fromString(status).displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                ...statusBrothers.map((brother) => _BrotherManagementCard(
                      brother: brother,
                      currentUserId: currentUser?.id ?? '',
                    )),
                const SizedBox(height: 16),
              ];
            }),
          ],
        ),
      );
    }

    if (!isDesktopPlatform) {
      return MobileScaffold(
        currentRoute: '/brother-management',
        appBar: AppBar(
          title: const Text('Brothers'),
          actions: [_SendRemindersButton()],
        ),
        body: brothersAsync.when(
          data: (brothers) => buildBrotherList(brothers, padding: 16),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text('Error loading brothers: $error'),
          ),
        ),
      );
    }

    return DesktopScaffold(
      currentRoute: '/brother-management',
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Brothers',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      Text(
                        'Manage brother statuses and send reminders',
                        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                _SendRemindersButton(),
              ],
            ),
          ),
          Expanded(
            child: brothersAsync.when(
              data: (brothers) => buildBrotherList(brothers),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Error loading brothers: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// AppBar action button that sends payment reminder push notifications
/// to all brothers with unpaid dues.
class _SendRemindersButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SendRemindersButton> createState() => _SendRemindersButtonState();
}

class _SendRemindersButtonState extends ConsumerState<_SendRemindersButton> {
  bool _sending = false;

  Future<void> _sendReminders() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Payment Reminders'),
        content: const Text(
          'This will send a push notification to every brother who has unpaid dues.\n\n'
          'Each brother will receive a message with their specific next payment amount and due date.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _sending = true);

    final result = await NotificationService.sendPaymentReminderNotifications();

    if (!mounted) return;
    setState(() => _sending = false);

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>?;
      final sent = data?['successCount'] ?? 0;
      final brothers = data?['brothersTargeted'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sent $sent notification${sent == 1 ? '' : 's'} to $brothers brother${brothers == 1 ? '' : 's'} with unpaid dues.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to send notifications'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sending) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return IconButton(
      icon: const Icon(Icons.notifications_active),
      tooltip: 'Send Payment Reminders',
      onPressed: _sendReminders,
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.75),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrotherManagementCard extends ConsumerWidget {
  final Map<String, dynamic> brother;
  final String currentUserId;

  const _BrotherManagementCard({
    required this.brother,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brotherId = brother['id'] as String;
    final brotherName = brother['full_name'] as String;
    final brotherEmail = brother['email'] as String;
    final role = brother['role'] as String;
    final status = brother['brother_status'] as String? ?? 'active';
    final isCurrentUser = brotherId == currentUserId;
    final isVP = role == 'vp_finance';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isVP
                ? const Color(0xFFF3E8FF)
                : const Color(0xFFDEE8FF),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            brotherName.isNotEmpty ? brotherName[0].toUpperCase() : '?',
            style: TextStyle(
              color: isVP ? const Color(0xFF7E22CE) : const Color(0xFF1E3A8A),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                brotherName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            if (isVP) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'VP',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7E22CE),
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              brotherEmail,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusBgColor(status),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                BrotherStatus.fromString(status).displayName,
                style: TextStyle(
                  fontSize: 10.5,
                  color: _getStatusColor(status),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            if (value == 'change_status') {
              final newStatus = await showDialog<String>(
                context: context,
                builder: (context) => _ChangeStatusDialog(
                  brotherName: brotherName,
                  currentStatus: status,
                ),
              );
              if (newStatus != null && context.mounted) {
                final repository = ref.read(authRepositoryProvider);
                final result = await repository.updateBrotherStatus(
                  brotherId: brotherId,
                  status: newStatus,
                );
                if (context.mounted) {
                  if (result['success'] == true) {
                    ref.invalidate(allBrothersProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Status updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['error'] ?? 'Failed to update status'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            } else if (value == 'make_vp') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Transfer VP Role'),
                  content: Text(
                    'Are you sure you want to make $brotherName the VP of Finance? You will become a regular brother.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Transfer VP Role'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                final repository = ref.read(authRepositoryProvider);
                final result = await repository.transferVPRole(
                  currentVPId: currentUserId,
                  newVPId: brotherId,
                );

                if (context.mounted) {
                  if (result['success'] == true) {
                    // Sign out current user since they're no longer VP
                    await repository.signOut();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('VP role transferred. Please log in again.'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 5),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['error'] ?? 'Failed to transfer VP role'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            } else if (value == 'delete_brother') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Brother'),
                  content: Text(
                    'Are you sure you want to permanently delete $brotherName?\n\n'
                    'This will remove all their dues, payments, and payment history. '
                    'This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
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
                final repository = ref.read(authRepositoryProvider);
                final result = await repository.deleteBrother(
                  brotherId: brotherId,
                );

                if (context.mounted) {
                  if (result['success'] == true) {
                    ref.invalidate(allBrothersProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$brotherName has been deleted'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['error'] ?? 'Failed to delete brother'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'change_status',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Change Status'),
                ],
              ),
            ),
            if (!isVP && !isCurrentUser)
              const PopupMenuItem(
                value: 'make_vp',
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, color: Colors.purple),
                    SizedBox(width: 8),
                    Text('Make VP of Finance'),
                  ],
                ),
              ),
            if (!isVP && !isCurrentUser)
              const PopupMenuItem(
                value: 'delete_brother',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Delete Brother',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFFD97706);
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFFDCFCE7);
      default:
        return const Color(0xFFFFF7ED);
    }
  }
}

class _ChangeStatusDialog extends StatefulWidget {
  final String brotherName;
  final String currentStatus;

  const _ChangeStatusDialog({
    required this.brotherName,
    required this.currentStatus,
  });

  @override
  State<_ChangeStatusDialog> createState() => _ChangeStatusDialogState();
}

class _ChangeStatusDialogState extends State<_ChangeStatusDialog> {
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    // Normalize legacy statuses to active/inactive
    _selectedStatus = widget.currentStatus == 'active' ? 'active' : 'inactive';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Change Status for ${widget.brotherName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<String>(
            title: const Text('Active'),
            value: 'active',
            groupValue: _selectedStatus,
            onChanged: (value) => setState(() => _selectedStatus = value!),
          ),
          RadioListTile<String>(
            title: const Text('Inactive'),
            value: 'inactive',
            groupValue: _selectedStatus,
            onChanged: (value) => setState(() => _selectedStatus = value!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedStatus),
          child: const Text('Update Status'),
        ),
      ],
    );
  }
}
