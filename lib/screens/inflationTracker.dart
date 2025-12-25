import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/providers.dart';
import '../services/inflation_service.dart';
import '../config/api_config.dart';

class InflationTrackerScreen extends ConsumerStatefulWidget {
  const InflationTrackerScreen({super.key});

  @override
  ConsumerState<InflationTrackerScreen> createState() => _InflationTrackerScreenState();
}

class _InflationTrackerScreenState extends ConsumerState<InflationTrackerScreen> {
  Future<void> _refreshInflationData() async {
    if (!mounted) return;
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing inflation data...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    try {
      final inflationService = ref.read(inflationServiceProvider);
      await inflationService.refreshInflationData();
      
      // Refresh providers
      ref.invalidate(inflationRateProvider);
      ref.invalidate(historicalInflationProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inflation data updated'),
            backgroundColor: Color(0xFF27AE60),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error refreshing data';
        final errorString = e.toString();
        
        // Provide user-friendly error messages
        if (errorString.contains('No internet connection') || errorString.contains('network')) {
          errorMessage = 'No internet connection. Using default inflation rate. Please check your network settings.';
        } else if (errorString.contains('timeout') || errorString.contains('Timeout')) {
          errorMessage = 'Request timed out. Using default inflation rate. Please try again later.';
        } else if (errorString.contains('rate limit')) {
          errorMessage = 'API rate limit exceeded. Using default inflation rate. Please try again later.';
        } else if (errorString.contains('Unable to fetch')) {
          errorMessage = 'Unable to fetch latest data. Using default inflation rate.';
        } else {
          // Show generic error message (service will use default rates)
          errorMessage = 'Using default inflation rate. Data will update when connection is available.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFE74C3C),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  List<double> _calculatePredictions(double currentRate, int months) {
    if (currentRate == 0) {
      return List.filled(months, 0.0);
    }
    
    // Simple prediction: use current rate for next months
    // In reality, this could be more sophisticated
    return List.filled(months, currentRate);
  }

  @override
  Widget build(BuildContext context) {
    final inflationRateAsync = ref.watch(inflationRateProvider);
    final historicalRatesAsync = ref.watch(historicalInflationProvider);
    
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
                  const Expanded(
                    child: Text(
                      'Inflation Tracker',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_rounded, color: Colors.white),
                    onPressed: _showApiKeyDialog,
                    tooltip: 'Settings',
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    onPressed: _refreshInflationData,
                    tooltip: 'Refresh Data',
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshInflationData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Country Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.public_rounded,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              ApiConfig.defaultCountry,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Current Inflation Rate Card
                      inflationRateAsync.when(
                        data: (rate) {
                          if (rate == null) {
                            return _buildNoApiKeyCard();
                          }
                          return _buildCurrentRateCard(rate);
                        },
                        loading: () => _buildLoadingCard(),
                        error: (error, stack) => _buildErrorCard(error.toString()),
                      ),
                      const SizedBox(height: 20),
                      
                      // Historical Chart
                      historicalRatesAsync.when(
                        data: (rates) {
                          if (rates.isEmpty) {
                            return _buildEmptyChartCard();
                          }
                          return _buildHistoricalChart(rates);
                        },
                        loading: () => _buildLoadingCard(),
                        error: (error, stack) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 20),
                      
                      // Predictions
                      inflationRateAsync.when(
                        data: (rate) {
                          if (rate == null) {
                            return const SizedBox.shrink();
                          }
                          return _buildPredictionsCard(rate);
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (error, stack) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 20),
                      
                      // Info Section
                      _buildInfoCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentRateCard(double rate) {
    final isHigh = rate > 5.0;
    final isModerate = rate > 2.0 && rate <= 5.0;
    
    return Container(
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Inflation Rate',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rate.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: isHigh 
                      ? const Color(0xFFE74C3C)
                      : isModerate
                          ? const Color(0xFFF39C12)
                          : const Color(0xFF27AE60),
                  letterSpacing: -1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  '%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isHigh
                  ? const Color(0xFFE74C3C).withOpacity(0.1)
                  : isModerate
                      ? const Color(0xFFF39C12).withOpacity(0.1)
                      : const Color(0xFF27AE60).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isHigh
                  ? 'High Inflation'
                  : isModerate
                      ? 'Moderate Inflation'
                      : 'Low Inflation',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isHigh
                    ? const Color(0xFFE74C3C)
                    : isModerate
                        ? const Color(0xFFF39C12)
                        : const Color(0xFF27AE60),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricalChart(List<double> rates) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historical Inflation (Last 12 Months)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: InflationChartPainter(rates),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionsCard(double currentRate) {
    final predictions = _calculatePredictions(currentRate, 3);
    
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Predicted Inflation (Next 3 Months)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: predictions.asMap().entries.map((entry) {
              final index = entry.key;
              final rate = entry.value;
              return Column(
                children: [
                  Text(
                    'Month ${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${rate.toStringAsFixed(2)}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A90E2),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4A90E2).withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF4A90E2).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: const Color(0xFF4A90E2),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'About Inflation Rate',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A90E2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Inflation rate measures how much prices increase over time. A higher rate means prices are rising faster. This data is fetched from API Ninjas and represents the general inflation rate for ${ApiConfig.defaultCountry}.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoApiKeyCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.key_off_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'API Key Not Configured',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please configure your API Ninjas key to view inflation data.',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get your FREE API key:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '1. Go to api-ninjas.com\n'
                  '2. Sign up (FREE)\n'
                  '3. Get your API key\n'
                  '4. Paste it here',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showApiKeyDialog,
            icon: const Icon(Icons.settings_rounded, size: 18),
            label: const Text('Configure API Key'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showApiKeyDialog() async {
    final TextEditingController controller = TextEditingController();
    bool isObscured = true;
    
    // Load current API key if exists
    final currentKey = await ApiConfig.getApiNinjasKey();
    if (currentKey.isNotEmpty) {
      controller.text = currentKey;
    }

    if (!mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Configure API Key'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                          const SizedBox(width: 6),
                          Text(
                            'How to get your API Key:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Visit: api-ninjas.com\n'
                        '2. Sign up for a FREE account\n'
                        '3. Go to "API Keys" section\n'
                        '4. Click "Generate New Key"\n'
                        '5. Copy the key and paste it below',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  obscureText: isObscured,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    hintText: 'Enter your API Ninjas key',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isObscured ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          isObscured = !isObscured;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final key = controller.text.trim();
                if (key.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter an API key'),
                        backgroundColor: Color(0xFFE74C3C),
                      ),
                    );
                  }
                  return;
                }
                
                // Save API key
                final success = await ApiConfig.saveApiNinjasKey(key);
                
                if (success) {
                  // Close dialog first
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                  
                  // Wait a bit for dialog to close and SharedPreferences to persist
                  await Future.delayed(const Duration(milliseconds: 300));
                  
                  // Refresh providers
                  ref.invalidate(inflationRateProvider);
                  ref.invalidate(historicalInflationProvider);
                  
                  // Show saving message and try to refresh data
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('API key saved. Fetching data...'),
                        backgroundColor: Color(0xFF4A90E2),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    
                    // Try to refresh data
                    await _refreshInflationData();
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to save API key. Please try again.'),
                        backgroundColor: Color(0xFFE74C3C),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.length > 100 ? error.substring(0, 100) + '...' : error,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.show_chart_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Historical Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Historical data will appear here once available.',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Chart Painter for Historical Inflation Data
class InflationChartPainter extends CustomPainter {
  final List<double> rates;
  final Color lineColor = const Color(0xFF4A90E2);
  final Color gridColor = Colors.grey;

  InflationChartPainter(this.rates);

  @override
  void paint(Canvas canvas, Size size) {
    if (rates.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final gridPaint = Paint()
      ..color = gridColor.withOpacity(0.2)
      ..strokeWidth = 1;

    final minValue = rates.reduce(math.min);
    final maxValue = rates.reduce(math.max);
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

    for (int i = 0; i < rates.length; i++) {
      final x = padding + (size.width - 2 * padding) * (i / (rates.length - 1));
      final normalizedValue = range > 0 ? (rates[i] - minValue) / range : 0.5;
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
