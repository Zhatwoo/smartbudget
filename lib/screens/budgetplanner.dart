import 'package:flutter/material.dart';

class BudgetPlannerScreen extends StatefulWidget {
  const BudgetPlannerScreen({super.key});

  @override
  State<BudgetPlannerScreen> createState() => _BudgetPlannerScreenState();
}

class _BudgetPlannerScreenState extends State<BudgetPlannerScreen> {
  final List<BudgetCategory> _budgetCategories = [
    BudgetCategory(
      id: '1',
      name: 'Food',
      allocated: 15000,
      spent: 12000,
      icon: Icons.restaurant,
      color: const Color(0xFFE74C3C),
    ),
    BudgetCategory(
      id: '2',
      name: 'Transport',
      allocated: 10000,
      spent: 8000,
      icon: Icons.directions_car,
      color: const Color(0xFF4A90E2),
    ),
    BudgetCategory(
      id: '3',
      name: 'Bills',
      allocated: 12000,
      spent: 10000,
      icon: Icons.receipt_long,
      color: const Color(0xFFF39C12),
    ),
    BudgetCategory(
      id: '4',
      name: 'Shopping',
      allocated: 8000,
      spent: 5000,
      icon: Icons.shopping_bag,
      color: const Color(0xFF27AE60),
    ),
    BudgetCategory(
      id: '5',
      name: 'Entertainment',
      allocated: 5000,
      spent: 4500,
      icon: Icons.movie,
      color: const Color(0xFF9B59B6),
    ),
    BudgetCategory(
      id: '6',
      name: 'Healthcare',
      allocated: 3000,
      spent: 1500,
      icon: Icons.local_hospital,
      color: const Color(0xFFE67E22),
    ),
  ];

  double get _totalAllocated {
    return _budgetCategories.fold(0, (sum, category) => sum + category.allocated);
  }

  double get _totalSpent {
    return _budgetCategories.fold(0, (sum, category) => sum + category.spent);
  }

  double get _totalRemaining {
    return _totalAllocated - _totalSpent;
  }

  List<BudgetCategory> get _categoriesAtRisk {
    return _budgetCategories.where((category) {
      final percentage = (category.spent / category.allocated) * 100;
      return percentage >= 80; // At risk if 80% or more spent
    }).toList();
  }

  List<BudgetCategory> get _overspentCategories {
    return _budgetCategories.where((category) => category.spent > category.allocated).toList();
  }

  void _editBudget(BudgetCategory category) {
    final amountController = TextEditingController(
      text: category.allocated.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Budget - ${category.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monthly Budget',
                prefixText: '₱ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newAmount = double.tryParse(amountController.text);
              if (newAmount != null && newAmount > 0) {
                setState(() {
                  final index = _budgetCategories.indexWhere((c) => c.id == category.id);
                  if (index != -1) {
                    _budgetCategories[index] = BudgetCategory(
                      id: category.id,
                      name: category.name,
                      allocated: newAmount,
                      spent: category.spent,
                      icon: category.icon,
                      color: category.color,
                    );
                  }
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Budget updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.grey),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
                alignment: Alignment.centerLeft,
              ),
            ),
            // Summary Card
            _buildSummaryCard(),
            const SizedBox(height: 24),

            // Alerts Section
            if (_overspentCategories.isNotEmpty) ...[
              _buildOverspendingAlerts(),
              const SizedBox(height: 24),
            ],

            if (_categoriesAtRisk.isNotEmpty && _overspentCategories.isEmpty) ...[
              _buildRiskAlerts(),
              const SizedBox(height: 24),
            ],

            // Budget Categories Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Budget by Category',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Add new category
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add category feature coming soon...')),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Category'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Budget Categories List
            ..._budgetCategories.map((category) {
              return _buildBudgetCategoryCard(category);
            }).toList(),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final spentPercentage = _totalAllocated > 0
        ? (_totalSpent / _totalAllocated) * 100
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Budget Summary',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Allocated',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₱${_totalAllocated.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
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
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₱${_totalRemaining.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: _totalRemaining >= 0
                          ? Colors.white
                          : Colors.red[200],
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ₱${_totalSpent.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              Text(
                '${spentPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: spentPercentage / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                spentPercentage > 100
                    ? Colors.red[300]!
                    : spentPercentage > 80
                        ? Colors.orange[300]!
                        : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverspendingAlerts() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Overspending Alert!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._overspentCategories.map((category) {
            final overspent = category.spent - category.allocated;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Overspent by ₱${overspent.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
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

  Widget _buildRiskAlerts() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.tertiary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Categories at Risk',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._categoriesAtRisk.map((category) {
            final percentage = (category.spent / category.allocated) * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}% spent',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.tertiary,
                      fontWeight: FontWeight.bold,
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

  Widget _buildBudgetCategoryCard(BudgetCategory category) {
    final percentage = category.allocated > 0
        ? (category.spent / category.allocated) * 100
        : 0.0;
    final remaining = category.allocated - category.spent;
    final isOverspent = category.spent > category.allocated;
    final isAtRisk = percentage >= 80 && !isOverspent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: isOverspent
            ? Border.all(
                color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                width: 2,
              )
            : isAtRisk
                ? Border.all(
                    color: Theme.of(context).colorScheme.tertiary.withOpacity(0.5),
                    width: 2,
                  )
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Allocated: ₱${category.allocated.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Spent: ₱${category.spent.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _editBudget(category),
                tooltip: 'Edit Budget',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Remaining: ₱${remaining.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: remaining >= 0
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                  Row(
                    children: [
                      if (isOverspent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'OVERSpent',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (isAtRisk)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.tertiary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'AT RISK',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage > 100 ? 1.0 : percentage / 100,
                  minHeight: 10,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverspent
                        ? Theme.of(context).colorScheme.error
                        : isAtRisk
                            ? Theme.of(context).colorScheme.tertiary
                            : category.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Budget Category Model
class BudgetCategory {
  final String id;
  final String name;
  final double allocated;
  final double spent;
  final IconData icon;
  final Color color;

  BudgetCategory({
    required this.id,
    required this.name,
    required this.allocated,
    required this.spent,
    required this.icon,
    required this.color,
  });
}

