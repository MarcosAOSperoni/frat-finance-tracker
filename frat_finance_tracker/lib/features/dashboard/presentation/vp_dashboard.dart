import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:frat_finance_tracker/features/auth/providers/auth_provider.dart';
import 'package:frat_finance_tracker/features/payments/providers/payments_provider.dart';
import 'package:frat_finance_tracker/features/payments/domain/brother_dues.dart';
import 'package:frat_finance_tracker/features/payments/domain/payment_plan.dart';
import 'package:frat_finance_tracker/features/dashboard/widgets/dues_detail_view.dart';
import 'package:frat_finance_tracker/shared/widgets/desktop_scaffold.dart';

class VPDashboard extends ConsumerStatefulWidget {
  const VPDashboard({super.key});

  @override
  ConsumerState<VPDashboard> createState() => _VPDashboardState();
}

class _VPDashboardState extends ConsumerState<VPDashboard> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _paidUpExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final allDuesAsync = ref.watch(allBrothersDuesProvider);
    final paymentPlansAsync = ref.watch(allPaymentPlansProvider);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    Future<void> createDues() async {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const CreateDuesScreen()),
      );
      if (result == true) {
        ref.invalidate(allBrothersDuesProvider);
      }
    }

    final dashboardBody = RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allBrothersDuesProvider);
        ref.invalidate(allPaymentPlansProvider);
      },
      child: allDuesAsync.when(
          data: (allDues) {
            final paymentPlans = paymentPlansAsync.valueOrNull ?? {};
            if (allDues.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No dues periods created yet'),
                ),
              );
            }

            // Filter out fully paid dues periods (where all brothers have paid)
            final duesPeriodsMap = <String, List<Map<String, dynamic>>>{};
            for (final duesData in allDues) {
              final periodId = duesData['dues_period_id'] as String;
              duesPeriodsMap.putIfAbsent(periodId, () => []);
              duesPeriodsMap[periodId]!.add(duesData);
            }

            // Filter out fully paid periods
            final activePeriodsIds = <String>{};
            for (final entry in duesPeriodsMap.entries) {
              final hasOutstanding = entry.value.any((dues) {
                final total = (dues['total_amount'] as num).toDouble();
                final paid = (dues['amount_paid'] as num).toDouble();
                return paid < total;
              });
              if (hasOutstanding) {
                activePeriodsIds.add(entry.key);
              }
            }

            // Group dues by brother (only include active periods)
            final brotherDuesMap = <String, List<Map<String, dynamic>>>{};
            for (final duesData in allDues) {
              final periodId = duesData['dues_period_id'] as String;
              if (!activePeriodsIds.contains(periodId)) continue;

              final brotherId = duesData['brother_id'] as String;
              brotherDuesMap.putIfAbsent(brotherId, () => []);
              brotherDuesMap[brotherId]!.add(duesData);
            }

            // Separate brothers into outstanding and paid categories
            final brothersWithOutstanding = <String, List<Map<String, dynamic>>>{};
            final brothersPaidUp = <String, List<Map<String, dynamic>>>{};

            for (final entry in brotherDuesMap.entries) {
              double brotherTotal = 0;
              double brotherPaid = 0;
              for (final duesData in entry.value) {
                brotherTotal += (duesData['total_amount'] as num).toDouble();
                brotherPaid += (duesData['amount_paid'] as num).toDouble();
              }

              if (brotherPaid < brotherTotal) {
                brothersWithOutstanding[entry.key] = entry.value;
              } else {
                brothersPaidUp[entry.key] = entry.value;
              }
            }

            // Calculate overall statistics (only from active periods)
            double totalOwed = 0;
            double totalPaid = 0;
            int totalOverdue = 0;
            for (final duesData in allDues) {
              final periodId = duesData['dues_period_id'] as String;
              if (!activePeriodsIds.contains(periodId)) continue;

              totalOwed += (duesData['total_amount'] as num).toDouble();
              totalPaid += (duesData['amount_paid'] as num).toDouble();

              // Count overdue scheduled payments
              final duesId = duesData['id'] as String;
              final plan = paymentPlans[duesId];
              if (plan != null) {
                totalOverdue += plan.overduePayments.length;
              }
            }
            final totalRemaining = totalOwed - totalPaid;
            final totalBrothers = brotherDuesMap.length;
            final paidUpCount = brothersPaidUp.length;

            // Helper to build brother card data
            _BrotherCardData buildCardData(MapEntry<String, List<Map<String, dynamic>>> entry) {
              final brotherDuesList = entry.value;
              final firstDues = brotherDuesList.first;
              final userData = firstDues['users'] as Map<String, dynamic>?;
              final brotherName = userData?['full_name'] as String? ?? 'Unknown';
              final brotherEmail = userData?['email'] as String? ?? '';

              double brotherTotal = 0;
              double brotherPaid = 0;
              int totalScheduled = 0;
              int paidScheduled = 0;
              int overdueCount = 0;
              for (final duesData in brotherDuesList) {
                brotherTotal += (duesData['total_amount'] as num).toDouble();
                brotherPaid += (duesData['amount_paid'] as num).toDouble();
                final duesId = duesData['id'] as String;
                final plan = paymentPlans[duesId];
                if (plan != null) {
                  totalScheduled += plan.plan.totalPayments;
                  paidScheduled += plan.paidCount;
                  overdueCount += plan.overduePayments.length;
                } else {
                  totalScheduled += 1;
                  if ((duesData['amount_paid'] as num).toDouble() >= (duesData['total_amount'] as num).toDouble()) {
                    paidScheduled += 1;
                  }
                }
              }

              return _BrotherCardData(
                name: brotherName,
                email: brotherEmail,
                totalOwed: brotherTotal,
                totalPaid: brotherPaid,
                remaining: brotherTotal - brotherPaid,
                paidPayments: paidScheduled,
                totalPayments: totalScheduled,
                overdueCount: overdueCount,
                duesList: brotherDuesList,
              );
            }

            // Filter by search query
            bool matchesSearch(String name) {
              if (_searchQuery.isEmpty) return true;
              return name.toLowerCase().contains(_searchQuery.toLowerCase());
            }

            final filteredOutstanding = brothersWithOutstanding.entries
                .map(buildCardData)
                .where((d) => matchesSearch(d.name))
                .toList();
            final filteredPaidUp = brothersPaidUp.entries
                .map(buildCardData)
                .where((d) => matchesSearch(d.name))
                .toList();

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page header
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Overview',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E3A8A),
                                    ),
                              ),
                              Text(
                                'Active dues periods and payment status',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (context) => const AddUserDialog(),
                            );
                            if (result == true && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('User created successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.person_add_outlined, size: 16),
                          label: const Text('Add Brother'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1E3A8A),
                            side: BorderSide(color: Colors.grey.shade300),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Desktop: horizontal stat tiles; Mobile: overview card
                  if (isDesktopPlatform)
                    _StatisticsCard(
                      totalOwed: totalOwed,
                      totalPaid: totalPaid,
                      totalRemaining: totalRemaining,
                      totalBrothers: totalBrothers,
                      paidUpCount: paidUpCount,
                      overdueCount: totalOverdue,
                    )
                  else
                    _MobileOverviewCard(
                      totalOwed: totalOwed,
                      totalPaid: totalPaid,
                      totalRemaining: totalRemaining,
                      totalBrothers: totalBrothers,
                      paidUpCount: paidUpCount,
                      overdueCount: totalOverdue,
                    ),
                  const SizedBox(height: 16),

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search brothers...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                  const SizedBox(height: 20),

                  // Outstanding Dues Section
                  if (filteredOutstanding.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Outstanding Dues (${filteredOutstanding.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...filteredOutstanding.map((data) => _BrotherCard(
                          data: data,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BrotherDetailScreen(
                                  brotherName: data.name,
                                  brotherEmail: data.email,
                                  duesList: data.duesList,
                                  paymentPlans: paymentPlans,
                                ),
                              ),
                            );
                          },
                        )),
                    const SizedBox(height: 24),
                  ],

                  // Paid Up Section (collapsible)
                  if (filteredPaidUp.isNotEmpty) ...[
                    InkWell(
                      onTap: () => setState(() => _paidUpExpanded = !_paidUpExpanded),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Paid Up (${filteredPaidUp.length})',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade900,
                                    ),
                              ),
                            ),
                            Icon(
                              _paidUpExpanded ? Icons.expand_less : Icons.expand_more,
                              color: Colors.green.shade700,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_paidUpExpanded) ...[
                      const SizedBox(height: 12),
                      ...filteredPaidUp.map((data) => _BrotherCard(
                            data: data,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BrotherDetailScreen(
                                    brotherName: data.name,
                                    brotherEmail: data.email,
                                    duesList: data.duesList,
                                    paymentPlans: paymentPlans,
                                  ),
                                ),
                              );
                            },
                          )),
                    ],
                  ],

                  // Show message if no active dues
                  if (brothersWithOutstanding.isEmpty && brothersPaidUp.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(Icons.celebration, size: 64, color: Colors.green.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'All dues periods are fully paid!',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Bottom padding to avoid FAB overlap
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading data: $error'),
            ),
          ),
        ),
    );

    if (!isDesktopPlatform) {
      return MobileScaffold(
        currentRoute: '/vp-dashboard',
        appBar: AppBar(title: const Text('VP Dashboard')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: createDues,
          icon: const Icon(Icons.add),
          label: const Text('Create Dues'),
          backgroundColor: const Color(0xFFEEAA00),
          foregroundColor: Colors.black87,
        ),
        body: dashboardBody,
      );
    }

    return DesktopScaffold(
      currentRoute: '/vp-dashboard',
      onCreateDues: createDues,
      body: dashboardBody,
    );
  }
}

