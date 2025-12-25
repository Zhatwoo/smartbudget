import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../models/suggestion_model.dart';
import '../utils/currency_formatter.dart';

/// Service for generating dynamic smart suggestions
/// Analyzes transaction data and inflation rate to provide actionable suggestions
class SuggestionService {
  /// Get suggestions for cutting expenses based on spending patterns
  List<Suggestion> getCutExpenseSuggestions(List<TransactionModel> transactions, {String currency = 'PHP (₱)'}) {
    final suggestions = <Suggestion>[];
    
    if (transactions.isEmpty) {
      return _getGenericExpenseSuggestions(currency);
    }

    // Filter expenses from last 30 days
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recentExpenses = transactions
        .where((t) => t.type == 'expense' && t.date.isAfter(thirtyDaysAgo))
        .toList();

    if (recentExpenses.isEmpty) {
      return _getGenericExpenseSuggestions(currency);
    }

    // Calculate total expenses
    final totalExpenses = recentExpenses
        .fold(0.0, (sum, t) => sum + t.amount.abs());

    // Group by category and calculate spending
    final categorySpending = <String, double>{};
    for (var expense in recentExpenses) {
      categorySpending[expense.category] =
          (categorySpending[expense.category] ?? 0) + expense.amount.abs();
    }

    // Sort categories by spending (highest first)
    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Generate suggestions for top 3-5 categories
    final topCategories = sortedCategories.take(5).toList();
    
    for (var entry in topCategories) {
      final category = entry.key;
      final monthlySpending = entry.value;
      final percentageOfTotal = (monthlySpending / totalExpenses) * 100;
      
      // Only suggest if category is significant (>= 10% of total expenses)
      if (percentageOfTotal >= 10) {
        final potentialSavings = monthlySpending * 0.15; // 15% reduction
        final priority = percentageOfTotal >= 30
            ? Priority.high
            : percentageOfTotal >= 20
                ? Priority.medium
                : Priority.low;

        final suggestion = _createExpenseSuggestion(
          category: category,
          monthlySpending: monthlySpending,
          potentialSavings: potentialSavings,
          priority: priority,
        );
        suggestions.add(suggestion);
      }
    }

    return suggestions;
  }

