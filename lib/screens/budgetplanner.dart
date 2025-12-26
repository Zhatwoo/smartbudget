import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/budget_model.dart';
import '../models/upcoming_bill_model.dart';
import '../models/bill_model.dart';
import '../models/transaction_model.dart';
import '../utils/currency_formatter.dart';

class BudgetPlannerScreen extends ConsumerStatefulWidget {
  const BudgetPlannerScreen({super.key});

  @override
  ConsumerState<BudgetPlannerScreen> createState() => _BudgetPlannerScreenState();
}

class _BudgetPlannerScreenState extends ConsumerState<BudgetPlannerScreen> {
  // Helper to get icon and color for category
  Map<String, dynamic> _getCategoryStyle(String category) {
    final categoryLower = category.toLowerCase();
    
    if (categoryLower.contains('food') || categoryLower.contains('restaurant') || categoryLower.contains('grocer')) {
      return {
        'icon': Icons.restaurant,
        'color': const Color(0xFFE74C3C),
      };
    } else if (categoryLower.contains('transport') || categoryLower.contains('car') || categoryLower.contains('gas')) {
      return {
        'icon': Icons.directions_car,
        'color': const Color(0xFF4A90E2),
      };
    } else if (categoryLower.contains('bill') || categoryLower.contains('utility')) {
      return {
        'icon': Icons.receipt_long,
        'color': const Color(0xFFF39C12),
      };
    } else if (categoryLower.contains('shop') || categoryLower.contains('retail')) {
      return {
        'icon': Icons.shopping_bag,
        'color': const Color(0xFF27AE60),
      };
    } else if (categoryLower.contains('entertain') || categoryLower.contains('movie') || categoryLower.contains('game')) {
      return {
        'icon': Icons.movie,
        'color': const Color(0xFF9B59B6),
      };
    } else if (categoryLower.contains('health') || categoryLower.contains('medical') || categoryLower.contains('hospital')) {
      return {
        'icon': Icons.local_hospital,
        'color': const Color(0xFFE67E22),
      };
    } else if (categoryLower.contains('education') || categoryLower.contains('school')) {
      return {
        'icon': Icons.school,
        'color': const Color(0xFF3498DB),
      };
    } else if (categoryLower.contains('travel') || categoryLower.contains('vacation')) {
      return {
        'icon': Icons.flight,
        'color': const Color(0xFF16A085),
      };
    } else {
      // Default
      return {
        'icon': Icons.category,
        'color': const Color(0xFF95A5A6),
      };
    }
  }

