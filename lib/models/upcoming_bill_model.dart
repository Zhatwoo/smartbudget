import 'package:flutter/material.dart';

class UpcomingBillModel {
  final String title;
  final double amount;
  final DateTime dueDate;
  final IconData icon;
  final String category;
  final String? transactionId; // Reference to last transaction

  UpcomingBillModel({
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.icon,
    required this.category,
    this.transactionId,
  });

  // Calculate days until due
  int get daysUntilDue {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    return difference.inDays;
  }

  // Check if overdue
  bool get isOverdue => daysUntilDue < 0;

  // Check if due soon (within 3 days)
  bool get isDueSoon => daysUntilDue >= 0 && daysUntilDue <= 3;

  // Get status color
  Color get statusColor {
    if (isOverdue) return const Color(0xFFE74C3C);
    if (isDueSoon) return const Color(0xFFF39C12);
    return Colors.grey;
  }

  // Get status text
  String get statusText {
    if (isOverdue) return 'Overdue';
    if (daysUntilDue == 0) return 'Due today';
    if (daysUntilDue == 1) return 'Due tomorrow';
    return 'Due in $daysUntilDue days';
  }
}


