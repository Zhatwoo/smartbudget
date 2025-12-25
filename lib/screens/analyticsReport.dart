import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../providers/providers.dart';
import '../utils/currency_formatter.dart';

class AnalyticsReportScreen extends ConsumerStatefulWidget {
  const AnalyticsReportScreen({super.key});

  @override
  ConsumerState<AnalyticsReportScreen> createState() => _AnalyticsReportScreenState();
}

class _AnalyticsReportScreenState extends ConsumerState<AnalyticsReportScreen> {
  DateTimeRange? _selectedDateRange;

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 180)),
            end: DateTime.now(),
          ),
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _selectedDateRange = null;
    });
  }

  Future<void> _exportToPDF() async {
    // TODO: Implement PDF export functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Text(
          'Export Report',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'PDF export feature will be available soon.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get data from providers (UI → Provider → Service → Firebase)
    final monthlySpending = ref.watch(monthlySpendingWithNamesProvider);
    final categorySpending = ref.watch(categorySpendingWithColorsProvider);
    final predictions = ref.watch(analyticsExpensePredictionsProvider);
    final inflationImpact = ref.watch(inflationImpactProvider);
    final totalSpending = categorySpending.fold(0.0, (sum, cat) => sum + cat.amount);

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
                  const Expanded(
                    child: Text(
                      'Analytics Report',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                    onPressed: _exportToPDF,
                    tooltip: 'Export PDF',
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: monthlySpending.isEmpty && categorySpending.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No analytics data available',
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add transactions to see analytics',
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
                          // Date Range Filter
                          Container(
                            padding: const EdgeInsets.all(16.0),
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
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.date_range_rounded,
                                    color: Color(0xFF4A90E2),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: _selectDateRange,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Date Range',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _selectedDateRange == null
                                              ? 'Last 6 months'
                                              : '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_selectedDateRange != null)
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 20),
                                    onPressed: _clearDateRange,
                                    tooltip: 'Clear filter',
                                    color: Colors.grey.shade600,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Monthly Spending Trends
                          if (monthlySpending.isNotEmpty) ...[
                            _buildMonthlyTrendsSection(monthlySpending),
                            const SizedBox(height: 24),
                          ],

                          // Category Breakdown
                          if (categorySpending.isNotEmpty) ...[
                            _buildCategoryBreakdownSection(categorySpending, totalSpending),
                            const SizedBox(height: 24),
                          ],

                          // Predicted Expenses
                          _buildPredictedExpensesSection(predictions),
                          const SizedBox(height: 24),

                          // Inflation Impact
                          _buildInflationImpactSection(inflationImpact),
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

  Widget _buildMonthlyTrendsSection(List<MonthlySpendingData> monthlySpending) {
    final amounts = monthlySpending.map((m) => m.amount).toList();
    final maxAmount = amounts.isNotEmpty ? amounts.reduce(math.max) : 0.0;
    final minAmount = amounts.isNotEmpty ? amounts.reduce(math.min) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Spending Trends',
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
                height: 200,
                child: CustomPaint(
                  painter: LineChartPainter(
                    amounts,
                    const Color(0xFF4A90E2),
                    Colors.grey.shade400,
                  ),
                  child: Container(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: monthlySpending.map((month) {
                  return Column(
                    children: [
                      Text(
                        month.month,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${CurrencyFormatter.extractSymbol(ref.read(currencyProvider))}${(month.amount / 1000).toStringAsFixed(0)}k',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdownSection(
    List<CategorySpendingData> categorySpending,
    double totalSpending,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category-wise Breakdown',
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
          child: Row(
            children: [
              // Pie Chart
              SizedBox(
                width: 150,
                height: 150,
                child: CustomPaint(
                  painter: PieChartPainter(categorySpending, totalSpending),
                  child: Container(),
                ),
              ),
              const SizedBox(width: 20),
              // Legend
              Expanded(
                child: Column(
                  children: categorySpending.map((category) {
                    final percentage = (totalSpending > 0)
                        ? (category.amount / totalSpending) * 100
                        : 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: category.color,
                              shape: BoxShape.circle,
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
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '${CurrencyFormatter.format(category.amount, ref.read(currencyProvider))} (${percentage.toStringAsFixed(1)}%)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildPredictedExpensesSection(Map<String, dynamic> predictions) {
    final predictedNextMonth = predictions['predictedNextMonth'] as double;
    final currentMonthSpending = predictions['currentMonth'] as double;
    final increase = predictions['change'] as double;
    final increasePercentage = predictions['changePercent'] as double;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Predicted Expenses (Next Month)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
            borderRadius: BorderRadius.circular(14),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Month',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.format(currentMonthSpending, ref.read(currencyProvider)),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
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
                        'Next Month',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.format(predictedNextMonth, ref.read(currencyProvider)),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      increase >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Expected ${increase >= 0 ? 'increase' : 'decrease'}: ${CurrencyFormatter.format(increase.abs(), ref.read(currencyProvider))} (${increasePercentage.abs().toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInflationImpactSection(Map<String, dynamic> inflationImpact) {
    final inflationRate = inflationImpact['inflationRate'] as double;
    final inflationAmount = inflationImpact['inflationAmount'] as double;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inflation Impact on Budget',
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
                    'Current Inflation Rate',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inflation Rate',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${inflationRate.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE74C3C),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Additional Cost',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.format(inflationAmount, ref.read(currencyProvider)),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE74C3C),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (inflationRate > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Due to ${inflationRate.toStringAsFixed(1)}% inflation, you need an additional ${CurrencyFormatter.format(inflationAmount, ref.read(currencyProvider))} to maintain your current lifestyle.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Line Chart Painter
class LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color gridColor;

  LineChartPainter(this.data, this.lineColor, this.gridColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final gridPaint = Paint()
      ..color = gridColor.withOpacity(0.2)
      ..strokeWidth = 1;

    final minValue = data.reduce(math.min);
    final maxValue = data.reduce(math.max);
    final range = maxValue - minValue;
    final padding = 20.0;

    // Draw grid lines
    for (int i = 0; i <= 4; i++) {
      final y = padding + (size.height - 2 * padding) * (i / 4);
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    // Draw line chart
    final path = Path();
    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = padding + (size.width - 2 * padding) * (i / (data.length - 1));
      final normalizedValue = range > 0 ? (data[i] - minValue) / range : 0.5;
      final y = size.height - padding - (size.height - 2 * padding) * normalizedValue;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw point
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Pie Chart Painter
class PieChartPainter extends CustomPainter {
  final List<CategorySpendingData> categories;
  final double total;

  PieChartPainter(this.categories, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0 || categories.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    double startAngle = -math.pi / 2; // Start from top

    for (var category in categories) {
      final sweepAngle = (category.amount / total) * 2 * math.pi;

      final paint = Paint()
        ..color = category.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
