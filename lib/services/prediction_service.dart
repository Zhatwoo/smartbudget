import '../models/transaction_model.dart';
import '../models/inflation_item_model.dart';
import '../models/budget_model.dart';
import 'dart:math' as math;

/// Service for handling prediction logic
/// Handles business logic for expense predictions
/// Returns prediction data
/// NO UI logic - pure business logic only
/// NO Firebase calls - works with data from providers
class PredictionService {
  /// Predict future spending based on transaction history
  /// Uses simple moving average for prediction
  /// Returns predicted amount for next period
  double predictFutureSpending(
    List<TransactionModel> transactions,
    String category,
    int daysToPredict,
  ) {
    // Filter transactions by category and get expenses only
    final categoryExpenses = transactions
        .where((t) => t.category == category && t.type == 'expense')
        .toList();

    if (categoryExpenses.isEmpty) return 0.0;

    // Calculate average daily spending
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final recentExpenses = categoryExpenses
        .where((t) => t.date.isAfter(thirtyDaysAgo))
        .toList();

    if (recentExpenses.isEmpty) return 0.0;

    final totalSpending = recentExpenses
        .fold(0.0, (sum, t) => sum + t.amount.abs());
    
    final daysInPeriod = now.difference(thirtyDaysAgo).inDays;
    final averageDailySpending = totalSpending / daysInPeriod;

    // Predict for next period
    return averageDailySpending * daysToPredict;
  }

  /// Predict future prices for inflation items
  /// Uses linear regression on price history
  /// Returns predicted prices for next N periods
  List<double> predictFuturePrices(
    InflationItemModel item,
    int periods,
  ) {
    final history = item.priceHistory;
    if (history.length < 2) {
      // Not enough data, return current price
      return List.filled(periods, item.currentPrice);
    }

    // Simple linear regression
    final n = history.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    for (int i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = history[i];
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    // Predict next periods
    final predictions = <double>[];
    for (int i = 1; i <= periods; i++) {
      final predictedPrice = slope * (n + i - 1) + intercept;
      predictions.add(predictedPrice > 0 ? predictedPrice : item.currentPrice);
    }

    return predictions;
  }

  /// Get spending trend (increasing, decreasing, stable)
  /// Returns trend analysis for a category
  String getSpendingTrend(
    List<TransactionModel> transactions,
    String category,
  ) {
    final categoryExpenses = transactions
        .where((t) => t.category == category && t.type == 'expense')
        .toList();

    if (categoryExpenses.length < 2) return 'stable';

    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    final previousWeek = lastWeek.subtract(const Duration(days: 7));

    final lastWeekSpending = categoryExpenses
        .where((t) => t.date.isAfter(lastWeek))
        .fold(0.0, (sum, t) => sum + t.amount.abs());

    final previousWeekSpending = categoryExpenses
        .where((t) => t.date.isAfter(previousWeek) && t.date.isBefore(lastWeek))
        .fold(0.0, (sum, t) => sum + t.amount.abs());

    if (previousWeekSpending == 0) return 'stable';

    final change = ((lastWeekSpending - previousWeekSpending) / previousWeekSpending) * 100;

    if (change > 10) return 'increasing';
    if (change < -10) return 'decreasing';
    return 'stable';
  }

  /// Predict total expenses for next month
  /// Aggregates predictions across all categories
  double predictNextMonthExpenses(List<TransactionModel> transactions) {
    final categories = transactions
        .where((t) => t.type == 'expense')
        .map((t) => t.category)
        .toSet();

    double totalPredicted = 0.0;
    for (final category in categories) {
      totalPredicted += predictFutureSpending(transactions, category, 30);
    }

    return totalPredicted;
  }

  /// Predict expenses for next N months
  /// Uses historical monthly data, budget constraints, and inflation
  /// Returns list of predicted amounts for each month
  List<MonthlyPrediction> predictNextMonthsExpenses(
    List<TransactionModel> transactions,
    int numberOfMonths, {
    List<BudgetModel>? budgets,
    double? inflationRate,
  }) {
    final predictions = <MonthlyPrediction>[];
    final now = DateTime.now();
    
    // Get historical monthly spending (last 6 months)
    final historicalMonthlySpending = _getHistoricalMonthlySpending(transactions, 6);
    
    // Get categories
    final categories = transactions
        .where((t) => t.type == 'expense')
        .map((t) => t.category)
        .toSet();

    // Predict for each month
    for (int monthOffset = 1; monthOffset <= numberOfMonths; monthOffset++) {
      final targetMonth = DateTime(now.year, now.month + monthOffset, 1);
      final monthName = _getMonthName(targetMonth.month);
      
      // Predict spending for this month using multiple methods
      double monthPrediction = 0.0;
      
      // Method 1: Historical average (if we have enough data)
      double historicalAverage = 0.0;
      if (historicalMonthlySpending.isNotEmpty) {
        historicalAverage = historicalMonthlySpending.values.reduce((a, b) => a + b) / historicalMonthlySpending.length;
      }
      
      // Method 2: Category-based prediction with trend
      double categoryBasedPrediction = 0.0;
      for (final category in categories) {
        final categoryMonthlyAvg = _getCategoryMonthlyAverage(transactions, category);
        final trend = _getCategoryTrend(transactions, category);
        
        // Apply trend (increasing/decreasing)
        double categoryPrediction = categoryMonthlyAvg;
        if (trend > 0.05) {
          // Increasing trend - add 5% per month
          categoryPrediction *= (1 + (trend * monthOffset));
        } else if (trend < -0.05) {
          // Decreasing trend
          categoryPrediction *= (1 + (trend * monthOffset));
        }
        
        // Apply inflation if provided
        if (inflationRate != null && inflationRate > 0) {
          categoryPrediction *= (1 + (inflationRate / 100) * monthOffset);
        }
        
        // Consider budget limit if available
        if (budgets != null) {
          final budget = budgets.firstWhere(
            (b) => b.category == category,
            orElse: () => BudgetModel(
              category: category,
              limit: 0,
              spent: 0,
              startDate: now,
              endDate: now,
            ),
          );
          
          // If budget exists and prediction exceeds it, cap at budget + 10% buffer
          if (budget.limit > 0 && categoryPrediction > budget.limit) {
            categoryPrediction = budget.limit * 1.1; // 10% buffer for safety
          }
        }
        
        categoryBasedPrediction += categoryPrediction;
      }
      
      // Combine methods: 70% category-based, 30% historical average (if available)
      if (historicalAverage > 0) {
        monthPrediction = (categoryBasedPrediction * 0.7) + (historicalAverage * 0.3);
      } else {
        monthPrediction = categoryBasedPrediction;
      }

      predictions.add(MonthlyPrediction(
        month: monthName,
        monthIndex: targetMonth.month,
        amount: monthPrediction,
      ));
    }

    return predictions;
  }

  /// Get average daily spending for a category
  double _getCategoryDailyAverage(
    List<TransactionModel> transactions,
    String category,
  ) {
    final categoryExpenses = transactions
        .where((t) => t.category == category && t.type == 'expense')
        .toList();

    if (categoryExpenses.isEmpty) return 0.0;

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final recentExpenses = categoryExpenses
        .where((t) => t.date.isAfter(thirtyDaysAgo))
        .toList();

    if (recentExpenses.isEmpty) return 0.0;

    final totalSpending = recentExpenses
        .fold(0.0, (sum, t) => sum + t.amount.abs());
    
    final daysInPeriod = now.difference(thirtyDaysAgo).inDays;
    return totalSpending / daysInPeriod;
  }

  /// Get month name abbreviation
  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  /// Get current month total spending
  double getCurrentMonthSpending(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    
    return transactions
        .where((t) => 
            t.type == 'expense' && 
            t.date.isAfter(currentMonthStart.subtract(const Duration(days: 1))))
        .fold(0.0, (sum, t) => sum + t.amount.abs());
  }

  /// Get historical monthly spending for the last N months
  Map<String, double> _getHistoricalMonthlySpending(
    List<TransactionModel> transactions,
    int numberOfMonths,
  ) {
    final monthlySpending = <String, double>{};
    final now = DateTime.now();
    
    for (int i = numberOfMonths - 1; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthStart = DateTime(monthDate.year, monthDate.month, 1);
      final monthEnd = DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59, 59);
      
      final monthKey = '${monthDate.year}-${monthDate.month.toString().padLeft(2, '0')}';
      
      final monthExpenses = transactions
          .where((t) => 
              t.type == 'expense' &&
              t.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
              t.date.isBefore(monthEnd.add(const Duration(days: 1))))
          .fold(0.0, (sum, t) => sum + t.amount.abs());
      
      monthlySpending[monthKey] = monthExpenses;
    }
    
    return monthlySpending;
  }

