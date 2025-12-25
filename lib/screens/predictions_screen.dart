import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../providers/providers.dart';
import '../models/budget_model.dart';
import '../utils/currency_formatter.dart';

class PredictionsScreen extends ConsumerWidget {
  const PredictionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get data from providers (UI → Provider → Service → Firebase)
    final transactionsAsync = ref.watch(transactionsProvider);
    final predictions = ref.watch(monthlyPredictionsProvider);
    final currentMonthSpending = ref.watch(currentMonthSpendingProvider);
    final futureSpending = ref.watch(futureSpendingPredictionProvider);
    final budgetsAsync = ref.watch(budgetsProvider);
    final budgets = budgetsAsync.value ?? [];
    final currency = ref.watch(currencyProvider);

    // Show loading if transactions are still loading
    if (transactionsAsync.isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF4A90E2),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Expense Predictions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Loading
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate statistics
    final averagePrediction = predictions.isEmpty
        ? 0.0
        : predictions.fold(0.0, (sum, p) => sum + p.amount) / predictions.length;
    
    final maxPrediction = predictions.isEmpty
        ? 0.0
        : predictions.map((p) => p.amount).reduce(math.max);
    
    final minPrediction = predictions.isEmpty
        ? 0.0
        : predictions.map((p) => p.amount).reduce(math.min);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header (matching dashboard style)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF4A90E2),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Expense Predictions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: predictions.isEmpty || averagePrediction == 0.0
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.trending_up_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No predictions available',
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add transactions to see predictions',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary Card - only show if there's data
                          if (averagePrediction > 0 && currentMonthSpending > 0) ...[
                            _buildSummaryCard(
                              averagePrediction,
                              currentMonthSpending,
                              predictions.length,
                              currency,
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Predictions Chart - only show if there's data
                          if (predictions.isNotEmpty && maxPrediction > 0) ...[
                            _buildPredictionsChart(context, predictions, maxPrediction, currency),
                            const SizedBox(height: 24),
                          ],

                          // Monthly Breakdown - only show if there's data
                          if (predictions.isNotEmpty) ...[
                            _buildMonthlyBreakdown(
                              context,
                              ref,
                              predictions,
                              currentMonthSpending,
                              currency,
                              budgets,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    double averagePrediction,
    double currentMonthSpending,
    int numberOfMonths,
    String currency,
  ) {
    final averageChange = averagePrediction - currentMonthSpending;
    final averageChangePercent = currentMonthSpending > 0
        ? (averageChange / currentMonthSpending) * 100
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A90E2), // Bright Blue
            Color(0xFF5DADE2), // Light Blue
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90E2).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Average Predicted Spending',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CurrencyFormatter.format(averagePrediction, currency),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Next $numberOfMonths months',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(
                        averageChange >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${averageChangePercent >= 0 ? '+' : ''}${averageChangePercent.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'vs Current Month',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionsChart(
    BuildContext context,
    List<MonthlyPrediction> predictions,
    double maxAmount,
    String currency,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Predicted Expenses by Month',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 250,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: predictions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final prediction = entry.value;
                    final height = maxAmount > 0
                        ? (prediction.amount / maxAmount) * 200
                        : 0.0;
                    final colors = [
                      [const Color(0xFF4A90E2), const Color(0xFF5DADE2)],
                      [const Color(0xFF27AE60), const Color(0xFF2ECC71)],
                      [const Color(0xFFF39C12), const Color(0xFFE67E22)],
                      [const Color(0xFF9B59B6), const Color(0xFF8E44AD)],
                      [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
                      [const Color(0xFF16A085), const Color(0xFF138D75)],
                    ];
                    final barColors = colors[index % colors.length];

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxHeight: 200,
                                  minHeight: height > 0 ? height : 0,
                                ),
                                height: height > 0 ? height : null,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: barColors,
                                  ),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: barColors[0].withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: height > 20
                                    ? Center(
                                        child: Text(
                                          '${CurrencyFormatter.extractSymbol(currency)}${(prediction.amount / 1000).toStringAsFixed(0)}k',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              prediction.month,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(prediction.amount, currency),
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyBreakdown(
    BuildContext context,
    WidgetRef ref,
    List<MonthlyPrediction> predictions,
    double currentMonthSpending,
    String currency,
    List<BudgetModel> budgets,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Breakdown',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        ...predictions.map((prediction) {
          final change = prediction.amount - currentMonthSpending;
          final changePercent = currentMonthSpending > 0
              ? (change / currentMonthSpending) * 100
              : 0.0;
          final isIncrease = change >= 0;

          // Calculate total budget for comparison
          final totalBudget = budgets.fold<double>(
            0.0,
            (sum, budget) => sum + budget.limit,
          );
          final exceedsBudget = totalBudget > 0 && prediction.amount > totalBudget;
          final budgetDifference = totalBudget > 0 ? prediction.amount - totalBudget : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Month
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    prediction.month,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A90E2),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Amount and Change
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        CurrencyFormatter.format(prediction.amount, currency),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            isIncrease
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 14,
                            color: isIncrease
                                ? const Color(0xFFE74C3C)
                                : const Color(0xFF27AE60),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}% vs current',
                              style: TextStyle(
                                fontSize: 13,
                                color: isIncrease
                                    ? const Color(0xFFE74C3C)
                                    : const Color(0xFF27AE60),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      // Budget Warning (if exceeds budget) - moved here
                      if (exceedsBudget) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE74C3C).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFE74C3C).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning_rounded,
                                color: Color(0xFFE74C3C),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Exceeds budget by ${CurrencyFormatter.format(budgetDifference, currency)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFE74C3C),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (totalBudget > 0 && prediction.amount <= totalBudget) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF27AE60).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF27AE60).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF27AE60),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Within budget',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF27AE60),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Trend Indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isIncrease
                        ? const Color(0xFFE74C3C).withOpacity(0.1)
                        : const Color(0xFF27AE60).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isIncrease
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: isIncrease
                        ? const Color(0xFFE74C3C)
                        : const Color(0xFF27AE60),
                    size: 20,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
