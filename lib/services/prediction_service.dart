import '../models/transaction_model.dart';
import '../models/inflation_item_model.dart';

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
  /// Returns list of predicted amounts for each month
  List<MonthlyPrediction> predictNextMonthsExpenses(
    List<TransactionModel> transactions,
    int numberOfMonths,
  ) {
    final predictions = <MonthlyPrediction>[];
    final now = DateTime.now();
    
    // Get current month spending
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentMonthExpenses = transactions
        .where((t) => 
            t.type == 'expense' && 
            t.date.isAfter(currentMonthStart.subtract(const Duration(days: 1))))
        .fold(0.0, (sum, t) => sum + t.amount.abs());

    // Get categories
    final categories = transactions
        .where((t) => t.type == 'expense')
        .map((t) => t.category)
        .toSet();

    // Predict for each month
    for (int monthOffset = 1; monthOffset <= numberOfMonths; monthOffset++) {
      final targetMonth = DateTime(now.year, now.month + monthOffset, 1);
      final monthName = _getMonthName(targetMonth.month);
      
      // Calculate days in target month
      final daysInMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
      
      // Predict spending for this month
      double monthPrediction = 0.0;
      for (final category in categories) {
        // Use 30-day average and scale to month
        final dailyAverage = _getCategoryDailyAverage(transactions, category);
        monthPrediction += dailyAverage * daysInMonth;
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

