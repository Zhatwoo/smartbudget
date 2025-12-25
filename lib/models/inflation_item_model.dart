class InflationItemModel {
  final String? id;
  final String name;
  final String unit;
  final double currentPrice;
  final double previousPrice;
  final List<double> priceHistory;
  final List<double> predictedPrices;
  final String color;
  final String icon;

  InflationItemModel({
    this.id,
    required this.name,
    required this.unit,
    required this.currentPrice,
    required this.previousPrice,
    required this.priceHistory,
    required this.predictedPrices,
    required this.color,
    required this.icon,
  });

  double get percentageChange {
    if (previousPrice == 0) return 0;
    return ((currentPrice - previousPrice) / previousPrice) * 100;
  }

  bool get isIncrease => currentPrice >= previousPrice;

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    final now = DateTime.now();
    return {
      'name': name,
      'unit': unit,
      'currentPrice': currentPrice,
      'previousPrice': previousPrice,
      'priceHistory': priceHistory,
      'predictedPrices': predictedPrices,
      'color': color,
      'icon': icon,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };
  }
  
  // Update map (for updates, preserves createdAt)
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'unit': unit,
      'currentPrice': currentPrice,
      'previousPrice': previousPrice,
      'priceHistory': priceHistory,
      'predictedPrices': predictedPrices,
      'color': color,
      'icon': icon,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  // Create from Firestore document
  factory InflationItemModel.fromMap(String id, Map<String, dynamic> map) {
    return InflationItemModel(
      id: id,
      name: map['name'] ?? '',
      unit: map['unit'] ?? '',
      currentPrice: (map['currentPrice'] ?? 0).toDouble(),
      previousPrice: (map['previousPrice'] ?? 0).toDouble(),
      priceHistory: List<double>.from(map['priceHistory'] ?? []),
      predictedPrices: List<double>.from(map['predictedPrices'] ?? []),
      color: map['color'] ?? '#4A90E2',
      icon: map['icon'] ?? 'shopping_cart',
    );
  }

  InflationItemModel copyWith({
    String? id,
    String? name,
    String? unit,
    double? currentPrice,
    double? previousPrice,
    List<double>? priceHistory,
    List<double>? predictedPrices,
    String? color,
    String? icon,
  }) {
    return InflationItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      currentPrice: currentPrice ?? this.currentPrice,
      previousPrice: previousPrice ?? this.previousPrice,
      priceHistory: priceHistory ?? this.priceHistory,
      predictedPrices: predictedPrices ?? this.predictedPrices,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
}

