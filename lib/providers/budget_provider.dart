import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/budget_service.dart';
import '../services/transaction_service.dart';
import '../models/budget_model.dart';
import '../providers/transaction_provider.dart';

/// Budget Service Provider
final budgetServiceProvider = Provider<BudgetService>((ref) {
  return BudgetService();
});

/// Budgets Stream Provider
/// Streams all budgets for the current user
/// Used by Budget Planner screen
final budgetsProvider = StreamProvider<List<BudgetModel>>((ref) {
  final budgetService = ref.watch(budgetServiceProvider);
  return budgetService.getBudgets();
});

/// Budgets with Overspending Provider
/// Compares budgets vs transactions and highlights overspending
/// This is the critical dependency mentioned in workflow
final budgetsWithOverspendingProvider = Provider<List<BudgetModel>>((ref) {
  final budgets = ref.watch(budgetsProvider);
  final transactions = ref.watch(transactionsProvider);
  final budgetService = ref.watch(budgetServiceProvider);
  
  if (budgets.value == null || transactions.value == null) {
    return [];
  }
  
  final budgetsWithSpent = budgetService.getBudgetsWithOverspending(
    budgets.value!,
    transactions.value!,
  );
  
  // Check and create notifications for budget alerts (async, don't wait)
  budgetService.checkAndCreateBudgetNotifications(
    budgets.value!,
    transactions.value!,
  ).catchError((e) {
    // Silently fail - notifications are not critical
  });
  
  return budgetsWithSpent;
});

