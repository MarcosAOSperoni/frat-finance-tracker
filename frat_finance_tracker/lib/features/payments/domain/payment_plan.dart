/// Payment plan domain models

/// Payment plan for dues
class PaymentPlan {
  final String id;
  final String brotherDuesId;
  final int totalPayments;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentPlan({
    required this.id,
    required this.brotherDuesId,
    required this.totalPayments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentPlan.fromJson(Map<String, dynamic> json) {
    return PaymentPlan(
      id: json['id'] as String,
      brotherDuesId: json['brother_dues_id'] as String,
      totalPayments: json['total_payments'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brother_dues_id': brotherDuesId,
      'total_payments': totalPayments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Scheduled payment within a payment plan
class ScheduledPayment {
  final String id;
  final String paymentPlanId;
  final int paymentNumber;
  final double scheduledAmount;
  final DateTime scheduledDate;
  final ScheduledPaymentStatus status;
  final double paidAmount;
  final DateTime? paidDate;
  final String? paymentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScheduledPayment({
    required this.id,
    required this.paymentPlanId,
    required this.paymentNumber,
    required this.scheduledAmount,
    required this.scheduledDate,
    required this.status,
    required this.paidAmount,
    this.paidDate,
    this.paymentId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScheduledPayment.fromJson(Map<String, dynamic> json) {
    return ScheduledPayment(
      id: json['id'] as String,
      paymentPlanId: json['payment_plan_id'] as String,
      paymentNumber: json['payment_number'] as int,
      scheduledAmount: (json['scheduled_amount'] as num).toDouble(),
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      status: ScheduledPaymentStatus.fromString(json['status'] as String),
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
      paidDate: json['paid_date'] != null
          ? DateTime.parse(json['paid_date'] as String)
          : null,
      paymentId: json['payment_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_plan_id': paymentPlanId,
      'payment_number': paymentNumber,
      'scheduled_amount': scheduledAmount,
      'scheduled_date': scheduledDate.toIso8601String(),
      'status': status.value,
      'paid_amount': paidAmount,
      'paid_date': paidDate?.toIso8601String(),
      'payment_id': paymentId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if payment is overdue
  bool get isOverdue {
    return status == ScheduledPaymentStatus.pending &&
        scheduledDate.isBefore(DateTime.now());
  }

  /// Check if payment is upcoming (within 7 days)
  bool get isUpcoming {
    final now = DateTime.now();
    final inSevenDays = now.add(const Duration(days: 7));
    return status == ScheduledPaymentStatus.pending &&
        scheduledDate.isAfter(now) &&
        scheduledDate.isBefore(inSevenDays);
  }
}

/// Status of a scheduled payment
enum ScheduledPaymentStatus {
  pending('pending'),
  paid('paid'),
  skipped('skipped');

  final String value;
  const ScheduledPaymentStatus(this.value);

  static ScheduledPaymentStatus fromString(String value) {
    return ScheduledPaymentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ScheduledPaymentStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case ScheduledPaymentStatus.pending:
        return 'Pending';
      case ScheduledPaymentStatus.paid:
        return 'Paid';
      case ScheduledPaymentStatus.skipped:
        return 'Skipped';
    }
  }
}

/// Payment plan with scheduled payments
class PaymentPlanWithPayments {
  final PaymentPlan plan;
  final List<ScheduledPayment> scheduledPayments;

  PaymentPlanWithPayments({
    required this.plan,
    required this.scheduledPayments,
  });

  /// Get next pending payment
  ScheduledPayment? get nextPayment {
    final pending = scheduledPayments
        .where((p) => p.status == ScheduledPaymentStatus.pending)
        .toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

    return pending.isNotEmpty ? pending.first : null;
  }

  /// Get number of paid payments
  int get paidCount {
    return scheduledPayments
        .where((p) => p.status == ScheduledPaymentStatus.paid)
        .length;
  }

  /// Get number of pending payments
  int get pendingCount {
    return scheduledPayments
        .where((p) => p.status == ScheduledPaymentStatus.pending)
        .length;
  }

  /// Get total amount paid through scheduled payments
  double get totalPaid {
    return scheduledPayments
        .where((p) => p.status == ScheduledPaymentStatus.paid)
        .fold(0, (sum, p) => sum + p.paidAmount);
  }

  /// Get total scheduled amount remaining
  double get totalRemaining {
    return scheduledPayments
        .where((p) => p.status == ScheduledPaymentStatus.pending)
        .fold(0, (sum, p) => sum + p.scheduledAmount);
  }

  /// Get overdue payments
  List<ScheduledPayment> get overduePayments {
    return scheduledPayments.where((p) => p.isOverdue).toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
  }

  /// Get upcoming payments (within 7 days)
  List<ScheduledPayment> get upcomingPayments {
    return scheduledPayments.where((p) => p.isUpcoming).toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
  }
}