  void _editBudget(BudgetModel budget) {
    final amountController = TextEditingController(
      text: budget.limit.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: Text(
          'Edit Budget - ${budget.category}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: 'Monthly Budget',
                prefixText: '${CurrencyFormatter.extractSymbol(ref.read(currencyProvider))} ',
                prefixStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A90E2),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newAmount = double.tryParse(amountController.text);
              if (newAmount != null && newAmount > 0) {
                try {
                  final budgetService = ref.read(budgetServiceProvider);
                  final now = DateTime.now();
                  final startOfMonth = DateTime(now.year, now.month, 1);
                  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

                  final updatedBudget = budget.copyWith(
                    limit: newAmount,
                    startDate: startOfMonth,
                    endDate: endOfMonth,
                  );

                  await budgetService.saveBudget(updatedBudget);
                  
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Budget updated successfully'),
                      backgroundColor: Color(0xFF27AE60),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: const Color(0xFFE74C3C),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _addNewBudget() {
    final categoryController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = 'Food';

    final commonCategories = [
      'Food',
      'Transport',
      'Bills',
      'Shopping',
      'Entertainment',
      'Healthcare',
      'Education',
      'Travel',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            'Add New Budget',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
                items: commonCategories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'Monthly Budget',
                  prefixText: '${CurrencyFormatter.extractSymbol(ref.read(currencyProvider))} ',
                  prefixStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A90E2),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newAmount = double.tryParse(amountController.text);
                if (newAmount != null && newAmount > 0) {
                  try {
                    final budgetService = ref.read(budgetServiceProvider);
                    final now = DateTime.now();
                    final startOfMonth = DateTime(now.year, now.month, 1);
                    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

                    final newBudget = BudgetModel(
                      category: selectedCategory,
                      limit: newAmount,
                      spent: 0.0,
                      startDate: startOfMonth,
                      endDate: endOfMonth,
                    );

                    await budgetService.saveBudget(newBudget);
                    
                    if (!mounted) return;
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Budget created successfully'),
                        backgroundColor: Color(0xFF27AE60),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: const Color(0xFFE74C3C),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Create',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get budgets with calculated spent amounts (UI → Provider → Service → Firebase)
    final budgets = ref.watch(budgetsWithOverspendingProvider);
    final budgetsAsync = ref.watch(budgetsProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    // Show loading if budgets or transactions are still loading
    if (budgetsAsync.isLoading || transactionsAsync.isLoading) {
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
                      'Budget Planner',
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

    // Calculate totals
    final totalAllocated = budgets.fold(0.0, (sum, budget) => sum + budget.limit);
    final totalSpent = budgets.fold(0.0, (sum, budget) => sum + budget.spent);
    final totalRemaining = totalAllocated - totalSpent;
    final spentPercentage = totalAllocated > 0 ? (totalSpent / totalAllocated) * 100 : 0.0;

    // Filter budgets by status
    final overspentBudgets = budgets.where((b) => b.isExceeded).toList();
    final atRiskBudgets = budgets.where((b) => b.isAtRisk && !b.isExceeded).toList();

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
                    'Budget Planner',
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
              child: budgets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No budgets set',
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a budget to start tracking',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _addNewBudget,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Create Budget'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A90E2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                          // Summary Card
                          _buildSummaryCard(totalAllocated, totalSpent, totalRemaining, spentPercentage),
                          const SizedBox(height: 24),

                          // Alerts Section
                          if (overspentBudgets.isNotEmpty) ...[
                            _buildOverspendingAlerts(overspentBudgets),
                            const SizedBox(height: 24),
                          ],

                          if (atRiskBudgets.isNotEmpty && overspentBudgets.isEmpty) ...[
                            _buildRiskAlerts(atRiskBudgets),
                            const SizedBox(height: 24),
                          ],

                          // Upcoming Bills Section
                          _buildUpcomingBillsSection(),
                          const SizedBox(height: 24),

                          // Budget Categories Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Monthly Budget by Category',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: _addNewBudget,
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text(
                                  'Add',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Budget Categories List
                          ...budgets.map((budget) {
                            return _buildBudgetCategoryCard(budget);
                          }).toList(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double totalAllocated, double totalSpent, double totalRemaining, double spentPercentage) {
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
            'Monthly Budget Summary',
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
                    'Total Allocated',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.format(totalAllocated, ref.read(currencyProvider)),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Remaining',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.format(totalRemaining, ref.read(currencyProvider)),
                    style: TextStyle(
                      color: totalRemaining >= 0
                          ? Colors.white
                          : const Color(0xFFFFB3B3),
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${CurrencyFormatter.format(totalSpent, ref.read(currencyProvider))}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${spentPercentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: spentPercentage > 100 ? 1.0 : spentPercentage / 100,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                spentPercentage > 100
                    ? const Color(0xFFE74C3C)
                    : spentPercentage > 80
                        ? const Color(0xFFF39C12)
                        : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverspendingAlerts(List<BudgetModel> budgets) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE74C3C).withOpacity(0.3),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Color(0xFFE74C3C),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Overspending Alert!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...budgets.map((budget) {
            final overspent = budget.spent - budget.limit;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    budget.category,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Overspent by ${CurrencyFormatter.format(overspent, ref.read(currencyProvider))}',
                    style: const TextStyle(
                      color: Color(0xFFE74C3C),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRiskAlerts(List<BudgetModel> budgets) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF39C12).withOpacity(0.3),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF39C12).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFF39C12),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Categories at Risk',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...budgets.map((budget) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    budget.category,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${budget.percentage.toStringAsFixed(1)}% spent',
                    style: const TextStyle(
                      color: Color(0xFFF39C12),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBudgetCategoryCard(BudgetModel budget) {
    final style = _getCategoryStyle(budget.category);
    final icon = style['icon'] as IconData;
    final color = style['color'] as Color;
    final percentage = budget.percentage;
    final remaining = budget.remaining;
    final isOverspent = budget.isExceeded;
    final isAtRisk = budget.isAtRisk;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOverspent
              ? const Color(0xFFE74C3C).withOpacity(0.3)
              : isAtRisk
                  ? const Color(0xFFF39C12).withOpacity(0.3)
                  : Theme.of(context).colorScheme.outline.withOpacity(0.2),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.category,
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
                        Text(
                          'Allocated: ${CurrencyFormatter.format(budget.limit, ref.read(currencyProvider))}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Spent: ${CurrencyFormatter.format(budget.spent, ref.read(currencyProvider))}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 20),
                onPressed: () => _editBudget(budget),
                tooltip: 'Edit Budget',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress Bar Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Remaining: ${CurrencyFormatter.format(remaining, ref.read(currencyProvider))}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: remaining >= 0
                          ? const Color(0xFF27AE60)
                          : const Color(0xFFE74C3C),
                    ),
                  ),
                  Row(
                    children: [
                      if (isOverspent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE74C3C),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'OVERSpent',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (isAtRisk)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF39C12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'AT RISK',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: percentage > 100 ? 1.0 : percentage / 100,
                  minHeight: 10,
                  backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverspent
                        ? const Color(0xFFE74C3C)
                        : isAtRisk
                            ? const Color(0xFFF39C12)
                            : color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingBillsSection() {
    // Get bills from user input
    final userBillsAsync = ref.watch(billsProvider);
    // Get auto-detected bills from transactions
    final autoDetectedBills = ref.watch(upcomingBillsProvider);

    // Combine both lists
    final allBills = <dynamic>[];
    
    // Add user-input bills
    if (userBillsAsync.value != null) {
      allBills.addAll(userBillsAsync.value!);
    }
    
    // Add auto-detected bills (convert to BillModel-like structure)
    for (final bill in autoDetectedBills) {
      allBills.add(bill);
    }

    // Sort by due date
    allBills.sort((a, b) {
      final dateA = a is BillModel ? a.dueDate : (a as UpcomingBillModel).dueDate;
      final dateB = b is BillModel ? b.dueDate : (b as UpcomingBillModel).dueDate;
      return dateA.compareTo(dateB);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Upcoming Bills',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (allBills.isNotEmpty)
                  Text(
                    '${allBills.length} ${allBills.length == 1 ? 'bill' : 'bills'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_rounded, size: 20),
                  onPressed: _addNewBill,
                  tooltip: 'Add Bill',
                  color: const Color(0xFF4A90E2),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (allBills.isEmpty)
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
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
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No upcoming bills',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add bills manually or they will be detected from transactions',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addNewBill,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Bill'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allBills.length,
            itemExtent: 100.0, // Fixed height for better performance
            cacheExtent: 300.0,
            itemBuilder: (context, index) {
              final bill = allBills[index];
              if (bill is BillModel) {
                return _buildUserBillCard(bill);
              } else {
                return _buildUpcomingBillCard(bill as UpcomingBillModel);
              }
            },
          ),
      ],
    );
  }

  Widget _buildUpcomingBillCard(UpcomingBillModel bill) {
    final daysUntilDue = bill.daysUntilDue;
    final isOverdue = bill.isOverdue;
    final isDueSoon = bill.isDueSoon;

    // Color coding based on urgency
    Color borderColor;
    Color statusColor;
    Color backgroundColor;

    if (isOverdue) {
      borderColor = const Color(0xFFE74C3C);
      statusColor = const Color(0xFFE74C3C);
      backgroundColor = const Color(0xFFE74C3C).withOpacity(0.05);
    } else if (isDueSoon) {
      borderColor = const Color(0xFFF39C12);
      statusColor = const Color(0xFFF39C12);
      backgroundColor = const Color(0xFFF39C12).withOpacity(0.05);
    } else {
      borderColor = Theme.of(context).colorScheme.outline.withOpacity(0.3);
      statusColor = Theme.of(context).colorScheme.onSurfaceVariant;
      backgroundColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
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
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              bill.icon,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Bill Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bill.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        CurrencyFormatter.format(bill.amount, ref.read(currencyProvider), decimals: 2),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        bill.statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Due Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${bill.dueDate.day}/${bill.dueDate.month}',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${bill.dueDate.year}',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addNewBill() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    IconData selectedIcon = Icons.receipt_long;
    String selectedCategory = 'Bills';
    bool isRecurring = false;
    int? recurringDays;

    final billIcons = [
      {'name': 'Electricity', 'icon': Icons.bolt, 'category': 'Bills'},
      {'name': 'Water', 'icon': Icons.water_drop, 'category': 'Bills'},
      {'name': 'Internet', 'icon': Icons.wifi, 'category': 'Bills'},
      {'name': 'Phone', 'icon': Icons.phone, 'category': 'Bills'},
      {'name': 'Rent', 'icon': Icons.home, 'category': 'Rent'},
      {'name': 'Credit Card', 'icon': Icons.credit_card, 'category': 'Bills'},
      {'name': 'Insurance', 'icon': Icons.shield, 'category': 'Bills'},
      {'name': 'Subscription', 'icon': Icons.subscriptions, 'category': 'Bills'},
      {'name': 'Other', 'icon': Icons.receipt_long, 'category': 'Bills'},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            'Add New Bill',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Bill Name',
                    hintText: 'e.g., Meralco, Maynilad',
                    prefixIcon: const Icon(Icons.receipt_long),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '${CurrencyFormatter.extractSymbol(ref.read(currencyProvider))} ',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Due Date',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: billIcons.isNotEmpty ? billIcons.first : null,
                  decoration: InputDecoration(
                    labelText: 'Bill Type',
                    prefixIcon: Icon(selectedIcon),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: billIcons.map((iconData) {
                    return DropdownMenuItem(
                      value: iconData,
                      child: Row(
                        children: [
                          Icon(iconData['icon'] as IconData, size: 20),
                          const SizedBox(width: 8),
                          Text(iconData['name'] as String),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedIcon = value['icon'] as IconData;
                        selectedCategory = value['category'] as String;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Recurring Bill'),
                  subtitle: const Text('Automatically reschedule after payment'),
                  value: isRecurring,
                  onChanged: (value) {
                    setDialogState(() {
                      isRecurring = value ?? false;
                      if (isRecurring && recurringDays == null) {
                        recurringDays = 30;
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (isRecurring) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: recurringDays ?? 30,
                    decoration: InputDecoration(
                      labelText: 'Repeat Every',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(value: 7, child: Text('Weekly (7 days)')),
                      DropdownMenuItem(value: 15, child: Text('Bi-weekly (15 days)')),
                      DropdownMenuItem(value: 30, child: Text('Monthly (30 days)')),
                      DropdownMenuItem(value: 60, child: Text('Bi-monthly (60 days)')),
                      DropdownMenuItem(value: 90, child: Text('Quarterly (90 days)')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          recurringDays = value;
                        });
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final amount = double.tryParse(amountController.text);

                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a bill name'),
                      backgroundColor: Color(0xFFE74C3C),
                    ),
                  );
                  return;
                }

                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                      backgroundColor: Color(0xFFE74C3C),
                    ),
                  );
                  return;
                }

                try {
                  final billService = ref.read(billServiceProvider);
                  final now = DateTime.now();

                  final newBill = BillModel(
                    title: title,
                    amount: amount,
                    dueDate: selectedDate,
                    icon: selectedIcon,
                    category: selectedCategory,
                    isRecurring: isRecurring,
                    recurringDays: recurringDays,
                    createdAt: now,
                    updatedAt: now,
                  );

                  await billService.saveBill(newBill);

                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bill added successfully'),
                      backgroundColor: Color(0xFF27AE60),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: const Color(0xFFE74C3C),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add Bill',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserBillCard(BillModel bill) {
    final daysUntilDue = bill.daysUntilDue;
    final isOverdue = bill.isOverdue;
    final isDueSoon = bill.isDueSoon;

    Color borderColor;
    Color statusColor;
    Color backgroundColor;

    if (isOverdue) {
      borderColor = const Color(0xFFE74C3C);
      statusColor = const Color(0xFFE74C3C);
      backgroundColor = const Color(0xFFE74C3C).withOpacity(0.05);
    } else if (isDueSoon) {
      borderColor = const Color(0xFFF39C12);
      statusColor = const Color(0xFFF39C12);
      backgroundColor = const Color(0xFFF39C12).withOpacity(0.05);
    } else {
      borderColor = Theme.of(context).colorScheme.outline.withOpacity(0.3);
      statusColor = Theme.of(context).colorScheme.onSurfaceVariant;
      backgroundColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              bill.icon,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        bill.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (bill.isRecurring)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A90E2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'RECURRING',
                          style: TextStyle(
                            color: Color(0xFF4A90E2),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        CurrencyFormatter.format(bill.amount, ref.read(currencyProvider), decimals: 2),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        bill.statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurfaceVariant),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
                onTap: () {
                  Future.delayed(Duration.zero, () => _editBill(bill));
                },
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, size: 18),
                    SizedBox(width: 8),
                    Text('Mark as Paid'),
                  ],
                ),
                onTap: () {
                  Future.delayed(Duration.zero, () => _markBillAsPaid(bill));
                },
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Color(0xFFE74C3C)),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Color(0xFFE74C3C))),
                  ],
                ),
                onTap: () {
                  Future.delayed(Duration.zero, () => _deleteBill(bill));
                },
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${bill.dueDate.day}/${bill.dueDate.month}',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${bill.dueDate.year}',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editBill(BillModel bill) {
    final titleController = TextEditingController(text: bill.title);
    final amountController = TextEditingController(text: bill.amount.toStringAsFixed(2));
    DateTime selectedDate = bill.dueDate;
    IconData selectedIcon = bill.icon;
    String selectedCategory = bill.category;
    bool isRecurring = bill.isRecurring;
    int? recurringDays = bill.recurringDays;

    final billIcons = [
      {'name': 'Electricity', 'icon': Icons.bolt, 'category': 'Bills'},
      {'name': 'Water', 'icon': Icons.water_drop, 'category': 'Bills'},
      {'name': 'Internet', 'icon': Icons.wifi, 'category': 'Bills'},
      {'name': 'Phone', 'icon': Icons.phone, 'category': 'Bills'},
      {'name': 'Rent', 'icon': Icons.home, 'category': 'Rent'},
      {'name': 'Credit Card', 'icon': Icons.credit_card, 'category': 'Bills'},
      {'name': 'Insurance', 'icon': Icons.shield, 'category': 'Bills'},
      {'name': 'Subscription', 'icon': Icons.subscriptions, 'category': 'Bills'},
      {'name': 'Other', 'icon': Icons.receipt_long, 'category': 'Bills'},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            'Edit Bill',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Bill Name',
                    prefixIcon: const Icon(Icons.receipt_long),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '${CurrencyFormatter.extractSymbol(ref.read(currencyProvider))} ',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Due Date',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: billIcons.isNotEmpty 
                    ? billIcons.firstWhere(
                        (icon) => icon['icon'] == selectedIcon,
                        orElse: () => billIcons.isNotEmpty ? billIcons.first : billIcons[0],
                      )
                    : null,
                  decoration: InputDecoration(
                    labelText: 'Bill Type',
                    prefixIcon: Icon(selectedIcon),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: billIcons.map((iconData) {
                    return DropdownMenuItem(
                      value: iconData,
                      child: Row(
                        children: [
                          Icon(iconData['icon'] as IconData, size: 20),
                          const SizedBox(width: 8),
                          Text(iconData['name'] as String),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedIcon = value['icon'] as IconData;
                        selectedCategory = value['category'] as String;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Recurring Bill'),
                  value: isRecurring,
                  onChanged: (value) {
                    setDialogState(() {
                      isRecurring = value ?? false;
                      if (isRecurring && recurringDays == null) {
                        recurringDays = 30;
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (isRecurring) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: recurringDays ?? 30,
                    decoration: InputDecoration(
                      labelText: 'Repeat Every',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(value: 7, child: Text('Weekly (7 days)')),
                      DropdownMenuItem(value: 15, child: Text('Bi-weekly (15 days)')),
                      DropdownMenuItem(value: 30, child: Text('Monthly (30 days)')),
                      DropdownMenuItem(value: 60, child: Text('Bi-monthly (60 days)')),
                      DropdownMenuItem(value: 90, child: Text('Quarterly (90 days)')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          recurringDays = value;
                        });
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final amount = double.tryParse(amountController.text);

                if (title.isEmpty || amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields correctly'),
                      backgroundColor: Color(0xFFE74C3C),
                    ),
                  );
                  return;
                }

                try {
                  final billService = ref.read(billServiceProvider);
                  final updatedBill = bill.copyWith(
                    title: title,
                    amount: amount,
                    dueDate: selectedDate,
                    icon: selectedIcon,
                    category: selectedCategory,
                    isRecurring: isRecurring,
                    recurringDays: recurringDays,
                  );

                  await billService.saveBill(updatedBill);

                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bill updated successfully'),
                      backgroundColor: Color(0xFF27AE60),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: const Color(0xFFE74C3C),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _markBillAsPaid(BillModel bill) async {
    try {
      final billService = ref.read(billServiceProvider);
      final transactionService = ref.read(transactionServiceProvider);

      final transaction = TransactionModel(
        title: bill.title,
        category: bill.category,
        amount: -bill.amount.abs(),
        date: DateTime.now(),
        type: 'expense',
        notes: 'Bill payment',
      );

      await transactionService.addTransaction(transaction);
      await billService.markBillAsPaid(bill);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bill.isRecurring
                ? 'Bill marked as paid. Next due date updated.'
                : 'Bill marked as paid and removed.',
          ),
          backgroundColor: const Color(0xFF27AE60),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: const Color(0xFFE74C3C),
        ),
      );
    }
  }

  void _deleteBill(BillModel bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Text('Delete Bill?'),
        content: Text('Are you sure you want to delete "${bill.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && bill.id != null) {
      try {
        final billService = ref.read(billServiceProvider);
        await billService.deleteBill(bill.id!);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bill deleted successfully'),
            backgroundColor: Color(0xFF27AE60),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFE74C3C),
          ),
        );
      }
    }
  }
}
