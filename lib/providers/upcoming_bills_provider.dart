import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../models/upcoming_bill_model.dart';
import '../providers/transaction_provider.dart';
import 'package:flutter/material.dart';

/// Upcoming Bills Provider
/// Analyzes transactions to identify recurring bills and predict upcoming due dates
/// Used by Dashboard and Budget Planner screens
final upcomingBillsProvider = Provider<List<UpcomingBillModel>>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);

  if (transactionsAsync.value == null) return [];

  final transactions = transactionsAsync.value!;
  final now = DateTime.now();

  // Filter for "Bills" category expenses
  final billTransactions = transactions
      .where((t) => t.type == 'expense' && t.category.toLowerCase() == 'bills')
      .toList();

  if (billTransactions.isEmpty) return [];

  // Group bills by title (case-insensitive)
  final billsByTitle = <String, List<TransactionModel>>{};
  for (final transaction in billTransactions) {
    final title = transaction.title.toLowerCase().trim();
    billsByTitle.putIfAbsent(title, () => []).add(transaction);
  }

  // Identify recurring bills and calculate next due date
  final upcomingBills = <UpcomingBillModel>[];

  for (final entry in billsByTitle.entries) {
    final title = entry.key;
    final transactions = entry.value;

    // Need at least 2 transactions to identify a pattern
    if (transactions.length < 2) continue;

    // Sort by date (most recent first)
    transactions.sort((a, b) => b.date.compareTo(a.date));

    // Get the most recent transaction
    final lastTransaction = transactions[0];
    final lastAmount = lastTransaction.amount.abs();

    // Calculate average interval between transactions
    if (transactions.length >= 2) {
      final intervals = <int>[];
      for (int i = 0; i < transactions.length - 1; i++) {
        final daysDiff = transactions[i].date.difference(transactions[i + 1].date).inDays;
        if (daysDiff > 0 && daysDiff <= 35) { // Monthly bills (25-35 days)
          intervals.add(daysDiff);
        }
      }

      if (intervals.isNotEmpty) {
        // Calculate average interval
        final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;

        // Predict next due date (last transaction date + average interval)
        final nextDueDate = lastTransaction.date.add(Duration(days: avgInterval.round()));

        // Only include if due date is in the future or within last 7 days (overdue)
        if (nextDueDate.isAfter(now.subtract(const Duration(days: 7)))) {
          // Get icon based on bill title
          final icon = _getBillIcon(lastTransaction.title);

          upcomingBills.add(UpcomingBillModel(
            title: lastTransaction.title,
            amount: lastAmount,
            dueDate: nextDueDate,
            icon: icon,
            category: lastTransaction.category,
            transactionId: lastTransaction.id,
          ));
        }
      } else {
        // If no clear pattern, assume monthly (30 days from last payment)
        final nextDueDate = lastTransaction.date.add(const Duration(days: 30));

        if (nextDueDate.isAfter(now.subtract(const Duration(days: 7)))) {
          final icon = _getBillIcon(lastTransaction.title);

          upcomingBills.add(UpcomingBillModel(
            title: lastTransaction.title,
            amount: lastAmount,
            dueDate: nextDueDate,
            icon: icon,
            category: lastTransaction.category,
            transactionId: lastTransaction.id,
          ));
        }
      }
    }
  }

  // Sort by due date (earliest first)
  upcomingBills.sort((a, b) => a.dueDate.compareTo(b.dueDate));

  return upcomingBills;
});

/// Get icon for bill based on title
IconData _getBillIcon(String title) {
  final titleLower = title.toLowerCase();

  if (titleLower.contains('electric') || titleLower.contains('power') || titleLower.contains('meralco')) {
    return Icons.bolt;
  } else if (titleLower.contains('water') || titleLower.contains('maynilad') || titleLower.contains('manila water')) {
    return Icons.water_drop;
  } else if (titleLower.contains('internet') || titleLower.contains('wifi') || titleLower.contains('pldt') || titleLower.contains('globe')) {
    return Icons.wifi;
  } else if (titleLower.contains('phone') || titleLower.contains('mobile') || titleLower.contains('smart') || titleLower.contains('globe')) {
    return Icons.phone;
  } else if (titleLower.contains('rent') || titleLower.contains('apartment')) {
    return Icons.home;
  } else if (titleLower.contains('credit') || titleLower.contains('card') || titleLower.contains('loan')) {
    return Icons.credit_card;
  } else if (titleLower.contains('insurance')) {
    return Icons.shield;
  } else if (titleLower.contains('subscription') || titleLower.contains('netflix') || titleLower.contains('spotify')) {
    return Icons.subscriptions;
  } else {
    return Icons.receipt_long;
  }
}


