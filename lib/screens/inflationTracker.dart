import 'package:flutter/material.dart';
import 'dart:math' as math;

class InflationTrackerScreen extends StatefulWidget {
  const InflationTrackerScreen({super.key});

  @override
  State<InflationTrackerScreen> createState() => _InflationTrackerScreenState();
}

class _InflationTrackerScreenState extends State<InflationTrackerScreen> {
  final List<TrackedItem> _trackedItems = [
    TrackedItem(
      id: '1',
      name: 'Rice',
      currentPrice: 55.00,
      previousPrice: 52.00,
      unit: 'per kg',
      icon: Icons.rice_bowl,
      color: const Color(0xFFE74C3C),
      priceHistory: [50.0, 51.0, 52.0, 53.0, 54.0, 55.0],
      predictedPrices: [56.0, 57.0, 58.0],
    ),
    TrackedItem(
      id: '2',
      name: 'Milk',
      currentPrice: 85.00,
      previousPrice: 82.00,
      unit: 'per liter',
      icon: Icons.local_drink,
      color: const Color(0xFF4A90E2),
      priceHistory: [80.0, 81.0, 82.0, 83.0, 84.0, 85.0],
      predictedPrices: [86.0, 87.0, 88.0],
    ),
    TrackedItem(
      id: '3',
      name: 'Eggs',
      currentPrice: 8.50,
      previousPrice: 8.00,
      unit: 'per piece',
      icon: Icons.egg,
      color: const Color(0xFFF39C12),
      priceHistory: [7.5, 7.8, 8.0, 8.2, 8.4, 8.5],
      predictedPrices: [8.7, 8.9, 9.0],
    ),
    TrackedItem(
      id: '4',
      name: 'Gasoline',
      currentPrice: 65.50,
      previousPrice: 63.00,
      unit: 'per liter',
      icon: Icons.local_gas_station,
      color: const Color(0xFF27AE60),
      priceHistory: [60.0, 61.5, 63.0, 64.0, 64.5, 65.5],
      predictedPrices: [66.0, 67.0, 68.0],
    ),
    TrackedItem(
      id: '5',
      name: 'Bread',
      currentPrice: 45.00,
      previousPrice: 43.00,
      unit: 'per loaf',
      icon: Icons.breakfast_dining,
      color: const Color(0xFF9B59B6),
      priceHistory: [42.0, 42.5, 43.0, 43.5, 44.0, 45.0],
      predictedPrices: [45.5, 46.0, 46.5],
    ),
  ];

  double _calculatePercentageChange(double current, double previous) {
    if (previous == 0) return 0;
    return ((current - previous) / previous) * 100;
  }

  Future<void> _refreshPrices() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    // TODO: Fetch latest prices from API
    setState(() {
      // Update prices (simulated)
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prices updated')),
      );
    }
  }

  void _addNewItem() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final unitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Item to Track'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                hintText: 'e.g., Chicken',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Current Price',
                prefixText: '₱ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: unitController,
              decoration: const InputDecoration(
                labelText: 'Unit',
                hintText: 'e.g., per kg, per liter',
                border: OutlineInputBorder(),
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
              final price = double.tryParse(priceController.text);
              if (nameController.text.isNotEmpty && price != null && price > 0) {
                setState(() {
                  _trackedItems.add(
                    TrackedItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      currentPrice: price,
                      previousPrice: price,
                      unit: unitController.text.isEmpty
                          ? 'per unit'
                          : unitController.text,
                      icon: Icons.shopping_cart,
                      color: Colors.blue,
                      priceHistory: [price],
                      predictedPrices: [price * 1.02, price * 1.04, price * 1.06],
                    ),
                  );
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item added successfully')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _viewItemDetails(TrackedItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24.0),
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: item.color, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          item.unit,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Current Price Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Price',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₱${item.currentPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_calculatePercentageChange(item.currentPrice, item.previousPrice).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: item.currentPrice >= item.previousPrice
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Price History Chart
            Text(
              'Price History (Last 6 Months)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomPaint(
                  painter: LineChartPainter(
                    item.priceHistory,
                    item.color,
                    Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  child: Container(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Predicted Prices
            Text(
              'Predicted Prices (Next 3 Months)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: item.predictedPrices.asMap().entries.map((entry) {
                  final index = entry.key;
                  final price = entry.value;
                  return Column(
                    children: [
                      Text(
                        'Month ${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₱${price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshPrices,
          child: Column(
            children: [
              // Header with Back Button and Add Item
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Back',
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.grey),
                      onPressed: _addNewItem,
                      tooltip: 'Add Item',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _trackedItems.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.track_changes_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No items tracked yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pull down to refresh or add items',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _trackedItems.length,
                itemBuilder: (context, index) {
                  final item = _trackedItems[index];
                  final percentageChange =
                      _calculatePercentageChange(item.currentPrice, item.previousPrice);
                  final isIncrease = item.currentPrice >= item.previousPrice;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.2),
                      ),
                    ),
                    child: InkWell(
                      onTap: () => _viewItemDetails(item),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Icon
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: item.color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    color: item.color,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Item Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.unit,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Price Change Indicator
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isIncrease
                                        ? Theme.of(context).colorScheme.error.withOpacity(0.1)
                                        : Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                                        size: 16,
                                        color: isIncrease
                                            ? Theme.of(context).colorScheme.error
                                            : Theme.of(context).colorScheme.secondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${percentageChange.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isIncrease
                                              ? Theme.of(context).colorScheme.error
                                              : Theme.of(context).colorScheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Current Price
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current Price',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₱${item.currentPrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Previous',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₱${item.previousPrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Mini Chart
                            Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: CustomPaint(
                                painter: MiniLineChartPainter(
                                  item.priceHistory,
                                  item.color,
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                child: Container(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tracked Item Model
class TrackedItem {
  final String id;
  final String name;
  final double currentPrice;
  final double previousPrice;
  final String unit;
  final IconData icon;
  final Color color;
  final List<double> priceHistory;
  final List<double> predictedPrices;

  TrackedItem({
    required this.id,
    required this.name,
    required this.currentPrice,
    required this.previousPrice,
    required this.unit,
    required this.icon,
    required this.color,
    required this.priceHistory,
    required this.predictedPrices,
  });
}

// Line Chart Painter for Price History
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

// Mini Line Chart Painter
class MiniLineChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color gridColor;

  MiniLineChartPainter(this.data, this.lineColor, this.gridColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final minValue = data.reduce(math.min);
    final maxValue = data.reduce(math.max);
    final range = maxValue - minValue;
    final padding = 5.0;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = padding + (size.width - 2 * padding) * (i / (data.length - 1));
      final normalizedValue = range > 0 ? (data[i] - minValue) / range : 0.5;
      final y = size.height - padding - (size.height - 2 * padding) * normalizedValue;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

