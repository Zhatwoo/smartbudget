import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/transaction_service.dart';
import '../models/transaction_model.dart';

/// Transaction Service Provider
final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService();
});

/// Transactions Stream Provider
/// Streams all transactions for the current user
/// Used by Dashboard, Expenses List, Budget Planner, Analytics
final transactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final transactionService = ref.watch(transactionServiceProvider);
  return transactionService.getTransactions();
});

/// Total Balance Provider
/// Calculates total balance from transactions
final totalBalanceProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final transactionService = ref.watch(transactionServiceProvider);
  
  if (transactions.value == null) return 0.0;
  return transactionService.calculateTotalBalance(transactions.value!);
});

/// Total Income Provider
final totalIncomeProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final transactionService = ref.watch(transactionServiceProvider);
  
  if (transactions.value == null) return 0.0;
  return transactionService.calculateTotalIncome(transactions.value!);
});

/// Total Expenses Provider
final totalExpensesProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final transactionService = ref.watch(transactionServiceProvider);
  
  if (transactions.value == null) return 0.0;
  return transactionService.calculateTotalExpenses(transactions.value!);
});

/// Recent Transactions Provider (last 4)
final recentTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final transactions = ref.watch(transactionsProvider);
  if (transactions.value == null) return [];
  return transactions.value!.take(4).toList();
});

/// Transactions by Category Provider
/// Used for filtering expenses by category
final transactionsByCategoryProvider = FutureProvider.family<List<TransactionModel>, String>((ref, category) async {
  final transactionService = ref.watch(transactionServiceProvider);
  return await transactionService.getTransactionsByCategory(category);
});

