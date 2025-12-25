import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/suggestion_service.dart';
import '../models/suggestion_model.dart';
import 'transaction_provider.dart';
import 'inflation_provider.dart';
import 'preferences_provider.dart';

/// Suggestion Service Provider
final suggestionServiceProvider = Provider<SuggestionService>((ref) {
  return SuggestionService();
});

/// Cut Expense Suggestions Provider
/// Generates suggestions for reducing expenses based on transaction data
final cutExpenseSuggestionsProvider = Provider<List<Suggestion>>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final suggestionService = ref.watch(suggestionServiceProvider);
  final currency = ref.watch(currencyProvider);
  
  if (transactions.value == null) return [];
  
  return suggestionService.getCutExpenseSuggestions(transactions.value!, currency: currency);
});

/// Increase Income Suggestions Provider
/// Generates suggestions for increasing income based on income patterns
final increaseIncomeSuggestionsProvider = Provider<List<Suggestion>>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final suggestionService = ref.watch(suggestionServiceProvider);
  final currency = ref.watch(currencyProvider);
  
  if (transactions.value == null) return [];
  
  return suggestionService.getIncreaseIncomeSuggestions(transactions.value!, currency: currency);
});

/// Investment Suggestions Provider
/// Generates investment suggestions based on current inflation rate
final investmentSuggestionsProvider = Provider<List<Suggestion>>((ref) {
  final inflationRateAsync = ref.watch(inflationRateProvider);
  final suggestionService = ref.watch(suggestionServiceProvider);
  
  // Handle async inflation rate
  return inflationRateAsync.when(
    data: (rate) => suggestionService.getInvestmentSuggestions(rate),
    loading: () => [],
    error: (_, __) => suggestionService.getInvestmentSuggestions(null),
  );
});

/// All Suggestions Provider
/// Combines all suggestions and sorts by priority
final allSuggestionsProvider = Provider<List<Suggestion>>((ref) {
  final expenseSuggestions = ref.watch(cutExpenseSuggestionsProvider);
  final incomeSuggestions = ref.watch(increaseIncomeSuggestionsProvider);
  final investmentSuggestions = ref.watch(investmentSuggestionsProvider);
  
  // Combine all suggestions
  final allSuggestions = <Suggestion>[
    ...expenseSuggestions,
    ...incomeSuggestions,
    ...investmentSuggestions,
  ];
  
  // Sort by priority: high > medium > low
  allSuggestions.sort((a, b) {
    final priorityOrder = {
      Priority.high: 0,
      Priority.medium: 1,
      Priority.low: 2,
    };
    return priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
  });
  
  return allSuggestions;
});

