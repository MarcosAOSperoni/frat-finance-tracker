import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frat_finance_tracker/features/auth/domain/app_user.dart';
import 'package:frat_finance_tracker/features/auth/providers/auth_provider.dart';

/// Dialog for transferring VP of Finance role to another brother
class TransferVPRoleDialog extends ConsumerStatefulWidget {
  final List<AppUser> brothers;
  final AppUser currentVP;

  const TransferVPRoleDialog({
    super.key,
    required this.brothers,
    required this.currentVP,
  });

  @override
  ConsumerState<TransferVPRoleDialog> createState() =>
      _TransferVPRoleDialogState();
}

class _TransferVPRoleDialogState extends ConsumerState<TransferVPRoleDialog> {
  AppUser? _selectedBrother;
  bool _isLoading = false;
  bool _confirmChecked = false;

  @override
  Widget build(BuildContext context) {
    // Filter out current VP and inactive brothers
    final availableBrothers = widget.brothers
        .where((b) =>
            b.id != widget.currentVP.id &&
            b.role == UserRole.brother &&
            b.brotherStatus == BrotherStatus.active)
        .toList()
      ..sort((a, b) => (a.fullName ?? '').compareTo(b.fullName ?? ''));

    if (availableBrothers.isEmpty) {
      return AlertDialog(
        title: const Text('No Brothers Available'),
        content: const Text(
          'There are no active brothers available to transfer the VP role to. '
          'Please create brother accounts first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Transfer VP Role'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This will transfer all VP of Finance privileges to the selected brother. '
                      'You will become a regular brother and lose admin access.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Brother selection
            Text(
              'Select New VP of Finance:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // Dropdown to select brother
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<AppUser>(
                isExpanded: true,
                value: _selectedBrother,
                hint: const Text('Choose a brother...'),
                underline: const SizedBox.shrink(),
                items: availableBrothers.map((brother) {
                  return DropdownMenuItem<AppUser>(
                    value: brother,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          brother.fullName ?? 'No Name',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          brother.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: _isLoading
                    ? null
                    : (AppUser? newValue) {
                        setState(() {
                          _selectedBrother = newValue;
                          _confirmChecked = false; // Reset confirmation
                        });
                      },
              ),
            ),

            if (_selectedBrother != null) ...[
              const SizedBox(height: 20),

              // Confirmation checkbox
              CheckboxListTile(
                value: _confirmChecked,
                onChanged: _isLoading
                    ? null
                    : (bool? value) {
                        setState(() {
                          _confirmChecked = value ?? false;
                        });
                      },
                title: Text(
                  'I understand this action will remove my VP privileges',
                  style: TextStyle(
                    fontSize: 13,
                    color: _confirmChecked ? Colors.black : Colors.grey.shade700,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading || _selectedBrother == null || !_confirmChecked
              ? null
              : _transferRole,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Transfer Role'),
        ),
      ],
    );
  }

  Future<void> _transferRole() async {
    if (_selectedBrother == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(authRepositoryProvider);
      final result = await repository.transferVPRole(
        currentVPId: widget.currentVP.id,
        newVPId: _selectedBrother!.id,
      );

      if (mounted) {
        if (result['success'] == true) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'VP role transferred to ${_selectedBrother!.fullName ?? _selectedBrother!.email}. '
                'You are now a regular brother.',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );

          // Sign out and force re-login to refresh permissions
          await repository.signOut();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to transfer VP role'),
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