  /// Get average monthly spending for a category
  double _getCategoryMonthlyAverage(
    List<TransactionModel> transactions,
    String category,
  ) {
    final categoryExpenses = transactions
        .where((t) => t.category == category && t.type == 'expense')
        .toList();

    if (categoryExpenses.isEmpty) return 0.0;

    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);
    
    // Get monthly totals for last 6 months
    final monthlyTotals = <double>[];
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthStart = DateTime(monthDate.year, monthDate.month, 1);
      final monthEnd = DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59, 59);
      
      final monthTotal = categoryExpenses
          .where((t) => 
              t.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
              t.date.isBefore(monthEnd.add(const Duration(days: 1))))
          .fold(0.0, (sum, t) => sum + t.amount.abs());
      
      if (monthTotal > 0) {
        monthlyTotals.add(monthTotal);
      }
    }

    if (monthlyTotals.isEmpty) {
      // Fallback to 30-day average if no monthly data
      return _getCategoryDailyAverage(transactions, category) * 30;
    }

    return monthlyTotals.reduce((a, b) => a + b) / monthlyTotals.length;
  }

  /// Get trend for a category (positive = increasing, negative = decreasing)
  /// Returns rate of change per month (e.g., 0.05 = 5% increase per month)
  double _getCategoryTrend(
    List<TransactionModel> transactions,
    String category,
  ) {
    final categoryExpenses = transactions
        .where((t) => t.category == category && t.type == 'expense')
        .toList();

    if (categoryExpenses.length < 2) return 0.0;

    final now = DateTime.now();
    
    // Get last 3 months of data
    final monthlyTotals = <double>[];
    for (int i = 2; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthStart = DateTime(monthDate.year, monthDate.month, 1);
      final monthEnd = DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59, 59);
      
      final monthTotal = categoryExpenses
          .where((t) => 
              t.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
              t.date.isBefore(monthEnd.add(const Duration(days: 1))))
          .fold(0.0, (sum, t) => sum + t.amount.abs());
      
      monthlyTotals.add(monthTotal);
    }

    if (monthlyTotals.length < 2) return 0.0;

    // Calculate trend using linear regression
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    final n = monthlyTotals.length;

    for (int i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = monthlyTotals[i];
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    if (n * sumX2 - sumX * sumX == 0) return 0.0;

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final averageY = sumY / n;

    // Return normalized trend (slope / average)
    return averageY > 0 ? slope / averageY : 0.0;
  }
}

/// Monthly Prediction Model
class MonthlyPrediction {
  final String month;
  final int monthIndex;
  final double amount;

  MonthlyPrediction({
    required this.month,
    required this.monthIndex,
    required this.amount,
  });
}

