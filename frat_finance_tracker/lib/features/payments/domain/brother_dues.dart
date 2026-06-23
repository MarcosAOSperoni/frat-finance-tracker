import 'package:flutter/material.dart';

class BrotherDues {
  final String id;
  final String brotherId;
  final String duesPeriodId;
  final String duesPeriodName;
  final double totalAmount;
  final double amountPaid;
  final DuesStatus status;
  final DateTime dueDate;
  final String? notes;

  BrotherDues({
    required this.id,
    required this.brotherId,
    required this.duesPeriodId,
    required this.duesPeriodName,
    required this.totalAmount,
    required this.amountPaid,
    required this.status,
    required this.dueDate,
    this.notes,
  });

  double get amountRemaining => totalAmount - amountPaid;
  bool get isPaid => status == DuesStatus.paid;
  bool get isPartiallyPaid => status == DuesStatus.partial;
  bool get isOverdue => status == DuesStatus.overdue;

  factory BrotherDues.fromJson(Map<String, dynamic> json) {
    return BrotherDues(
      id: json['id'] as String,
      brotherId: json['brother_id'] as String,
      duesPeriodId: json['dues_period_id'] as String,
      duesPeriodName: json['dues_periods']?['name'] as String? ?? 'Unknown',
      totalAmount: (json['total_amount'] as num).toDouble(),
      amountPaid: (json['amount_paid'] as num).toDouble(),
      status: DuesStatus.fromString(json['status'] as String),
      dueDate: DateTime.parse(json['due_date'] as String),
      notes: json['notes'] as String?,
    );
  }
}

enum DuesStatus {
  pending('pending'),
  partial('partial'),
  paid('paid'),
  overdue('overdue');

  final String value;
  const DuesStatus(this.value);

  static DuesStatus fromString(String value) {
    return DuesStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => DuesStatus.pending,
    );
  }

  Color get color {
    switch (this) {
      case DuesStatus.paid:
        return const Color(0xFF10B981); // Green
      case DuesStatus.partial:
        return const Color(0xFFF59E0B); // Yellow/Orange
      case DuesStatus.overdue:
        return const Color(0xFFEF4444); // Red
      case DuesStatus.pending:
        return const Color(0xFF6B7280); // Gray
    }
  }

  String get displayName {
    switch (this) {
      case DuesStatus.paid:
        return 'Paid';
      case DuesStatus.partial:
        return 'Partial';
      case DuesStatus.overdue:
        return 'Overdue';
      case DuesStatus.pending:
        return 'Pending';
    }
  }
}

class Payment {
  final String id;
  final String brotherDuesId;
  final double amount;
  final DateTime paymentDate;
  final String? paymentMethod;
  final String? notes;

  Payment({
    required this.id,
    required this.brotherDuesId,
    required this.amount,
    required this.paymentDate,
    this.paymentMethod,
    this.notes,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      brotherDuesId: json['brother_dues_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['payment_date'] as String),
      paymentMethod: json['payment_method'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