  /// Get suggestions for increasing income based on income patterns
  List<Suggestion> getIncreaseIncomeSuggestions(List<TransactionModel> transactions, {String currency = 'PHP (₱)'}) {
    final suggestions = <Suggestion>[];

    if (transactions.isEmpty) {
      return _getGenericIncomeSuggestions();
    }

    // Filter income transactions
    final incomeTransactions = transactions
        .where((t) => t.type == 'income')
        .toList();

    // Analyze income sources
    final incomeByCategory = <String, double>{};
    for (var income in incomeTransactions) {
      incomeByCategory[income.category] =
          (incomeByCategory[income.category] ?? 0) + income.amount.abs();
    }

    // Check for missing income sources
    final hasSalary = incomeByCategory.containsKey('Salary');
    final hasFreelance = incomeByCategory.containsKey('Freelance');
    final hasInvestment = incomeByCategory.containsKey('Investment');

    // Calculate total monthly income (estimate from last 30 days)
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recentIncome = incomeTransactions
        .where((t) => t.date.isAfter(thirtyDaysAgo))
        .toList();
    
    final monthlyIncome = recentIncome
        .fold(0.0, (sum, t) => sum + t.amount.abs());

    // Suggest freelance if missing
    if (!hasFreelance) {
      suggestions.add(Suggestion(
        id: 'income_freelance',
        title: 'Start Freelancing',
        description: 'You have no freelance income. Consider freelancing to diversify your income sources.',
        category: 'Freelance',
        type: SuggestionType.increaseIncome,
        potentialGain: 10000.0,
        priority: Priority.high,
        icon: Icons.work_outline_rounded,
        color: Color(0xFF4A90E2),
        actionSteps: [
          'Identify your skills (writing, design, programming, etc.)',
          'Create profiles on freelancing platforms (Upwork, Fiverr, etc.)',
          'Start with small projects to build your portfolio',
          'Aim for ${CurrencyFormatter.format(10000, currency)}-${CurrencyFormatter.format(20000, currency)}/month additional income',
        ],
      ));
    }

    // Suggest investment income if user has savings potential
    if (!hasInvestment && monthlyIncome > 20000) {
      suggestions.add(Suggestion(
        id: 'income_investment',
        title: 'Generate Investment Income',
        description: 'With your current income, you can start investing to generate passive income.',
        category: 'Investment',
        type: SuggestionType.increaseIncome,
        potentialGain: monthlyIncome * 0.05, // 5% return estimate
        priority: Priority.medium,
        icon: Icons.trending_up_rounded,
        color: Color(0xFF27AE60),
        actionSteps: [
          'Set aside 10-20% of income for investments',
          'Start with low-risk options (time deposits, bonds)',
          'Consider mutual funds for diversification',
          'Reinvest returns to compound growth',
        ],
      ));
    }

    // Suggest side hustle if income is low
    if (monthlyIncome < 30000 && !hasFreelance) {
      suggestions.add(Suggestion(
        id: 'income_sidehustle',
        title: 'Explore Side Hustle Opportunities',
        description: 'Your income could benefit from additional sources. Consider part-time work or side businesses.',
        category: 'Other',
        type: SuggestionType.increaseIncome,
        potentialGain: 5000.0,
        priority: Priority.high,
        icon: Icons.business_center_rounded,
        color: Color(0xFFF39C12),
        actionSteps: [
          'Identify marketable skills or hobbies',
          'Look for part-time opportunities in your field',
          'Consider online tutoring or consulting',
          'Start small and scale gradually',
        ],
      ));
    }

    // If no specific suggestions, provide generic ones
    if (suggestions.isEmpty) {
      return _getGenericIncomeSuggestions();
    }

    return suggestions;
  }

