import 'package:flutter/material.dart';
import 'dart:math' as math;

class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({super.key});

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen> {
  final List<Prediction> _predictions = [
    Prediction(month: 'Jan', amount: 35000),
    Prediction(month: 'Feb', amount: 38000),
    Prediction(month: 'Mar', amount: 32000),
    Prediction(month: 'Apr', amount: 40000),
    Prediction(month: 'May', amount: 37000),
    Prediction(month: 'Jun', amount: 39000),
  ];

  final double _currentMonthSpending = 35000.0;

  double get _averagePrediction {
    if (_predictions.isEmpty) return 0.0;
    final sum = _predictions.fold(0.0, (total, p) => total + p.amount);
    return sum / _predictions.length;
  }

  double get _maxPrediction {
    if (_predictions.isEmpty) return 0.0;
    return _predictions.map((p) => p.amount).reduce(math.max);
  }

  double get _minPrediction {
    if (_predictions.isEmpty) return 0.0;
    return _predictions.map((p) => p.amount).reduce(math.min);
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
              const SizedBox(height: 8),
              
              // Title
              Row(
                children: [
                  Icon(
                    Icons.auto_graph_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Expense Predictions',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Summary Card
              _buildSummaryCard(),
              const SizedBox(height: 24),

              // Predictions Chart
              _buildPredictionsChart(),
              const SizedBox(height: 24),

              // Monthly Breakdown
              _buildMonthlyBreakdown(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final averageChange = _averagePrediction - _currentMonthSpending;
    final averageChangePercent = _currentMonthSpending > 0
        ? (averageChange / _currentMonthSpending) * 100
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20.0),
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
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Average Predicted Spending',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₱${_averagePrediction.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Next ${_predictions.length} months',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
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
                        averageChange >= 0 ? Icons.trending_up : Icons.trending_down,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${averageChangePercent >= 0 ? '+' : ''}${averageChangePercent.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'vs Current Month',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
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

  Widget _buildPredictionsChart() {
    final maxAmount = _maxPrediction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Predicted Expenses by Month',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 250,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _predictions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final prediction = entry.value;
                    final height = maxAmount > 0 ? (prediction.amount / maxAmount) * 200 : 0.0;
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
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: height,
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
                              child: Center(
                                child: Text(
                                  '₱${(prediction.amount / 1000).toStringAsFixed(0)}k',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              prediction.month,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₱${prediction.amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
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

  Widget _buildMonthlyBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Breakdown',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ..._predictions.map((prediction) {
          final change = prediction.amount - _currentMonthSpending;
          final changePercent = _currentMonthSpending > 0
              ? (change / _currentMonthSpending) * 100
              : 0.0;
          final isIncrease = change >= 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                // Month
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    prediction.month,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Amount and Change
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₱${prediction.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 14,
                            color: isIncrease
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}% vs current',
                            style: TextStyle(
                              fontSize: 12,
                              color: isIncrease
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Trend Indicator
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isIncrease
                        ? Theme.of(context).colorScheme.error.withOpacity(0.1)
                        : Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isIncrease ? Icons.trending_up : Icons.trending_down,
                    color: isIncrease
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.secondary,
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

// Prediction Model
class Prediction {
  final String month;
  final double amount;

  Prediction({
    required this.month,
    required this.amount,
  });
}

