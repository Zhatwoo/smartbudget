import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/prediction_service.dart';
import '../models/transaction_model.dart';
import '../models/inflation_item_model.dart';
import '../models/budget_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/inflation_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/notification_provider.dart';

// Export MonthlyPrediction from service
export '../services/prediction_service.dart' show MonthlyPrediction;

/// Prediction Service Provider
final predictionServiceProvider = Provider<PredictionService>((ref) {
  return PredictionService();
});

/// Future Spending Prediction Provider
/// Predicts spending for next month
/// Used by Dashboard and Predictions screen
final futureSpendingPredictionProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final predictionService = ref.watch(predictionServiceProvider);
  
  if (transactions.value == null) return 0.0;
  
  return predictionService.predictNextMonthExpenses(transactions.value!);
});

/// Category Spending Prediction Provider
/// Predicts spending for a specific category
final categorySpendingPredictionProvider = FutureProvider.family<double, String>((ref, category) async {
  final transactions = ref.watch(transactionsProvider);
  final predictionService = ref.watch(predictionServiceProvider);
  
  if (transactions.value == null) return 0.0;
  
  // Predict for next 30 days
  return predictionService.predictFutureSpending(
    transactions.value!,
    category,
    30,
  );
});

/// Spending Trend Provider
/// Returns trend (increasing, decreasing, stable) for a category
final spendingTrendProvider = Provider.family<String, String>((ref, category) {
  final transactions = ref.watch(transactionsProvider);
  final predictionService = ref.watch(predictionServiceProvider);
  
  if (transactions.value == null) return 'stable';
  
  return predictionService.getSpendingTrend(transactions.value!, category);
});

/// Inflation Price Predictions Provider
/// Predicts future prices for inflation items
final inflationPricePredictionsProvider = Provider.family<List<double>, InflationItemModel>((ref, item) {
  final predictionService = ref.watch(predictionServiceProvider);
  
  // Predict next 6 months
  return predictionService.predictFuturePrices(item, 6);
});

/// Monthly Predictions Provider
/// Predicts expenses for next 6 months
/// Used by Predictions screen
final monthlyPredictionsProvider = Provider<List<MonthlyPrediction>>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final predictionService = ref.watch(predictionServiceProvider);
  
  if (transactions.value == null) return [];
  
  // Predict next 6 months
  return predictionService.predictNextMonthsExpenses(transactions.value!, 6);
});

/// Current Month Spending Provider
/// Gets total spending for current month
/// Used by Predictions screen and Analytics
final currentMonthSpendingProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final predictionService = ref.watch(predictionServiceProvider);
  
  if (transactions.value == null) return 0.0;
  
  return predictionService.getCurrentMonthSpending(transactions.value!);
});

/// Prediction vs Budget Alerts Provider
/// Checks if predictions exceed budgets and creates notifications
/// Used by Budget Planner and Notifications
final predictionBudgetAlertsProvider = Provider<void>((ref) {
  final predictions = ref.watch(monthlyPredictionsProvider);
  final budgets = ref.watch(budgetsProvider);
  final notificationService = ref.read(notificationServiceProvider);
  
  if (predictions.isEmpty || budgets.value == null) return;
  
  // Check next month prediction against budgets
  if (predictions.isNotEmpty) {
    final nextMonthPrediction = predictions[0].amount;
    
    // Get category predictions
    final transactions = ref.watch(transactionsProvider);
    final predictionService = ref.read(predictionServiceProvider);
    
    if (transactions.value != null) {
      final categories = transactions.value!
          .where((t) => t.type == 'expense')
          .map((t) => t.category)
          .toSet();
      
      for (final category in categories) {
        final categoryPrediction = predictionService.predictFutureSpending(
          transactions.value!,
          category,
          30,
        );
        
        // Find budget for this category
        final budget = budgets.value!.firstWhere(
          (b) => b.category == category,
          orElse: () => BudgetModel(
            category: category,
            limit: 0,
            spent: 0,
            startDate: DateTime.now(),
            endDate: DateTime.now(),
          ),
        );
        
        if (budget.limit > 0 && categoryPrediction > budget.limit) {
          // Create notification (async, don't wait)
          notificationService.checkPredictionBudgetAlerts(
            predictedAmount: categoryPrediction,
            budgetLimit: budget.limit,
            category: category,
          ).catchError((e) {
            // Silently fail
          });
        }
      }
    }
  }
});