/// Data class for brother card info
class _BrotherCardData {
  final String name;
  final String email;
  final double totalOwed;
  final double totalPaid;
  final double remaining;
  final int paidPayments;
  final int totalPayments;
  final int overdueCount;
  final List<Map<String, dynamic>> duesList;

  const _BrotherCardData({
    required this.name,
    required this.email,
    required this.totalOwed,
    required this.totalPaid,
    required this.remaining,
    required this.paidPayments,
    required this.totalPayments,
    required this.overdueCount,
    required this.duesList,
  });
}

class _StatisticsCard extends StatelessWidget {
  final double totalOwed;
  final double totalPaid;
  final double totalRemaining;
  final int totalBrothers;
  final int paidUpCount;
  final int overdueCount;

  const _StatisticsCard({
    required this.totalOwed,
    required this.totalPaid,
    required this.totalRemaining,
    required this.totalBrothers,
    required this.paidUpCount,
    required this.overdueCount,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final collectionProgress = totalOwed > 0 ? totalPaid / totalOwed : 0.0;
    final progressPercent = (collectionProgress * 100).toStringAsFixed(0);

    return Row(
      children: [
        _StatTile(
          label: 'Total Owed',
          value: currencyFormat.format(totalOwed),
          icon: Icons.account_balance_wallet_outlined,
          color: Theme.of(context).colorScheme.primary,
          flex: 1,
        ),
        const SizedBox(width: 12),
        _StatTile(
          label: 'Collected',
          value: currencyFormat.format(totalPaid),
          icon: Icons.check_circle_outline,
          color: Colors.green.shade700,
          flex: 1,
        ),
        const SizedBox(width: 12),
        _StatTile(
          label: 'Outstanding',
          value: currencyFormat.format(totalRemaining),
          icon: Icons.pending_outlined,
          color: Colors.orange.shade700,
          flex: 1,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people_outline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        'Collection Progress',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const Spacer(),
                      if (overdueCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$overdueCount overdue',
                            style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$paidUpCount / $totalBrothers brothers',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: collectionProgress,
                      minHeight: 6,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        collectionProgress >= 1.0 ? Colors.green : const Color(0xFFEEAA00),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$progressPercent% collected',
                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int flex;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color.withOpacity(0.7)),
                  const SizedBox(width: 6),
                  Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _BrotherCard extends StatelessWidget {
  final _BrotherCardData data;
  final VoidCallback onTap;

  const _BrotherCard({
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final isPaid = data.remaining <= 0;
    final progress = data.totalOwed > 0 ? data.totalPaid / data.totalOwed : 1.0;

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Theme.of(context).dividerColor),
    );

    if (!isDesktopPlatform) {
      // ── Mobile card: two-row layout ──────────────────────────────────────
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: Theme.of(context).colorScheme.surface,
        shape: cardShape,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: avatar + name/overdue badge + amount
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: isPaid ? Colors.green.shade100 : Colors.orange.shade100,
                      child: Text(
                        data.name.isNotEmpty ? data.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isPaid ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  data.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (data.overdueCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${data.overdueCount} late',
                                    style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            data.email,
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isPaid ? 'Paid' : currencyFormat.format(data.remaining),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isPaid ? Colors.green.shade600 : Colors.red.shade600,
                          ),
                        ),
                        Text(
                          isPaid ? 'in full' : 'remaining',
                          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: 10),
                // Row 2: progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPaid ? Colors.green : const Color(0xFFEEAA00),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Row 3: payments count + percentage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${data.paidPayments}/${data.totalPayments} payments',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% collected',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Desktop card: compact single-row layout ──────────────────────────
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: cardShape,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: isPaid
                    ? Colors.green.shade100
                    : Colors.orange.shade100,
                child: Text(
                  data.name.isNotEmpty ? data.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isPaid ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name + email
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            data.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (data.overdueCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${data.overdueCount} late',
                              style: TextStyle(fontSize: 9, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      data.email,
                      style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Progress bar
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isPaid ? Colors.green : const Color(0xFFEEAA00),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Payments
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${data.paidPayments}/${data.totalPayments}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text('payments', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Amount remaining
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isPaid ? 'Paid' : currencyFormat.format(data.remaining),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isPaid ? Colors.green.shade600 : Colors.red.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isPaid ? 'in full' : 'remaining',
                      style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mobile-only overview card: progress bar + three stat chips in a single card.
class _MobileOverviewCard extends StatelessWidget {
  final double totalOwed;
  final double totalPaid;
  final double totalRemaining;
  final int totalBrothers;
  final int paidUpCount;
  final int overdueCount;

  const _MobileOverviewCard({
    required this.totalOwed,
    required this.totalPaid,
    required this.totalRemaining,
    required this.totalBrothers,
    required this.paidUpCount,
    required this.overdueCount,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final progress = totalOwed > 0 ? totalPaid / totalOwed : 0.0;
    final progressPercent = (progress * 100).toStringAsFixed(0);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (overdueCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$overdueCount overdue',
                      style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people_outline, size: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  '$paidUpCount / $totalBrothers brothers collected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? Colors.green : const Color(0xFFEEAA00),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$progressPercent% collected',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MobileStatChip(
                    label: 'Total Owed',
                    value: currencyFormat.format(totalOwed),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MobileStatChip(
                    label: 'Collected',
                    value: currencyFormat.format(totalPaid),
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MobileStatChip(
                    label: 'Outstanding',
                    value: currencyFormat.format(totalRemaining),
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MobileStatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class BrotherDetailScreen extends ConsumerWidget {
  final String brotherName;
  final String brotherEmail;
  final List<Map<String, dynamic>> duesList;
  final Map<String, PaymentPlanWithPayments> paymentPlans;

  const BrotherDetailScreen({
    super.key,
    required this.brotherName,
    required this.brotherEmail,
    required this.duesList,
    required this.paymentPlans,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parsedDues = duesList.map((d) => BrotherDues.fromJson(d)).toList();

    void onDone() {
      ref.invalidate(allBrothersDuesProvider);
      ref.invalidate(allPaymentPlansProvider);
      Navigator.of(context).pop();
    }

    final detailView = DuesDetailView(
      brotherName: brotherName,
      brotherEmail: brotherEmail,
      duesList: parsedDues,
      paymentPlans: paymentPlans,
      isAdmin: true,
      onActionCompleted: onDone,
    );

    if (!isDesktopPlatform) {
      return MobileScaffold(
        currentRoute: '/vp-dashboard',
        appBar: AppBar(
          title: Text(brotherName),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: detailView,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                  tooltip: 'Back',
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  brotherName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  brotherEmail,
                  style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Expanded(child: detailView),
        ],
      ),
    );
  }
}

class RecordPaymentDialog extends ConsumerStatefulWidget {
  final String brotherName;
  final String duesPeriodName;
  final String brotherDuesId;
  final double remainingAmount;
  final double? scheduledAmount;
  final String? scheduledPaymentId;

  const RecordPaymentDialog({
    super.key,
    required this.brotherName,
    required this.duesPeriodName,
    required this.brotherDuesId,
    required this.remainingAmount,
    this.scheduledAmount,
    this.scheduledPaymentId,
  });

  @override
  ConsumerState<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends ConsumerState<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _paymentMethodController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = (widget.scheduledAmount ?? widget.remainingAmount).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _paymentMethodController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _recordPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    final amount = double.tryParse(_amountController.text) ?? 0;
    final repository = ref.read(paymentsRepositoryProvider);

    final result = await repository.recordPayment(
      brotherDuesId: widget.brotherDuesId,
      amount: amount,
      paymentDate: _selectedDate,
      recordedBy: currentUser.id,
      paymentMethod: _paymentMethodController.text.isNotEmpty
          ? _paymentMethodController.text
          : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      scheduledPaymentId: widget.scheduledPaymentId,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        Navigator.of(context).pop(true);
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to record payment'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return AlertDialog(
      title: Text('Record Payment for ${widget.brotherName}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.duesPeriodName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (widget.scheduledAmount != null && widget.scheduledAmount != widget.remainingAmount) ...[
                const SizedBox(height: 4),
                Text(
                  'Scheduled: \$${widget.scheduledAmount!.toStringAsFixed(2)}  •  Max (overflow to next): \$${widget.remainingAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Payment Amount',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (amount > widget.remainingAmount) {
                    return 'Amount exceeds remaining balance';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Payment Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(dateFormat.format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _paymentMethodController,
                decoration: const InputDecoration(
                  labelText: 'Payment Method (Optional)',
                  hintText: 'e.g., Venmo, Cash, Zelle',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _recordPayment,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Record Payment'),
        ),
      ],
    );
  }
}

class CreateDuesScreen extends ConsumerStatefulWidget {
  const CreateDuesScreen({super.key});

  @override
  ConsumerState<CreateDuesScreen> createState() => _CreateDuesScreenState();
}

class _CreateDuesScreenState extends ConsumerState<CreateDuesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

  // Brother selection: brotherId -> isSelected
  final Map<String, bool> _selectedBrothers = {};
  // Per-brother payment counts: brotherId -> number of payments
  final Map<String, int> _paymentCounts = {};

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _initBrothers(List<Map<String, dynamic>> brothers) {
    for (final brother in brothers) {
      final id = brother['id'] as String;
      final status = brother['brother_status'] as String? ?? 'active';
      if (status == 'active') {
        _selectedBrothers.putIfAbsent(id, () => true);
        _paymentCounts.putIfAbsent(id, () => 1);
      }
    }
  }

  void _toggleSelectAll(List<Map<String, dynamic>> activeBrothers, bool selectAll) {
    setState(() {
      for (final brother in activeBrothers) {
        final id = brother['id'] as String;
        _selectedBrothers[id] = selectAll;
        if (selectAll) {
          _paymentCounts.putIfAbsent(id, () => 1);
        }
      }
    });
  }

  Future<void> _createDuesPeriod() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    // Build payment counts map for selected brothers only
    final brotherPaymentCounts = <String, int>{};
    _selectedBrothers.forEach((id, selected) {
      if (selected) {
        brotherPaymentCounts[id] = _paymentCounts[id] ?? 1;
      }
    });

    if (brotherPaymentCounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one brother'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_dueDate.isBefore(_startDate) || _dueDate.isAtSameMomentAs(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Due date must be after start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;

    final brothersAsync = ref.read(allBrothersProvider);
    final brothers = brothersAsync.value ?? [];
    final selectedBrotherDetails = brothers
        .where((b) => brotherPaymentCounts.containsKey(b['id'] as String))
        .toList();

    // Check if any brothers have multiple payments
    final multiPaymentBrothers = selectedBrotherDetails
        .where((b) => (brotherPaymentCounts[b['id'] as String] ?? 1) > 1)
        .toList();

    if (multiPaymentBrothers.isNotEmpty) {
      // Go to date customization screen
      if (!mounted) return;
      final customDates = await Navigator.push<Map<String, List<DateTime>>>(
        context,
        MaterialPageRoute(
          builder: (context) => _PaymentDatesScreen(
            duesName: _nameController.text,
            amount: amount,
            startDate: _startDate,
            dueDate: _dueDate,
            brotherPaymentCounts: brotherPaymentCounts,
            brotherDetails: multiPaymentBrothers,
            allBrotherDetails: selectedBrotherDetails,
          ),
        ),
      );
      if (customDates == null) return; // user cancelled

      // Go to confirmation screen
      if (!mounted) return;
      final confirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => _DuesCreationConfirmScreen(
            duesName: _nameController.text,
            amount: amount,
            startDate: _startDate,
            dueDate: _dueDate,
            brotherPaymentCounts: brotherPaymentCounts,
            brotherDetails: selectedBrotherDetails,
            brotherCustomDates: customDates,
            createdBy: currentUser.id,
          ),
        ),
      );
      if (confirmed == true && mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      // No multi-payment brothers - go straight to confirmation
      if (!mounted) return;
      final confirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => _DuesCreationConfirmScreen(
            duesName: _nameController.text,
            amount: amount,
            startDate: _startDate,
            dueDate: _dueDate,
            brotherPaymentCounts: brotherPaymentCounts,
            brotherDetails: selectedBrotherDetails,
            brotherCustomDates: const {},
            createdBy: currentUser.id,
          ),
        ),
      );
      if (confirmed == true && mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final brothersAsync = ref.watch(allBrothersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Dues Period'),
      ),
      body: brothersAsync.when(
        data: (brothers) {
          final activeBrothers = brothers
              .where((b) => (b['brother_status'] as String? ?? 'active') == 'active')
              .toList();

          _initBrothers(brothers);

          final allSelected = activeBrothers.isNotEmpty &&
              activeBrothers.every((b) => _selectedBrothers[b['id'] as String] == true);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Dues Details Section
                Text(
                  'Dues Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Dues Period Name',
                    hintText: 'e.g., Fall 2024 Dues',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount Per Brother',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                          );
                          if (picked != null) {
                            setState(() => _startDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(dateFormat.format(_startDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dueDate,
                            firstDate: _startDate.add(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                          );
                          if (picked != null) {
                            setState(() => _dueDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Due Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(dateFormat.format(_dueDate)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Brother Selection Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Brothers',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton.icon(
                      onPressed: () => _toggleSelectAll(activeBrothers, !allSelected),
                      icon: Icon(
                        allSelected ? Icons.deselect : Icons.select_all,
                        size: 20,
                      ),
                      label: Text(allSelected ? 'Deselect All' : 'Select All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (activeBrothers.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Text(
                      'No active brothers found. Please update brother statuses in Brother Management.',
                    ),
                  )
                else
                  ...activeBrothers.map((brother) {
                    final id = brother['id'] as String;
                    final name = brother['full_name'] as String? ?? 'Unknown';
                    final email = brother['email'] as String? ?? '';
                    final isSelected = _selectedBrothers[id] ?? false;
                    final paymentCount = _paymentCounts[id] ?? 1;
                    final isVP = brother['role'] == 'vp_finance';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  _selectedBrothers[id] = value ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          name,
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      if (isVP) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'VP',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.purple,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    email,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey.shade600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Column(
                                children: [
                                  Text(
                                    'Payments',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey.shade600,
                                          fontSize: 11,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: paymentCount > 1
                                              ? () => setState(() => _paymentCounts[id] = paymentCount - 1)
                                              : null,
                                          child: Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: Icon(
                                              Icons.remove,
                                              size: 18,
                                              color: paymentCount > 1 ? Colors.black : Colors.grey.shade300,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          child: Text(
                                            '$paymentCount',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: paymentCount < 10
                                              ? () => setState(() => _paymentCounts[id] = paymentCount + 1)
                                              : null,
                                          child: Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: Icon(
                                              Icons.add,
                                              size: 18,
                                              color: paymentCount < 10 ? Colors.black : Colors.grey.shade300,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 24),

                // Create button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _createDuesPeriod,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF001F3F),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Next →',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error loading brothers: $error')),
      ),
    );
  }
}

class _PaymentDatesScreen extends StatefulWidget {
  final String duesName;
  final double amount;
  final DateTime startDate;
  final DateTime dueDate;
  final Map<String, int> brotherPaymentCounts;
  final List<Map<String, dynamic>> brotherDetails; // brothers with >1 payment
  final List<Map<String, dynamic>> allBrotherDetails;

  const _PaymentDatesScreen({
    required this.duesName,
    required this.amount,
    required this.startDate,
    required this.dueDate,
    required this.brotherPaymentCounts,
    required this.brotherDetails,
    required this.allBrotherDetails,
  });

  @override
  State<_PaymentDatesScreen> createState() => _PaymentDatesScreenState();
}

class _PaymentDatesScreenState extends State<_PaymentDatesScreen> {
  // brotherId -> list of DateTimes (one per payment)
  final Map<String, List<DateTime>> _paymentDates = {};

  @override
  void initState() {
    super.initState();
    _initializeDates();
  }

  void _initializeDates() {
    final totalDays = widget.dueDate.difference(widget.startDate).inDays;
    for (final brother in widget.brotherDetails) {
      final brotherId = brother['id'] as String;
      final count = widget.brotherPaymentCounts[brotherId] ?? 1;
      if (count <= 1) continue;
      final daysPerPayment = totalDays / count;
      _paymentDates[brotherId] = List.generate(count, (i) {
        final daysToAdd = (daysPerPayment * (i + 1)).round();
        return widget.startDate.add(Duration(days: daysToAdd));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final amountPerPayment = widget.amount; // total per brother

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Payment Dates'),
        actions: [
          TextButton(
            onPressed: _goToConfirmation,
            child: const Text(
              'Next →',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.duesName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${currencyFormat.format(widget.amount)} per brother  •  Due ${dateFormat.format(widget.dueDate)}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Customize payment dates for brothers with multiple installments.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),
          ...widget.brotherDetails.map((brother) {
            final brotherId = brother['id'] as String;
            final name = brother['full_name'] as String? ?? 'Unknown';
            final count = widget.brotherPaymentCounts[brotherId] ?? 1;
            if (count <= 1) return const SizedBox.shrink();
            final dates = _paymentDates[brotherId] ?? [];
            final paymentAmt = amountPerPayment / count;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFF1E3A8A),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        Text(
                          '$count payments of ${currencyFormat.format(paymentAmt)}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(count, (i) {
                      final date = i < dates.length ? dates[i] : widget.dueDate;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: date,
                              firstDate: widget.startDate,
                              lastDate: widget.dueDate,
                            );
                            if (picked != null) {
                              setState(() {
                                final newDates = List<DateTime>.from(_paymentDates[brotherId] ?? []);
                                while (newDates.length <= i) newDates.add(widget.dueDate);
                                newDates[i] = picked;
                                _paymentDates[brotherId] = newDates;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Payment ${i + 1}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const Spacer(),
                                Text(
                                  dateFormat.format(date),
                                  style: TextStyle(color: Colors.blue.shade700),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade500),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToConfirmation,
        label: const Text('Next →'),
        icon: const Icon(Icons.arrow_forward),
      ),
    );
  }

  void _goToConfirmation() {
    // Validate all dates are set and in order
    for (final brother in widget.brotherDetails) {
      final brotherId = brother['id'] as String;
      final count = widget.brotherPaymentCounts[brotherId] ?? 1;
      if (count <= 1) continue;
      final dates = _paymentDates[brotherId];
      if (dates == null || dates.length < count) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set all payment dates'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    Navigator.of(context).pop(_paymentDates);
  }
}

class _DuesCreationConfirmScreen extends ConsumerStatefulWidget {
  final String duesName;
  final double amount;
  final DateTime startDate;
  final DateTime dueDate;
  final Map<String, int> brotherPaymentCounts;
  final List<Map<String, dynamic>> brotherDetails;
  final Map<String, List<DateTime>> brotherCustomDates;
  final String createdBy;

  const _DuesCreationConfirmScreen({
    required this.duesName,
    required this.amount,
    required this.startDate,
    required this.dueDate,
    required this.brotherPaymentCounts,
    required this.brotherDetails,
    required this.brotherCustomDates,
    required this.createdBy,
  });

  @override
  ConsumerState<_DuesCreationConfirmScreen> createState() =>
      _DuesCreationConfirmScreenState();
}

class _DuesCreationConfirmScreenState
    extends ConsumerState<_DuesCreationConfirmScreen> {
  bool _isLoading = false;

  Future<void> _create() async {
    setState(() => _isLoading = true);

    final repository = ref.read(paymentsRepositoryProvider);

    final brotherPaymentCounts = <String, int>{};
    for (final b in widget.brotherDetails) {
      final id = b['id'] as String;
      brotherPaymentCounts[id] = widget.brotherPaymentCounts[id] ?? 1;
    }

    final result = await repository.createDuesPeriod(
      name: widget.duesName,
      totalAmount: widget.amount,
      startDate: widget.startDate,
      dueDate: widget.dueDate,
      brotherPaymentCounts: brotherPaymentCounts,
      createdBy: widget.createdBy,
      brotherCustomDates: widget.brotherCustomDates.isEmpty
          ? null
          : widget.brotherCustomDates,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        ref.invalidate(allBrothersDuesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dues period created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        final errorMessage = result['error'] ?? 'Failed to create dues period';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage.contains('duplicate key')
                  ? 'This dues period already exists. Please use a different name.'
                  : errorMessage,
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Dues Period'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dues summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dues Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Divider(height: 16),
                  _DetailRow(label: 'Name', value: widget.duesName),
                  _DetailRow(label: 'Amount', value: currencyFormat.format(widget.amount)),
                  _DetailRow(label: 'Start', value: dateFormat.format(widget.startDate)),
                  _DetailRow(label: 'Due', value: dateFormat.format(widget.dueDate)),
                  _DetailRow(
                    label: 'Brothers',
                    value: '${widget.brotherDetails.length}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Brothers list
          Text(
            'Payment Schedules',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...widget.brotherDetails.map((brother) {
            final id = brother['id'] as String;
            final name = brother['full_name'] as String? ?? 'Unknown';
            final count = widget.brotherPaymentCounts[id] ?? 1;
            final customDates = widget.brotherCustomDates[id];
            final paymentAmt = widget.amount / count;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '$count payment${count > 1 ? 's' : ''}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                    if (count > 1 && customDates != null) ...[
                      const SizedBox(height: 8),
                      ...List.generate(count, (i) {
                        final date = i < customDates.length ? customDates[i] : widget.dueDate;
                        return Padding(
                          padding: const EdgeInsets.only(left: 24, bottom: 2),
                          child: Text(
                            'Payment ${i + 1}: ${currencyFormat.format(paymentAmt)} — ${dateFormat.format(date)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }),
                    ] else if (count == 1) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 24, top: 2),
                        child: Text(
                          '${currencyFormat.format(widget.amount)} due ${dateFormat.format(widget.dueDate)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          // Create button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _create,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF001F3F),
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Confirm & Create Dues Period',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class EditDuesScreen extends ConsumerStatefulWidget {
  final BrotherDues dues;
  final PaymentPlanWithPayments? existingPlan;

  const EditDuesScreen({
    super.key,
    required this.dues,
    this.existingPlan,
  });

  @override
  ConsumerState<EditDuesScreen> createState() => _EditDuesScreenState();
}

class _EditDuesScreenState extends ConsumerState<EditDuesScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late DateTime _dueDate;
  bool _modifyingPlan = false;
  int _newPaymentCount = 1;
  List<DateTime> _newPaymentDates = [];
  bool _isLoading = false;

  bool get _hasChanges {
    final newAmount = double.tryParse(_amountController.text);
    final amountChanged = newAmount != null && (newAmount - widget.dues.totalAmount).abs() > 0.01;
    final dateChanged = _dueDate != widget.dues.dueDate;
    final notesChanged = _notesController.text.trim() != (widget.dues.notes ?? '');
    return amountChanged || dateChanged || notesChanged || _modifyingPlan;
  }

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.dues.totalAmount.toStringAsFixed(2),
    );
    _notesController = TextEditingController(text: widget.dues.notes ?? '');
    _dueDate = widget.dues.dueDate;
    _newPaymentCount = widget.existingPlan?.plan.totalPayments ?? 1;
    _initPaymentDates();
    _amountController.addListener(() => setState(() {}));
    _notesController.addListener(() => setState(() {}));
  }

  void _initPaymentDates() {
    if (widget.existingPlan != null) {
      final pendingSPs = widget.existingPlan!.scheduledPayments
          .where((sp) => sp.status == ScheduledPaymentStatus.pending)
          .toList();
      _newPaymentDates = pendingSPs.map((sp) => sp.scheduledDate).toList();
      _newPaymentCount = pendingSPs.isNotEmpty ? pendingSPs.length : 1;
    } else {
      _newPaymentCount = 1;
      _newPaymentDates = [];
    }
  }

  void _updatePaymentDateCount(int count) {
    setState(() {
      _newPaymentCount = count;
      if (count <= 1) {
        _newPaymentDates = [];
        return;
      }
      // Resize dates list
      final now = DateTime.now();
      final totalDays = _dueDate.difference(now).inDays;
      final daysPerPayment = totalDays > 0 ? totalDays / count : 1.0;
      _newPaymentDates = List.generate(count, (i) {
        if (i < _newPaymentDates.length) return _newPaymentDates[i];
        final daysToAdd = (daysPerPayment * (i + 1)).round();
        return now.add(Duration(days: daysToAdd));
      });
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newAmount = double.tryParse(_amountController.text);
    if (newAmount == null || newAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    final repository = ref.read(paymentsRepositoryProvider);

    // Update basic dues info
    final amountChanged = (newAmount - widget.dues.totalAmount).abs() > 0.01;
    final dateChanged = _dueDate != widget.dues.dueDate;
    final notesChanged = _notesController.text.trim() != (widget.dues.notes ?? '');

    if (amountChanged || dateChanged || notesChanged) {
      final result = await repository.updateBrotherDues(
        brotherDuesId: widget.dues.id,
        newTotalAmount: amountChanged ? newAmount : null,
        newDueDate: dateChanged ? _dueDate : null,
        newNotes: notesChanged ? _notesController.text : null,
      );
      if (!result['success']) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to update dues'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // Replace payment plan if modifying
    if (_modifyingPlan) {
      final result = await repository.replaceBrotherDuesPaymentPlan(
        brotherDuesId: widget.dues.id,
        numberOfPayments: _newPaymentCount,
        customDates: _newPaymentCount > 1 && _newPaymentDates.isNotEmpty
            ? _newPaymentDates
            : null,
      );
      if (!result['success']) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to update payment plan'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      ref.invalidate(allBrothersDuesProvider);
      ref.invalidate(allPaymentPlansProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dues updated successfully'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final hasPaidPayments = widget.dues.amountPaid > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit: ${widget.dues.duesPeriodName}'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            style: _hasChanges
                ? TextButton.styleFrom(foregroundColor: Colors.white)
                : null,
            child: _isLoading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current status
          if (hasPaidPayments)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade800, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${currencyFormat.format(widget.dues.amountPaid)} already paid. '
                      'New total cannot be less than this.',
                      style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Amount field
          Text('Total Amount', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(
              prefixText: '\$',
              border: OutlineInputBorder(),
              hintText: '0.00',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),

          // Due date
          Text('Due Date', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dueDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              );
              if (picked != null) {
                setState(() => _dueDate = picked);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(dateFormat.format(_dueDate)),
            ),
          ),
          const SizedBox(height: 16),

          // Notes
          Text('Notes (Optional)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          // Payment plan section
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Plan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Switch(
                value: _modifyingPlan,
                onChanged: (v) => setState(() {
                  _modifyingPlan = v;
                  if (v) _updatePaymentDateCount(_newPaymentCount);
                }),
              ),
            ],
          ),
          if (!_modifyingPlan && widget.existingPlan != null) ...[
            Text(
              'Current: ${widget.existingPlan!.plan.totalPayments} payments  •  '
              '${widget.existingPlan!.paidCount} paid',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Toggle to modify payment structure',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ] else if (!_modifyingPlan && widget.existingPlan == null) ...[
            Text(
              'No payment plan (single payment)',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            Text(
              'Toggle to add installments',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
          if (_modifyingPlan) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Number of payments:'),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: _newPaymentCount > 1
                            ? () => _updatePaymentDateCount(_newPaymentCount - 1)
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(Icons.remove, size: 18,
                            color: _newPaymentCount > 1 ? Colors.black : Colors.grey.shade300),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('$_newPaymentCount',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      InkWell(
                        onTap: _newPaymentCount < 10
                            ? () => _updatePaymentDateCount(_newPaymentCount + 1)
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(Icons.add, size: 18,
                            color: _newPaymentCount < 10 ? Colors.black : Colors.grey.shade300),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_newPaymentCount > 1) ...[
              const SizedBox(height: 12),
              Text('Payment Dates',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...List.generate(_newPaymentCount, (i) {
                final date = i < _newPaymentDates.length ? _newPaymentDates[i] : _dueDate;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: _dueDate,
                      );
                      if (picked != null) {
                        setState(() {
                          final newDates = List<DateTime>.from(_newPaymentDates);
                          while (newDates.length <= i) newDates.add(_dueDate);
                          newDates[i] = picked;
                          _newPaymentDates = newDates;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text('Payment ${i + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Text(dateFormat.format(date),
                            style: TextStyle(color: Colors.blue.shade700)),
                          const SizedBox(width: 6),
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade500),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade800, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pending scheduled payments will be replaced. Paid installments are preserved.',
                      style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class AddUserDialog extends ConsumerStatefulWidget {
  const AddUserDialog({super.key});

  @override
  ConsumerState<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends ConsumerState<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.createUser(
      email: _emailController.text,
      fullName: _fullNameController.text,
      role: 'brother', // Always create as brother
    );

    if (mounted) {
      // Small delay to ensure auth state has fully settled
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User created successfully. Default password: TempPassword123@',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to create user'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New User'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'brother@example.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'John Doe',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Default Login Information',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Password: TempPassword123@',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue.shade900,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'User will be required to change their password on first login.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue.shade700,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createUser,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create User'),
        ),
      ],
    );
  }
}

// Dialog to display temporary password after user creation
class _TemporaryPasswordDialog extends StatelessWidget {
  final String email;
  final String fullName;
  final String temporaryPassword;

  const _TemporaryPasswordDialog({
    required this.email,
    required this.fullName,
    required this.temporaryPassword,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 32),
          SizedBox(width: 12),
          Text('User Created Successfully'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Name: $fullName',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4),
                  Text('Email: $email'),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Warning banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'IMPORTANT: Save this password now. It cannot be retrieved later.',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Temporary password display
            Text(
              'Temporary Password:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      temporaryPassword,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, color: Colors.blue),
                    tooltip: 'Copy to clipboard',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: temporaryPassword));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Password copied to clipboard'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Next Steps:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Share this password with $fullName securely (in person, encrypted message, etc.)',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '2. They will be required to change this password on first login',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '3. Do not share this password via unsecured channels (SMS, regular email, etc.)',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Show confirmation before closing
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Confirm'),
                content: Text('Have you saved the temporary password? It cannot be retrieved later.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('No, go back'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close confirmation
                      Navigator.pop(context); // Close password dialog
                    },
                    child: Text('Yes, I\'ve saved it'),
                  ),
                ],
              ),
            );
          },
          child: Text('Close'),
        ),
      ],
    );
  }

}