  /// Get investment suggestions based on inflation rate
  List<Suggestion> getInvestmentSuggestions(double? inflationRate) {
    final suggestions = <Suggestion>[];

    // Default to moderate inflation if rate is null
    final rate = inflationRate ?? 3.0;

    if (rate < 2.0) {
      // Low inflation - focus on growth
      suggestions.add(Suggestion(
        id: 'invest_low_inflation',
        title: 'Focus on Growth Investments',
        description: 'With low inflation, focus on growth-oriented investments like stocks and mutual funds.',
        category: 'Investment',
        type: SuggestionType.invest,
        priority: Priority.high,
        icon: Icons.show_chart_rounded,
        color: Color(0xFF27AE60),
        actionSteps: [
          'Build emergency fund (3-6 months expenses)',
          'Invest 60-70% in stocks or equity mutual funds',
          'Consider index funds for diversification',
          'Reinvest dividends for compound growth',
        ],
      ));

      suggestions.add(Suggestion(
        id: 'invest_emergency_fund',
        title: 'Build Emergency Fund',
        description: 'Low inflation is a good time to build cash reserves without losing much value.',
        category: 'Savings',
        type: SuggestionType.invest,
        priority: Priority.medium,
        icon: Icons.account_balance_wallet_rounded,
        color: Color(0xFF4A90E2),
        actionSteps: [
          'Aim for 3-6 months of expenses in savings',
          'Use high-yield savings account or time deposit',
          'Keep it liquid for emergencies',
          'Automate monthly contributions',
        ],
      ));
    } else if (rate >= 2.0 && rate <= 5.0) {
      // Moderate inflation - balanced approach
      suggestions.add(Suggestion(
        id: 'invest_balanced',
        title: 'Balanced Investment Portfolio',
        description: 'With moderate inflation, maintain a balanced portfolio to protect and grow your wealth.',
        category: 'Investment',
        type: SuggestionType.invest,
        priority: Priority.high,
        icon: Icons.pie_chart_rounded,
        color: Color(0xFF4A90E2),
        actionSteps: [
          'Allocate 60% to stocks, 40% to bonds',
          'Consider real estate investment trusts (REITs)',
          'Diversify across different sectors',
          'Review and rebalance quarterly',
        ],
      ));

      suggestions.add(Suggestion(
        id: 'invest_real_estate',
        title: 'Consider Real Estate',
        description: 'Real estate can provide inflation protection and rental income during moderate inflation.',
        category: 'Real Estate',
        type: SuggestionType.invest,
        priority: Priority.medium,
        icon: Icons.home_work_rounded,
        color: Color(0xFFF39C12),
        actionSteps: [
          'Research real estate investment trusts (REITs)',
          'Consider rental properties if capital allows',
          'Look for properties in growing areas',
          'Calculate rental yield vs. mortgage costs',
        ],
      ));
    } else {
      // High inflation - inflation-hedged assets
      suggestions.add(Suggestion(
        id: 'invest_inflation_hedge',
        title: 'Protect Against High Inflation',
        description: 'With high inflation, prioritize assets that maintain value: stocks, real estate, and commodities.',
        category: 'Investment',
        type: SuggestionType.invest,
        priority: Priority.high,
        icon: Icons.shield_rounded,
        color: Color(0xFFE74C3C),
        actionSteps: [
          'Increase stock allocation to 70-80%',
          'Consider inflation-protected securities',
          'Invest in real estate or REITs',
          'Avoid keeping large cash reserves',
        ],
      ));

      suggestions.add(Suggestion(
        id: 'invest_stocks',
        title: 'Equity Investments',
        description: 'Stocks historically outperform inflation. Focus on quality companies with pricing power.',
        category: 'Stocks',
        type: SuggestionType.invest,
        priority: Priority.high,
        icon: Icons.trending_up_rounded,
        color: Color(0xFF27AE60),
        actionSteps: [
          'Invest in dividend-paying stocks',
          'Focus on sectors that benefit from inflation',
          'Consider index funds for diversification',
          'Reinvest dividends automatically',
        ],
      ));

      suggestions.add(Suggestion(
        id: 'invest_avoid_cash',
        title: 'Minimize Cash Holdings',
        description: 'Cash loses value quickly during high inflation. Invest excess cash in assets.',
        category: 'Cash Management',
        type: SuggestionType.invest,
        priority: Priority.medium,
        icon: Icons.money_off_rounded,
        color: Color(0xFFE74C3C),
        actionSteps: [
          'Keep only 1-2 months expenses in cash',
          'Move excess to investments immediately',
          'Use high-yield accounts for emergency fund',
          'Consider short-term bonds for liquidity',
        ],
      ));
    }

    return suggestions;
  }

  /// Create expense suggestion for a specific category
  Suggestion _createExpenseSuggestion({
    required String category,
    required double monthlySpending,
    required double potentialSavings,
    required Priority priority,
    String currency = 'PHP (₱)',
  }) {
    final categoryData = _getCategoryData(category);
    
    return Suggestion(
      id: 'expense_${category.toLowerCase()}',
      title: 'Reduce $category Spending',
      description: 'Your $category spending is ${CurrencyFormatter.format(monthlySpending, currency)}/month. You could save ${CurrencyFormatter.format(potentialSavings, currency)} by making small changes.',
      category: category,
      type: SuggestionType.cutExpense,
      potentialSavings: potentialSavings,
      priority: priority,
      icon: categoryData['icon'] as IconData,
      color: categoryData['color'] as Color,
      actionSteps: _getActionStepsForCategory(category, monthlySpending),
    );
  }

