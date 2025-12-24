import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/prediction_provider.dart';
import '../providers/inflation_provider.dart';

/// Category Spending Analytics Provider
/// Aggregates transactions by category for charts
/// Used by Analytics/Reports screen
final categorySpendingAnalyticsProvider = Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(transactionsProvider);
  
  if (transactions.value == null) return {};
  
  final categoryMap = <String, double>{};
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  
  // Filter transactions for current month
  final monthlyTransactions = transactions.value!.where((t) => 
    t.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
    t.type == 'expense'
  ).toList();

  // Group by category and sum expenses
  for (var transaction in monthlyTransactions) {
    categoryMap[transaction.category] = 
        (categoryMap[transaction.category] ?? 0) + transaction.amount.abs();
  }

  return categoryMap;
});

/// Monthly Spending Trend Provider
/// Returns spending data for last 6 months
final monthlySpendingTrendProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final transactions = ref.watch(transactionsProvider);
  
  if (transactions.value == null) return [];
  
  final now = DateTime.now();
  final trends = <Map<String, dynamic>>[];
  
  // Get last 6 months
  for (int i = 5; i >= 0; i--) {
    final monthStart = DateTime(now.year, now.month - i, 1);
    final monthEnd = DateTime(now.year, now.month - i + 1, 0);
    
    final monthTransactions = transactions.value!.where((t) =>
      t.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
      t.date.isBefore(monthEnd.add(const Duration(days: 1))) &&
      t.type == 'expense'
    ).toList();
    
    final total = monthTransactions.fold(0.0, (sum, t) => sum + t.amount.abs());
    
    trends.add({
      'month': monthStart.month,
      'year': monthStart.year,
      'total': total,
      'count': monthTransactions.length,
    });
  }
  
  return trends;
});

/// Expense Predictions for Analytics
/// Uses prediction service to generate future spending predictions
final analyticsExpensePredictionsProvider = Provider<Map<String, dynamic>>((ref) {
  final futureSpending = ref.watch(futureSpendingPredictionProvider);
  final currentMonthSpending = ref.watch(currentMonthSpendingProvider);
  
  return {
    'predictedNextMonth': futureSpending,
    'currentMonth': currentMonthSpending,
    'change': futureSpending - currentMonthSpending,
    'changePercent': currentMonthSpending > 0 
        ? ((futureSpending - currentMonthSpending) / currentMonthSpending * 100)
        : 0.0,
  };
});

/// Inflation Impact Provider
/// Calculates inflation impact on expenses
/// Used by Analytics screen
final inflationImpactProvider = Provider<Map<String, dynamic>>((ref) {
  final inflationItems = ref.watch(inflationItemsProvider);
  final currentMonthSpending = ref.watch(currentMonthSpendingProvider);
  
  if (inflationItems.value == null || inflationItems.value!.isEmpty) {
    return {
      'inflationRate': 0.0,
      'inflationAmount': 0.0,
      'averageInflation': 0.0,
    };
  }
  
  // Calculate average inflation rate from all items
  final items = inflationItems.value!;
  final totalInflation = items.fold(0.0, (sum, item) => sum + item.percentageChange.abs());
  final averageInflation = totalInflation / items.length;
  
  // Calculate inflation impact on current month spending
  final inflationAmount = currentMonthSpending > 0
      ? (currentMonthSpending * averageInflation / 100)
      : 0.0;
  
  return {
    'inflationRate': averageInflation,
    'inflationAmount': inflationAmount,
    'averageInflation': averageInflation,
    'itemCount': items.length,
  };
});

/// Monthly Spending with Month Names Provider
/// Returns spending data for last 6 months with month abbreviations
final monthlySpendingWithNamesProvider = Provider<List<MonthlySpendingData>>((ref) {
  final trends = ref.watch(monthlySpendingTrendProvider);
  
  const monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  
  return trends.map((trend) {
    return MonthlySpendingData(
      month: monthNames[trend['month'] - 1],
      amount: trend['total'] as double,
      monthIndex: trend['month'] as int,
      year: trend['year'] as int,
    );
  }).toList();
});

/// Category Spending with Colors Provider
/// Returns category spending with assigned colors
final categorySpendingWithColorsProvider = Provider<List<CategorySpendingData>>((ref) {
  final categoryMap = ref.watch(categorySpendingAnalyticsProvider);
  
  // Category color mapping
  final categoryColors = {
    'Food': const Color(0xFFE74C3C),
    'Transport': const Color(0xFF4A90E2),
    'Bills': const Color(0xFFF39C12),
    'Shopping': const Color(0xFF27AE60),
    'Entertainment': const Color(0xFF9B59B6),
    'Healthcare': const Color(0xFFE67E22),
    'Education': const Color(0xFF3498DB),
    'Travel': const Color(0xFF16A085),
  };
  
  final categoryList = categoryMap.entries.map((entry) {
    return CategorySpendingData(
      name: entry.key,
      amount: entry.value,
      color: categoryColors[entry.key] ?? const Color(0xFF95A5A6),
    );
  }).toList();
  
  // Sort by amount descending
  categoryList.sort((a, b) => b.amount.compareTo(a.amount));
  
  return categoryList;
});

/// Monthly Spending Data Model
class MonthlySpendingData {
  final String month;
  final double amount;
  final int monthIndex;
  final int year;

  MonthlySpendingData({
    required this.month,
    required this.amount,
    required this.monthIndex,
    required this.year,
  });
}

/// Category Spending Data Model
class CategorySpendingData {
  final String name;
  final double amount;
  final Color color;

  CategorySpendingData({
    required this.name,
    required this.amount,
    required this.color,
  });
}