  /// Get category-specific icon and color
  Map<String, dynamic> _getCategoryData(String category) {
    final categoryMap = {
      'Food': {
        'icon': Icons.restaurant_rounded,
        'color': Color(0xFFE74C3C),
      },
      'Transport': {
        'icon': Icons.directions_car_rounded,
        'color': Color(0xFF4A90E2),
      },
      'Bills': {
        'icon': Icons.receipt_long_rounded,
        'color': Color(0xFFF39C12),
      },
      'Shopping': {
        'icon': Icons.shopping_bag_rounded,
        'color': Color(0xFF27AE60),
      },
      'Entertainment': {
        'icon': Icons.movie_rounded,
        'color': Color(0xFF9B59B6),
      },
      'Healthcare': {
        'icon': Icons.local_hospital_rounded,
        'color': Color(0xFFE67E22),
      },
      'Education': {
        'icon': Icons.school_rounded,
        'color': Color(0xFF3498DB),
      },
      'Other': {
        'icon': Icons.category_rounded,
        'color': Color(0xFF95A5A6),
      },
    };

    return categoryMap[category] ?? {
      'icon': Icons.category_rounded,
      'color': Color(0xFF95A5A6),
    };
  }

  /// Get action steps for a specific category
  List<String> _getActionStepsForCategory(String category, double monthlySpending) {
    switch (category) {
      case 'Food':
        return [
          'Plan meals weekly to reduce impulse purchases',
          'Buy in bulk for non-perishable items',
          'Cook at home more often (save 30-50% vs. eating out)',
          'Use grocery store apps for discounts and coupons',
        ];
      case 'Transport':
        return [
          'Use public transportation when possible',
          'Carpool with colleagues to split costs',
          'Walk or bike for short distances',
          'Consider fuel-efficient vehicles or electric options',
        ];
      case 'Bills':
        return [
          'Review and cancel unused subscriptions',
          'Switch to energy-efficient appliances',
          'Negotiate better rates with service providers',
          'Use budget billing for utilities',
        ];
      case 'Shopping':
        return [
          'Wait 24-48 hours before making non-essential purchases',
          'Compare prices online before buying',
          'Use cashback apps and credit card rewards',
          'Buy during sales and use discount codes',
        ];
      case 'Entertainment':
        return [
          'Look for free or low-cost alternatives (parks, libraries)',
          'Share streaming subscriptions with family',
          'Take advantage of happy hours and early bird specials',
          'Set a monthly entertainment budget',
        ];
      case 'Healthcare':
        return [
          'Use generic medications when available',
          'Take advantage of preventive care (cheaper than treatment)',
          'Compare prices at different pharmacies',
          'Consider health insurance if not covered',
        ];
      case 'Education':
        return [
          'Look for free online courses and resources',
          'Use library resources instead of buying books',
          'Apply for scholarships and financial aid',
          'Consider community college for prerequisites',
        ];
      default:
        return [
          'Review all expenses in this category',
          'Identify non-essential items to cut',
          'Set a monthly budget limit',
          'Track spending to stay within budget',
        ];
    }
  }

  /// Get generic expense suggestions when no transaction data
  List<Suggestion> _getGenericExpenseSuggestions(String currency) {
    return [
      Suggestion(
        id: 'generic_expense_1',
        title: 'Track Your Expenses',
        description: 'Start tracking your expenses to identify areas where you can save money.',
        category: 'General',
        type: SuggestionType.cutExpense,
        priority: Priority.medium,
        icon: Icons.receipt_long_rounded,
        color: Color(0xFF4A90E2),
        actionSteps: [
          'Record all expenses for 30 days',
          'Categorize spending to see patterns',
          'Identify top spending categories',
          'Set reduction goals for each category',
        ],
      ),
    ];
  }

  /// Get generic income suggestions when no transaction data
  List<Suggestion> _getGenericIncomeSuggestions() {
    return [
      Suggestion(
        id: 'generic_income_1',
        title: 'Diversify Your Income',
        description: 'Having multiple income sources provides financial security and growth opportunities.',
        category: 'General',
        type: SuggestionType.increaseIncome,
        priority: Priority.medium,
        icon: Icons.trending_up_rounded,
        color: Color(0xFF27AE60),
        actionSteps: [
          'Identify your marketable skills',
          'Explore freelancing or part-time opportunities',
          'Consider passive income streams',
          'Invest in skills that increase earning potential',
        ],
      ),
    ];
  }
}


